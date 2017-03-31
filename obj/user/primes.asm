
obj/user/primes:     file format elf32-i386


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
  80002c:	e8 c1 00 00 00       	call   8000f2 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <primeproc>:

#include <inc/lib.h>

unsigned
primeproc(void)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	57                   	push   %edi
  800037:	56                   	push   %esi
  800038:	53                   	push   %ebx
  800039:	83 ec 1c             	sub    $0x1c,%esp
	int i, id, p;
	envid_t envid;

	// fetch a prime from our left neighbor
top:
	p = ipc_recv(&envid, 0, 0);
  80003c:	8d 75 e4             	lea    -0x1c(%ebp),%esi
  80003f:	83 ec 04             	sub    $0x4,%esp
  800042:	6a 00                	push   $0x0
  800044:	6a 00                	push   $0x0
  800046:	56                   	push   %esi
  800047:	e8 8d 10 00 00       	call   8010d9 <ipc_recv>
  80004c:	89 c3                	mov    %eax,%ebx
	cprintf("CPU %d: %d \n", envid, p);
  80004e:	83 c4 0c             	add    $0xc,%esp
  800051:	50                   	push   %eax
  800052:	ff 75 e4             	pushl  -0x1c(%ebp)
  800055:	68 00 15 80 00       	push   $0x801500
  80005a:	e8 c4 01 00 00       	call   800223 <cprintf>

	// fork a right neighbor to continue the chain
	if ((id = fork()) < 0)
  80005f:	e8 77 0e 00 00       	call   800edb <fork>
  800064:	89 c7                	mov    %eax,%edi
  800066:	83 c4 10             	add    $0x10,%esp
  800069:	85 c0                	test   %eax,%eax
  80006b:	79 12                	jns    80007f <primeproc+0x4c>
		panic("fork: %e", id);
  80006d:	50                   	push   %eax
  80006e:	68 0d 15 80 00       	push   $0x80150d
  800073:	6a 1a                	push   $0x1a
  800075:	68 16 15 80 00       	push   $0x801516
  80007a:	e8 cb 00 00 00       	call   80014a <_panic>
	if (id == 0)
  80007f:	85 c0                	test   %eax,%eax
  800081:	74 bc                	je     80003f <primeproc+0xc>
		goto top;

	// filter out multiples of our prime
	while (1) {
		i = ipc_recv(&envid, 0, 0);
  800083:	8d 75 e4             	lea    -0x1c(%ebp),%esi
  800086:	83 ec 04             	sub    $0x4,%esp
  800089:	6a 00                	push   $0x0
  80008b:	6a 00                	push   $0x0
  80008d:	56                   	push   %esi
  80008e:	e8 46 10 00 00       	call   8010d9 <ipc_recv>
  800093:	89 c1                	mov    %eax,%ecx
		if (i % p)
  800095:	99                   	cltd   
  800096:	f7 fb                	idiv   %ebx
  800098:	83 c4 10             	add    $0x10,%esp
  80009b:	85 d2                	test   %edx,%edx
  80009d:	74 e7                	je     800086 <primeproc+0x53>
			ipc_send(id, i, 0, 0);
  80009f:	6a 00                	push   $0x0
  8000a1:	6a 00                	push   $0x0
  8000a3:	51                   	push   %ecx
  8000a4:	57                   	push   %edi
  8000a5:	e8 ac 10 00 00       	call   801156 <ipc_send>
  8000aa:	83 c4 10             	add    $0x10,%esp
  8000ad:	eb d7                	jmp    800086 <primeproc+0x53>

008000af <umain>:
	}
}

void  
umain(int argc, char **argv)
{
  8000af:	55                   	push   %ebp
  8000b0:	89 e5                	mov    %esp,%ebp
  8000b2:	56                   	push   %esi
  8000b3:	53                   	push   %ebx
	int i, id;

	// fork the first prime process in the chain
	if ((id = fork()) < 0)
  8000b4:	e8 22 0e 00 00       	call   800edb <fork>
  8000b9:	89 c6                	mov    %eax,%esi
  8000bb:	85 c0                	test   %eax,%eax
  8000bd:	79 12                	jns    8000d1 <umain+0x22>
		panic("fork: %e", id);
  8000bf:	50                   	push   %eax
  8000c0:	68 0d 15 80 00       	push   $0x80150d
  8000c5:	6a 2d                	push   $0x2d
  8000c7:	68 16 15 80 00       	push   $0x801516
  8000cc:	e8 79 00 00 00       	call   80014a <_panic>
  8000d1:	bb 02 00 00 00       	mov    $0x2,%ebx
	if (id == 0)
  8000d6:	85 c0                	test   %eax,%eax
  8000d8:	75 05                	jne    8000df <umain+0x30>
		primeproc();
  8000da:	e8 54 ff ff ff       	call   800033 <primeproc>

	// feed all the integers through
	for (i = 2; ; i++)
		ipc_send(id, i, 0, 0);
  8000df:	6a 00                	push   $0x0
  8000e1:	6a 00                	push   $0x0
  8000e3:	53                   	push   %ebx
  8000e4:	56                   	push   %esi
  8000e5:	e8 6c 10 00 00       	call   801156 <ipc_send>
		panic("fork: %e", id);
	if (id == 0)
		primeproc();

	// feed all the integers through
	for (i = 2; ; i++)
  8000ea:	83 c3 01             	add    $0x1,%ebx
  8000ed:	83 c4 10             	add    $0x10,%esp
  8000f0:	eb ed                	jmp    8000df <umain+0x30>

008000f2 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000f2:	55                   	push   %ebp
  8000f3:	89 e5                	mov    %esp,%ebp
  8000f5:	56                   	push   %esi
  8000f6:	53                   	push   %ebx
  8000f7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000fa:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = envs+ENVX(sys_getenvid());
  8000fd:	e8 ea 0a 00 00       	call   800bec <sys_getenvid>
  800102:	25 ff 03 00 00       	and    $0x3ff,%eax
  800107:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80010a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80010f:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800114:	85 db                	test   %ebx,%ebx
  800116:	7e 07                	jle    80011f <libmain+0x2d>
		binaryname = argv[0];
  800118:	8b 06                	mov    (%esi),%eax
  80011a:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80011f:	83 ec 08             	sub    $0x8,%esp
  800122:	56                   	push   %esi
  800123:	53                   	push   %ebx
  800124:	e8 86 ff ff ff       	call   8000af <umain>

	// exit gracefully
	exit();
  800129:	e8 0a 00 00 00       	call   800138 <exit>
}
  80012e:	83 c4 10             	add    $0x10,%esp
  800131:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800134:	5b                   	pop    %ebx
  800135:	5e                   	pop    %esi
  800136:	5d                   	pop    %ebp
  800137:	c3                   	ret    

00800138 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800138:	55                   	push   %ebp
  800139:	89 e5                	mov    %esp,%ebp
  80013b:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80013e:	6a 00                	push   $0x0
  800140:	e8 66 0a 00 00       	call   800bab <sys_env_destroy>
}
  800145:	83 c4 10             	add    $0x10,%esp
  800148:	c9                   	leave  
  800149:	c3                   	ret    

0080014a <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80014a:	55                   	push   %ebp
  80014b:	89 e5                	mov    %esp,%ebp
  80014d:	56                   	push   %esi
  80014e:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80014f:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800152:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800158:	e8 8f 0a 00 00       	call   800bec <sys_getenvid>
  80015d:	83 ec 0c             	sub    $0xc,%esp
  800160:	ff 75 0c             	pushl  0xc(%ebp)
  800163:	ff 75 08             	pushl  0x8(%ebp)
  800166:	56                   	push   %esi
  800167:	50                   	push   %eax
  800168:	68 30 15 80 00       	push   $0x801530
  80016d:	e8 b1 00 00 00       	call   800223 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800172:	83 c4 18             	add    $0x18,%esp
  800175:	53                   	push   %ebx
  800176:	ff 75 10             	pushl  0x10(%ebp)
  800179:	e8 54 00 00 00       	call   8001d2 <vcprintf>
	cprintf("\n");
  80017e:	c7 04 24 0b 15 80 00 	movl   $0x80150b,(%esp)
  800185:	e8 99 00 00 00       	call   800223 <cprintf>
  80018a:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80018d:	cc                   	int3   
  80018e:	eb fd                	jmp    80018d <_panic+0x43>

00800190 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800190:	55                   	push   %ebp
  800191:	89 e5                	mov    %esp,%ebp
  800193:	53                   	push   %ebx
  800194:	83 ec 04             	sub    $0x4,%esp
  800197:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80019a:	8b 13                	mov    (%ebx),%edx
  80019c:	8d 42 01             	lea    0x1(%edx),%eax
  80019f:	89 03                	mov    %eax,(%ebx)
  8001a1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001a4:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001a8:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001ad:	75 1a                	jne    8001c9 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001af:	83 ec 08             	sub    $0x8,%esp
  8001b2:	68 ff 00 00 00       	push   $0xff
  8001b7:	8d 43 08             	lea    0x8(%ebx),%eax
  8001ba:	50                   	push   %eax
  8001bb:	e8 ae 09 00 00       	call   800b6e <sys_cputs>
		b->idx = 0;
  8001c0:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001c6:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001c9:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001cd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001d0:	c9                   	leave  
  8001d1:	c3                   	ret    

008001d2 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001d2:	55                   	push   %ebp
  8001d3:	89 e5                	mov    %esp,%ebp
  8001d5:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001db:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001e2:	00 00 00 
	b.cnt = 0;
  8001e5:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001ec:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001ef:	ff 75 0c             	pushl  0xc(%ebp)
  8001f2:	ff 75 08             	pushl  0x8(%ebp)
  8001f5:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001fb:	50                   	push   %eax
  8001fc:	68 90 01 80 00       	push   $0x800190
  800201:	e8 1a 01 00 00       	call   800320 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800206:	83 c4 08             	add    $0x8,%esp
  800209:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80020f:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800215:	50                   	push   %eax
  800216:	e8 53 09 00 00       	call   800b6e <sys_cputs>

	return b.cnt;
}
  80021b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800221:	c9                   	leave  
  800222:	c3                   	ret    

00800223 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800223:	55                   	push   %ebp
  800224:	89 e5                	mov    %esp,%ebp
  800226:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800229:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80022c:	50                   	push   %eax
  80022d:	ff 75 08             	pushl  0x8(%ebp)
  800230:	e8 9d ff ff ff       	call   8001d2 <vcprintf>
	va_end(ap);

	return cnt;
}
  800235:	c9                   	leave  
  800236:	c3                   	ret    

00800237 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800237:	55                   	push   %ebp
  800238:	89 e5                	mov    %esp,%ebp
  80023a:	57                   	push   %edi
  80023b:	56                   	push   %esi
  80023c:	53                   	push   %ebx
  80023d:	83 ec 1c             	sub    $0x1c,%esp
  800240:	89 c7                	mov    %eax,%edi
  800242:	89 d6                	mov    %edx,%esi
  800244:	8b 45 08             	mov    0x8(%ebp),%eax
  800247:	8b 55 0c             	mov    0xc(%ebp),%edx
  80024a:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80024d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800250:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800253:	bb 00 00 00 00       	mov    $0x0,%ebx
  800258:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80025b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80025e:	39 d3                	cmp    %edx,%ebx
  800260:	72 05                	jb     800267 <printnum+0x30>
  800262:	39 45 10             	cmp    %eax,0x10(%ebp)
  800265:	77 45                	ja     8002ac <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800267:	83 ec 0c             	sub    $0xc,%esp
  80026a:	ff 75 18             	pushl  0x18(%ebp)
  80026d:	8b 45 14             	mov    0x14(%ebp),%eax
  800270:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800273:	53                   	push   %ebx
  800274:	ff 75 10             	pushl  0x10(%ebp)
  800277:	83 ec 08             	sub    $0x8,%esp
  80027a:	ff 75 e4             	pushl  -0x1c(%ebp)
  80027d:	ff 75 e0             	pushl  -0x20(%ebp)
  800280:	ff 75 dc             	pushl  -0x24(%ebp)
  800283:	ff 75 d8             	pushl  -0x28(%ebp)
  800286:	e8 d5 0f 00 00       	call   801260 <__udivdi3>
  80028b:	83 c4 18             	add    $0x18,%esp
  80028e:	52                   	push   %edx
  80028f:	50                   	push   %eax
  800290:	89 f2                	mov    %esi,%edx
  800292:	89 f8                	mov    %edi,%eax
  800294:	e8 9e ff ff ff       	call   800237 <printnum>
  800299:	83 c4 20             	add    $0x20,%esp
  80029c:	eb 18                	jmp    8002b6 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80029e:	83 ec 08             	sub    $0x8,%esp
  8002a1:	56                   	push   %esi
  8002a2:	ff 75 18             	pushl  0x18(%ebp)
  8002a5:	ff d7                	call   *%edi
  8002a7:	83 c4 10             	add    $0x10,%esp
  8002aa:	eb 03                	jmp    8002af <printnum+0x78>
  8002ac:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002af:	83 eb 01             	sub    $0x1,%ebx
  8002b2:	85 db                	test   %ebx,%ebx
  8002b4:	7f e8                	jg     80029e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002b6:	83 ec 08             	sub    $0x8,%esp
  8002b9:	56                   	push   %esi
  8002ba:	83 ec 04             	sub    $0x4,%esp
  8002bd:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002c0:	ff 75 e0             	pushl  -0x20(%ebp)
  8002c3:	ff 75 dc             	pushl  -0x24(%ebp)
  8002c6:	ff 75 d8             	pushl  -0x28(%ebp)
  8002c9:	e8 c2 10 00 00       	call   801390 <__umoddi3>
  8002ce:	83 c4 14             	add    $0x14,%esp
  8002d1:	0f be 80 53 15 80 00 	movsbl 0x801553(%eax),%eax
  8002d8:	50                   	push   %eax
  8002d9:	ff d7                	call   *%edi
}
  8002db:	83 c4 10             	add    $0x10,%esp
  8002de:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002e1:	5b                   	pop    %ebx
  8002e2:	5e                   	pop    %esi
  8002e3:	5f                   	pop    %edi
  8002e4:	5d                   	pop    %ebp
  8002e5:	c3                   	ret    

008002e6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002e6:	55                   	push   %ebp
  8002e7:	89 e5                	mov    %esp,%ebp
  8002e9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002ec:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002f0:	8b 10                	mov    (%eax),%edx
  8002f2:	3b 50 04             	cmp    0x4(%eax),%edx
  8002f5:	73 0a                	jae    800301 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002f7:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002fa:	89 08                	mov    %ecx,(%eax)
  8002fc:	8b 45 08             	mov    0x8(%ebp),%eax
  8002ff:	88 02                	mov    %al,(%edx)
}
  800301:	5d                   	pop    %ebp
  800302:	c3                   	ret    

00800303 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800303:	55                   	push   %ebp
  800304:	89 e5                	mov    %esp,%ebp
  800306:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800309:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80030c:	50                   	push   %eax
  80030d:	ff 75 10             	pushl  0x10(%ebp)
  800310:	ff 75 0c             	pushl  0xc(%ebp)
  800313:	ff 75 08             	pushl  0x8(%ebp)
  800316:	e8 05 00 00 00       	call   800320 <vprintfmt>
	va_end(ap);
}
  80031b:	83 c4 10             	add    $0x10,%esp
  80031e:	c9                   	leave  
  80031f:	c3                   	ret    

00800320 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800320:	55                   	push   %ebp
  800321:	89 e5                	mov    %esp,%ebp
  800323:	57                   	push   %edi
  800324:	56                   	push   %esi
  800325:	53                   	push   %ebx
  800326:	83 ec 2c             	sub    $0x2c,%esp
  800329:	8b 75 08             	mov    0x8(%ebp),%esi
  80032c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80032f:	8b 7d 10             	mov    0x10(%ebp),%edi
  800332:	eb 12                	jmp    800346 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800334:	85 c0                	test   %eax,%eax
  800336:	0f 84 42 04 00 00    	je     80077e <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  80033c:	83 ec 08             	sub    $0x8,%esp
  80033f:	53                   	push   %ebx
  800340:	50                   	push   %eax
  800341:	ff d6                	call   *%esi
  800343:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800346:	83 c7 01             	add    $0x1,%edi
  800349:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80034d:	83 f8 25             	cmp    $0x25,%eax
  800350:	75 e2                	jne    800334 <vprintfmt+0x14>
  800352:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800356:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80035d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800364:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80036b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800370:	eb 07                	jmp    800379 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800372:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800375:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800379:	8d 47 01             	lea    0x1(%edi),%eax
  80037c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80037f:	0f b6 07             	movzbl (%edi),%eax
  800382:	0f b6 d0             	movzbl %al,%edx
  800385:	83 e8 23             	sub    $0x23,%eax
  800388:	3c 55                	cmp    $0x55,%al
  80038a:	0f 87 d3 03 00 00    	ja     800763 <vprintfmt+0x443>
  800390:	0f b6 c0             	movzbl %al,%eax
  800393:	ff 24 85 20 16 80 00 	jmp    *0x801620(,%eax,4)
  80039a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80039d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003a1:	eb d6                	jmp    800379 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003a6:	b8 00 00 00 00       	mov    $0x0,%eax
  8003ab:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003ae:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003b1:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8003b5:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8003b8:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8003bb:	83 f9 09             	cmp    $0x9,%ecx
  8003be:	77 3f                	ja     8003ff <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003c0:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003c3:	eb e9                	jmp    8003ae <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c8:	8b 00                	mov    (%eax),%eax
  8003ca:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8003d0:	8d 40 04             	lea    0x4(%eax),%eax
  8003d3:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003d9:	eb 2a                	jmp    800405 <vprintfmt+0xe5>
  8003db:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003de:	85 c0                	test   %eax,%eax
  8003e0:	ba 00 00 00 00       	mov    $0x0,%edx
  8003e5:	0f 49 d0             	cmovns %eax,%edx
  8003e8:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003ee:	eb 89                	jmp    800379 <vprintfmt+0x59>
  8003f0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003f3:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003fa:	e9 7a ff ff ff       	jmp    800379 <vprintfmt+0x59>
  8003ff:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800402:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800405:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800409:	0f 89 6a ff ff ff    	jns    800379 <vprintfmt+0x59>
				width = precision, precision = -1;
  80040f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800412:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800415:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80041c:	e9 58 ff ff ff       	jmp    800379 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800421:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800424:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800427:	e9 4d ff ff ff       	jmp    800379 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80042c:	8b 45 14             	mov    0x14(%ebp),%eax
  80042f:	8d 78 04             	lea    0x4(%eax),%edi
  800432:	83 ec 08             	sub    $0x8,%esp
  800435:	53                   	push   %ebx
  800436:	ff 30                	pushl  (%eax)
  800438:	ff d6                	call   *%esi
			break;
  80043a:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80043d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800440:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800443:	e9 fe fe ff ff       	jmp    800346 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800448:	8b 45 14             	mov    0x14(%ebp),%eax
  80044b:	8d 78 04             	lea    0x4(%eax),%edi
  80044e:	8b 00                	mov    (%eax),%eax
  800450:	99                   	cltd   
  800451:	31 d0                	xor    %edx,%eax
  800453:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800455:	83 f8 08             	cmp    $0x8,%eax
  800458:	7f 0b                	jg     800465 <vprintfmt+0x145>
  80045a:	8b 14 85 80 17 80 00 	mov    0x801780(,%eax,4),%edx
  800461:	85 d2                	test   %edx,%edx
  800463:	75 1b                	jne    800480 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800465:	50                   	push   %eax
  800466:	68 6b 15 80 00       	push   $0x80156b
  80046b:	53                   	push   %ebx
  80046c:	56                   	push   %esi
  80046d:	e8 91 fe ff ff       	call   800303 <printfmt>
  800472:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800475:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800478:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80047b:	e9 c6 fe ff ff       	jmp    800346 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800480:	52                   	push   %edx
  800481:	68 74 15 80 00       	push   $0x801574
  800486:	53                   	push   %ebx
  800487:	56                   	push   %esi
  800488:	e8 76 fe ff ff       	call   800303 <printfmt>
  80048d:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800490:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800493:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800496:	e9 ab fe ff ff       	jmp    800346 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80049b:	8b 45 14             	mov    0x14(%ebp),%eax
  80049e:	83 c0 04             	add    $0x4,%eax
  8004a1:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8004a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004a7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004a9:	85 ff                	test   %edi,%edi
  8004ab:	b8 64 15 80 00       	mov    $0x801564,%eax
  8004b0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004b3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004b7:	0f 8e 94 00 00 00    	jle    800551 <vprintfmt+0x231>
  8004bd:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004c1:	0f 84 98 00 00 00    	je     80055f <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c7:	83 ec 08             	sub    $0x8,%esp
  8004ca:	ff 75 d0             	pushl  -0x30(%ebp)
  8004cd:	57                   	push   %edi
  8004ce:	e8 33 03 00 00       	call   800806 <strnlen>
  8004d3:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004d6:	29 c1                	sub    %eax,%ecx
  8004d8:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004db:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004de:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004e2:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004e5:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004e8:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ea:	eb 0f                	jmp    8004fb <vprintfmt+0x1db>
					putch(padc, putdat);
  8004ec:	83 ec 08             	sub    $0x8,%esp
  8004ef:	53                   	push   %ebx
  8004f0:	ff 75 e0             	pushl  -0x20(%ebp)
  8004f3:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004f5:	83 ef 01             	sub    $0x1,%edi
  8004f8:	83 c4 10             	add    $0x10,%esp
  8004fb:	85 ff                	test   %edi,%edi
  8004fd:	7f ed                	jg     8004ec <vprintfmt+0x1cc>
  8004ff:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800502:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800505:	85 c9                	test   %ecx,%ecx
  800507:	b8 00 00 00 00       	mov    $0x0,%eax
  80050c:	0f 49 c1             	cmovns %ecx,%eax
  80050f:	29 c1                	sub    %eax,%ecx
  800511:	89 75 08             	mov    %esi,0x8(%ebp)
  800514:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800517:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80051a:	89 cb                	mov    %ecx,%ebx
  80051c:	eb 4d                	jmp    80056b <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80051e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800522:	74 1b                	je     80053f <vprintfmt+0x21f>
  800524:	0f be c0             	movsbl %al,%eax
  800527:	83 e8 20             	sub    $0x20,%eax
  80052a:	83 f8 5e             	cmp    $0x5e,%eax
  80052d:	76 10                	jbe    80053f <vprintfmt+0x21f>
					putch('?', putdat);
  80052f:	83 ec 08             	sub    $0x8,%esp
  800532:	ff 75 0c             	pushl  0xc(%ebp)
  800535:	6a 3f                	push   $0x3f
  800537:	ff 55 08             	call   *0x8(%ebp)
  80053a:	83 c4 10             	add    $0x10,%esp
  80053d:	eb 0d                	jmp    80054c <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  80053f:	83 ec 08             	sub    $0x8,%esp
  800542:	ff 75 0c             	pushl  0xc(%ebp)
  800545:	52                   	push   %edx
  800546:	ff 55 08             	call   *0x8(%ebp)
  800549:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80054c:	83 eb 01             	sub    $0x1,%ebx
  80054f:	eb 1a                	jmp    80056b <vprintfmt+0x24b>
  800551:	89 75 08             	mov    %esi,0x8(%ebp)
  800554:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800557:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80055a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80055d:	eb 0c                	jmp    80056b <vprintfmt+0x24b>
  80055f:	89 75 08             	mov    %esi,0x8(%ebp)
  800562:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800565:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800568:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80056b:	83 c7 01             	add    $0x1,%edi
  80056e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800572:	0f be d0             	movsbl %al,%edx
  800575:	85 d2                	test   %edx,%edx
  800577:	74 23                	je     80059c <vprintfmt+0x27c>
  800579:	85 f6                	test   %esi,%esi
  80057b:	78 a1                	js     80051e <vprintfmt+0x1fe>
  80057d:	83 ee 01             	sub    $0x1,%esi
  800580:	79 9c                	jns    80051e <vprintfmt+0x1fe>
  800582:	89 df                	mov    %ebx,%edi
  800584:	8b 75 08             	mov    0x8(%ebp),%esi
  800587:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80058a:	eb 18                	jmp    8005a4 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80058c:	83 ec 08             	sub    $0x8,%esp
  80058f:	53                   	push   %ebx
  800590:	6a 20                	push   $0x20
  800592:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800594:	83 ef 01             	sub    $0x1,%edi
  800597:	83 c4 10             	add    $0x10,%esp
  80059a:	eb 08                	jmp    8005a4 <vprintfmt+0x284>
  80059c:	89 df                	mov    %ebx,%edi
  80059e:	8b 75 08             	mov    0x8(%ebp),%esi
  8005a1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005a4:	85 ff                	test   %edi,%edi
  8005a6:	7f e4                	jg     80058c <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005a8:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8005ab:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005b1:	e9 90 fd ff ff       	jmp    800346 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005b6:	83 f9 01             	cmp    $0x1,%ecx
  8005b9:	7e 19                	jle    8005d4 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8005bb:	8b 45 14             	mov    0x14(%ebp),%eax
  8005be:	8b 50 04             	mov    0x4(%eax),%edx
  8005c1:	8b 00                	mov    (%eax),%eax
  8005c3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005c6:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005c9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cc:	8d 40 08             	lea    0x8(%eax),%eax
  8005cf:	89 45 14             	mov    %eax,0x14(%ebp)
  8005d2:	eb 38                	jmp    80060c <vprintfmt+0x2ec>
	else if (lflag)
  8005d4:	85 c9                	test   %ecx,%ecx
  8005d6:	74 1b                	je     8005f3 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005db:	8b 00                	mov    (%eax),%eax
  8005dd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005e0:	89 c1                	mov    %eax,%ecx
  8005e2:	c1 f9 1f             	sar    $0x1f,%ecx
  8005e5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005e8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005eb:	8d 40 04             	lea    0x4(%eax),%eax
  8005ee:	89 45 14             	mov    %eax,0x14(%ebp)
  8005f1:	eb 19                	jmp    80060c <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005f3:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f6:	8b 00                	mov    (%eax),%eax
  8005f8:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005fb:	89 c1                	mov    %eax,%ecx
  8005fd:	c1 f9 1f             	sar    $0x1f,%ecx
  800600:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800603:	8b 45 14             	mov    0x14(%ebp),%eax
  800606:	8d 40 04             	lea    0x4(%eax),%eax
  800609:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80060c:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80060f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800612:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800617:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80061b:	0f 89 0e 01 00 00    	jns    80072f <vprintfmt+0x40f>
				putch('-', putdat);
  800621:	83 ec 08             	sub    $0x8,%esp
  800624:	53                   	push   %ebx
  800625:	6a 2d                	push   $0x2d
  800627:	ff d6                	call   *%esi
				num = -(long long) num;
  800629:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80062c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80062f:	f7 da                	neg    %edx
  800631:	83 d1 00             	adc    $0x0,%ecx
  800634:	f7 d9                	neg    %ecx
  800636:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800639:	b8 0a 00 00 00       	mov    $0xa,%eax
  80063e:	e9 ec 00 00 00       	jmp    80072f <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800643:	83 f9 01             	cmp    $0x1,%ecx
  800646:	7e 18                	jle    800660 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800648:	8b 45 14             	mov    0x14(%ebp),%eax
  80064b:	8b 10                	mov    (%eax),%edx
  80064d:	8b 48 04             	mov    0x4(%eax),%ecx
  800650:	8d 40 08             	lea    0x8(%eax),%eax
  800653:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800656:	b8 0a 00 00 00       	mov    $0xa,%eax
  80065b:	e9 cf 00 00 00       	jmp    80072f <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800660:	85 c9                	test   %ecx,%ecx
  800662:	74 1a                	je     80067e <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800664:	8b 45 14             	mov    0x14(%ebp),%eax
  800667:	8b 10                	mov    (%eax),%edx
  800669:	b9 00 00 00 00       	mov    $0x0,%ecx
  80066e:	8d 40 04             	lea    0x4(%eax),%eax
  800671:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800674:	b8 0a 00 00 00       	mov    $0xa,%eax
  800679:	e9 b1 00 00 00       	jmp    80072f <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80067e:	8b 45 14             	mov    0x14(%ebp),%eax
  800681:	8b 10                	mov    (%eax),%edx
  800683:	b9 00 00 00 00       	mov    $0x0,%ecx
  800688:	8d 40 04             	lea    0x4(%eax),%eax
  80068b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80068e:	b8 0a 00 00 00       	mov    $0xa,%eax
  800693:	e9 97 00 00 00       	jmp    80072f <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800698:	83 ec 08             	sub    $0x8,%esp
  80069b:	53                   	push   %ebx
  80069c:	6a 58                	push   $0x58
  80069e:	ff d6                	call   *%esi
			putch('X', putdat);
  8006a0:	83 c4 08             	add    $0x8,%esp
  8006a3:	53                   	push   %ebx
  8006a4:	6a 58                	push   $0x58
  8006a6:	ff d6                	call   *%esi
			putch('X', putdat);
  8006a8:	83 c4 08             	add    $0x8,%esp
  8006ab:	53                   	push   %ebx
  8006ac:	6a 58                	push   $0x58
  8006ae:	ff d6                	call   *%esi
			break;
  8006b0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006b3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8006b6:	e9 8b fc ff ff       	jmp    800346 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8006bb:	83 ec 08             	sub    $0x8,%esp
  8006be:	53                   	push   %ebx
  8006bf:	6a 30                	push   $0x30
  8006c1:	ff d6                	call   *%esi
			putch('x', putdat);
  8006c3:	83 c4 08             	add    $0x8,%esp
  8006c6:	53                   	push   %ebx
  8006c7:	6a 78                	push   $0x78
  8006c9:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ce:	8b 10                	mov    (%eax),%edx
  8006d0:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006d5:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006d8:	8d 40 04             	lea    0x4(%eax),%eax
  8006db:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006de:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006e3:	eb 4a                	jmp    80072f <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006e5:	83 f9 01             	cmp    $0x1,%ecx
  8006e8:	7e 15                	jle    8006ff <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006ea:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ed:	8b 10                	mov    (%eax),%edx
  8006ef:	8b 48 04             	mov    0x4(%eax),%ecx
  8006f2:	8d 40 08             	lea    0x8(%eax),%eax
  8006f5:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006f8:	b8 10 00 00 00       	mov    $0x10,%eax
  8006fd:	eb 30                	jmp    80072f <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006ff:	85 c9                	test   %ecx,%ecx
  800701:	74 17                	je     80071a <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800703:	8b 45 14             	mov    0x14(%ebp),%eax
  800706:	8b 10                	mov    (%eax),%edx
  800708:	b9 00 00 00 00       	mov    $0x0,%ecx
  80070d:	8d 40 04             	lea    0x4(%eax),%eax
  800710:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800713:	b8 10 00 00 00       	mov    $0x10,%eax
  800718:	eb 15                	jmp    80072f <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80071a:	8b 45 14             	mov    0x14(%ebp),%eax
  80071d:	8b 10                	mov    (%eax),%edx
  80071f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800724:	8d 40 04             	lea    0x4(%eax),%eax
  800727:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80072a:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80072f:	83 ec 0c             	sub    $0xc,%esp
  800732:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800736:	57                   	push   %edi
  800737:	ff 75 e0             	pushl  -0x20(%ebp)
  80073a:	50                   	push   %eax
  80073b:	51                   	push   %ecx
  80073c:	52                   	push   %edx
  80073d:	89 da                	mov    %ebx,%edx
  80073f:	89 f0                	mov    %esi,%eax
  800741:	e8 f1 fa ff ff       	call   800237 <printnum>
			break;
  800746:	83 c4 20             	add    $0x20,%esp
  800749:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80074c:	e9 f5 fb ff ff       	jmp    800346 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800751:	83 ec 08             	sub    $0x8,%esp
  800754:	53                   	push   %ebx
  800755:	52                   	push   %edx
  800756:	ff d6                	call   *%esi
			break;
  800758:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80075b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80075e:	e9 e3 fb ff ff       	jmp    800346 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800763:	83 ec 08             	sub    $0x8,%esp
  800766:	53                   	push   %ebx
  800767:	6a 25                	push   $0x25
  800769:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80076b:	83 c4 10             	add    $0x10,%esp
  80076e:	eb 03                	jmp    800773 <vprintfmt+0x453>
  800770:	83 ef 01             	sub    $0x1,%edi
  800773:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800777:	75 f7                	jne    800770 <vprintfmt+0x450>
  800779:	e9 c8 fb ff ff       	jmp    800346 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80077e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800781:	5b                   	pop    %ebx
  800782:	5e                   	pop    %esi
  800783:	5f                   	pop    %edi
  800784:	5d                   	pop    %ebp
  800785:	c3                   	ret    

00800786 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800786:	55                   	push   %ebp
  800787:	89 e5                	mov    %esp,%ebp
  800789:	83 ec 18             	sub    $0x18,%esp
  80078c:	8b 45 08             	mov    0x8(%ebp),%eax
  80078f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800792:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800795:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800799:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80079c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007a3:	85 c0                	test   %eax,%eax
  8007a5:	74 26                	je     8007cd <vsnprintf+0x47>
  8007a7:	85 d2                	test   %edx,%edx
  8007a9:	7e 22                	jle    8007cd <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007ab:	ff 75 14             	pushl  0x14(%ebp)
  8007ae:	ff 75 10             	pushl  0x10(%ebp)
  8007b1:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007b4:	50                   	push   %eax
  8007b5:	68 e6 02 80 00       	push   $0x8002e6
  8007ba:	e8 61 fb ff ff       	call   800320 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007c2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007c8:	83 c4 10             	add    $0x10,%esp
  8007cb:	eb 05                	jmp    8007d2 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007cd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007d2:	c9                   	leave  
  8007d3:	c3                   	ret    

008007d4 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007d4:	55                   	push   %ebp
  8007d5:	89 e5                	mov    %esp,%ebp
  8007d7:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007da:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007dd:	50                   	push   %eax
  8007de:	ff 75 10             	pushl  0x10(%ebp)
  8007e1:	ff 75 0c             	pushl  0xc(%ebp)
  8007e4:	ff 75 08             	pushl  0x8(%ebp)
  8007e7:	e8 9a ff ff ff       	call   800786 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007ec:	c9                   	leave  
  8007ed:	c3                   	ret    

008007ee <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007ee:	55                   	push   %ebp
  8007ef:	89 e5                	mov    %esp,%ebp
  8007f1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007f4:	b8 00 00 00 00       	mov    $0x0,%eax
  8007f9:	eb 03                	jmp    8007fe <strlen+0x10>
		n++;
  8007fb:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007fe:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800802:	75 f7                	jne    8007fb <strlen+0xd>
		n++;
	return n;
}
  800804:	5d                   	pop    %ebp
  800805:	c3                   	ret    

00800806 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800806:	55                   	push   %ebp
  800807:	89 e5                	mov    %esp,%ebp
  800809:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80080c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80080f:	ba 00 00 00 00       	mov    $0x0,%edx
  800814:	eb 03                	jmp    800819 <strnlen+0x13>
		n++;
  800816:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800819:	39 c2                	cmp    %eax,%edx
  80081b:	74 08                	je     800825 <strnlen+0x1f>
  80081d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800821:	75 f3                	jne    800816 <strnlen+0x10>
  800823:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800825:	5d                   	pop    %ebp
  800826:	c3                   	ret    

00800827 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800827:	55                   	push   %ebp
  800828:	89 e5                	mov    %esp,%ebp
  80082a:	53                   	push   %ebx
  80082b:	8b 45 08             	mov    0x8(%ebp),%eax
  80082e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800831:	89 c2                	mov    %eax,%edx
  800833:	83 c2 01             	add    $0x1,%edx
  800836:	83 c1 01             	add    $0x1,%ecx
  800839:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80083d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800840:	84 db                	test   %bl,%bl
  800842:	75 ef                	jne    800833 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800844:	5b                   	pop    %ebx
  800845:	5d                   	pop    %ebp
  800846:	c3                   	ret    

00800847 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800847:	55                   	push   %ebp
  800848:	89 e5                	mov    %esp,%ebp
  80084a:	53                   	push   %ebx
  80084b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80084e:	53                   	push   %ebx
  80084f:	e8 9a ff ff ff       	call   8007ee <strlen>
  800854:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800857:	ff 75 0c             	pushl  0xc(%ebp)
  80085a:	01 d8                	add    %ebx,%eax
  80085c:	50                   	push   %eax
  80085d:	e8 c5 ff ff ff       	call   800827 <strcpy>
	return dst;
}
  800862:	89 d8                	mov    %ebx,%eax
  800864:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800867:	c9                   	leave  
  800868:	c3                   	ret    

00800869 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800869:	55                   	push   %ebp
  80086a:	89 e5                	mov    %esp,%ebp
  80086c:	56                   	push   %esi
  80086d:	53                   	push   %ebx
  80086e:	8b 75 08             	mov    0x8(%ebp),%esi
  800871:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800874:	89 f3                	mov    %esi,%ebx
  800876:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800879:	89 f2                	mov    %esi,%edx
  80087b:	eb 0f                	jmp    80088c <strncpy+0x23>
		*dst++ = *src;
  80087d:	83 c2 01             	add    $0x1,%edx
  800880:	0f b6 01             	movzbl (%ecx),%eax
  800883:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800886:	80 39 01             	cmpb   $0x1,(%ecx)
  800889:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80088c:	39 da                	cmp    %ebx,%edx
  80088e:	75 ed                	jne    80087d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800890:	89 f0                	mov    %esi,%eax
  800892:	5b                   	pop    %ebx
  800893:	5e                   	pop    %esi
  800894:	5d                   	pop    %ebp
  800895:	c3                   	ret    

00800896 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800896:	55                   	push   %ebp
  800897:	89 e5                	mov    %esp,%ebp
  800899:	56                   	push   %esi
  80089a:	53                   	push   %ebx
  80089b:	8b 75 08             	mov    0x8(%ebp),%esi
  80089e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008a1:	8b 55 10             	mov    0x10(%ebp),%edx
  8008a4:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008a6:	85 d2                	test   %edx,%edx
  8008a8:	74 21                	je     8008cb <strlcpy+0x35>
  8008aa:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8008ae:	89 f2                	mov    %esi,%edx
  8008b0:	eb 09                	jmp    8008bb <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008b2:	83 c2 01             	add    $0x1,%edx
  8008b5:	83 c1 01             	add    $0x1,%ecx
  8008b8:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008bb:	39 c2                	cmp    %eax,%edx
  8008bd:	74 09                	je     8008c8 <strlcpy+0x32>
  8008bf:	0f b6 19             	movzbl (%ecx),%ebx
  8008c2:	84 db                	test   %bl,%bl
  8008c4:	75 ec                	jne    8008b2 <strlcpy+0x1c>
  8008c6:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008c8:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008cb:	29 f0                	sub    %esi,%eax
}
  8008cd:	5b                   	pop    %ebx
  8008ce:	5e                   	pop    %esi
  8008cf:	5d                   	pop    %ebp
  8008d0:	c3                   	ret    

008008d1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008d1:	55                   	push   %ebp
  8008d2:	89 e5                	mov    %esp,%ebp
  8008d4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008d7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008da:	eb 06                	jmp    8008e2 <strcmp+0x11>
		p++, q++;
  8008dc:	83 c1 01             	add    $0x1,%ecx
  8008df:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008e2:	0f b6 01             	movzbl (%ecx),%eax
  8008e5:	84 c0                	test   %al,%al
  8008e7:	74 04                	je     8008ed <strcmp+0x1c>
  8008e9:	3a 02                	cmp    (%edx),%al
  8008eb:	74 ef                	je     8008dc <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ed:	0f b6 c0             	movzbl %al,%eax
  8008f0:	0f b6 12             	movzbl (%edx),%edx
  8008f3:	29 d0                	sub    %edx,%eax
}
  8008f5:	5d                   	pop    %ebp
  8008f6:	c3                   	ret    

008008f7 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008f7:	55                   	push   %ebp
  8008f8:	89 e5                	mov    %esp,%ebp
  8008fa:	53                   	push   %ebx
  8008fb:	8b 45 08             	mov    0x8(%ebp),%eax
  8008fe:	8b 55 0c             	mov    0xc(%ebp),%edx
  800901:	89 c3                	mov    %eax,%ebx
  800903:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800906:	eb 06                	jmp    80090e <strncmp+0x17>
		n--, p++, q++;
  800908:	83 c0 01             	add    $0x1,%eax
  80090b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80090e:	39 d8                	cmp    %ebx,%eax
  800910:	74 15                	je     800927 <strncmp+0x30>
  800912:	0f b6 08             	movzbl (%eax),%ecx
  800915:	84 c9                	test   %cl,%cl
  800917:	74 04                	je     80091d <strncmp+0x26>
  800919:	3a 0a                	cmp    (%edx),%cl
  80091b:	74 eb                	je     800908 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80091d:	0f b6 00             	movzbl (%eax),%eax
  800920:	0f b6 12             	movzbl (%edx),%edx
  800923:	29 d0                	sub    %edx,%eax
  800925:	eb 05                	jmp    80092c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800927:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80092c:	5b                   	pop    %ebx
  80092d:	5d                   	pop    %ebp
  80092e:	c3                   	ret    

0080092f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80092f:	55                   	push   %ebp
  800930:	89 e5                	mov    %esp,%ebp
  800932:	8b 45 08             	mov    0x8(%ebp),%eax
  800935:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800939:	eb 07                	jmp    800942 <strchr+0x13>
		if (*s == c)
  80093b:	38 ca                	cmp    %cl,%dl
  80093d:	74 0f                	je     80094e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80093f:	83 c0 01             	add    $0x1,%eax
  800942:	0f b6 10             	movzbl (%eax),%edx
  800945:	84 d2                	test   %dl,%dl
  800947:	75 f2                	jne    80093b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800949:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80094e:	5d                   	pop    %ebp
  80094f:	c3                   	ret    

00800950 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800950:	55                   	push   %ebp
  800951:	89 e5                	mov    %esp,%ebp
  800953:	8b 45 08             	mov    0x8(%ebp),%eax
  800956:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80095a:	eb 03                	jmp    80095f <strfind+0xf>
  80095c:	83 c0 01             	add    $0x1,%eax
  80095f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800962:	38 ca                	cmp    %cl,%dl
  800964:	74 04                	je     80096a <strfind+0x1a>
  800966:	84 d2                	test   %dl,%dl
  800968:	75 f2                	jne    80095c <strfind+0xc>
			break;
	return (char *) s;
}
  80096a:	5d                   	pop    %ebp
  80096b:	c3                   	ret    

0080096c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80096c:	55                   	push   %ebp
  80096d:	89 e5                	mov    %esp,%ebp
  80096f:	57                   	push   %edi
  800970:	56                   	push   %esi
  800971:	53                   	push   %ebx
  800972:	8b 7d 08             	mov    0x8(%ebp),%edi
  800975:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800978:	85 c9                	test   %ecx,%ecx
  80097a:	74 36                	je     8009b2 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80097c:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800982:	75 28                	jne    8009ac <memset+0x40>
  800984:	f6 c1 03             	test   $0x3,%cl
  800987:	75 23                	jne    8009ac <memset+0x40>
		c &= 0xFF;
  800989:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80098d:	89 d3                	mov    %edx,%ebx
  80098f:	c1 e3 08             	shl    $0x8,%ebx
  800992:	89 d6                	mov    %edx,%esi
  800994:	c1 e6 18             	shl    $0x18,%esi
  800997:	89 d0                	mov    %edx,%eax
  800999:	c1 e0 10             	shl    $0x10,%eax
  80099c:	09 f0                	or     %esi,%eax
  80099e:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8009a0:	89 d8                	mov    %ebx,%eax
  8009a2:	09 d0                	or     %edx,%eax
  8009a4:	c1 e9 02             	shr    $0x2,%ecx
  8009a7:	fc                   	cld    
  8009a8:	f3 ab                	rep stos %eax,%es:(%edi)
  8009aa:	eb 06                	jmp    8009b2 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009ac:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009af:	fc                   	cld    
  8009b0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009b2:	89 f8                	mov    %edi,%eax
  8009b4:	5b                   	pop    %ebx
  8009b5:	5e                   	pop    %esi
  8009b6:	5f                   	pop    %edi
  8009b7:	5d                   	pop    %ebp
  8009b8:	c3                   	ret    

008009b9 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009b9:	55                   	push   %ebp
  8009ba:	89 e5                	mov    %esp,%ebp
  8009bc:	57                   	push   %edi
  8009bd:	56                   	push   %esi
  8009be:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c1:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009c4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009c7:	39 c6                	cmp    %eax,%esi
  8009c9:	73 35                	jae    800a00 <memmove+0x47>
  8009cb:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009ce:	39 d0                	cmp    %edx,%eax
  8009d0:	73 2e                	jae    800a00 <memmove+0x47>
		s += n;
		d += n;
  8009d2:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009d5:	89 d6                	mov    %edx,%esi
  8009d7:	09 fe                	or     %edi,%esi
  8009d9:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009df:	75 13                	jne    8009f4 <memmove+0x3b>
  8009e1:	f6 c1 03             	test   $0x3,%cl
  8009e4:	75 0e                	jne    8009f4 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009e6:	83 ef 04             	sub    $0x4,%edi
  8009e9:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009ec:	c1 e9 02             	shr    $0x2,%ecx
  8009ef:	fd                   	std    
  8009f0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009f2:	eb 09                	jmp    8009fd <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009f4:	83 ef 01             	sub    $0x1,%edi
  8009f7:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009fa:	fd                   	std    
  8009fb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009fd:	fc                   	cld    
  8009fe:	eb 1d                	jmp    800a1d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a00:	89 f2                	mov    %esi,%edx
  800a02:	09 c2                	or     %eax,%edx
  800a04:	f6 c2 03             	test   $0x3,%dl
  800a07:	75 0f                	jne    800a18 <memmove+0x5f>
  800a09:	f6 c1 03             	test   $0x3,%cl
  800a0c:	75 0a                	jne    800a18 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a0e:	c1 e9 02             	shr    $0x2,%ecx
  800a11:	89 c7                	mov    %eax,%edi
  800a13:	fc                   	cld    
  800a14:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a16:	eb 05                	jmp    800a1d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a18:	89 c7                	mov    %eax,%edi
  800a1a:	fc                   	cld    
  800a1b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a1d:	5e                   	pop    %esi
  800a1e:	5f                   	pop    %edi
  800a1f:	5d                   	pop    %ebp
  800a20:	c3                   	ret    

00800a21 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a21:	55                   	push   %ebp
  800a22:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a24:	ff 75 10             	pushl  0x10(%ebp)
  800a27:	ff 75 0c             	pushl  0xc(%ebp)
  800a2a:	ff 75 08             	pushl  0x8(%ebp)
  800a2d:	e8 87 ff ff ff       	call   8009b9 <memmove>
}
  800a32:	c9                   	leave  
  800a33:	c3                   	ret    

00800a34 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a34:	55                   	push   %ebp
  800a35:	89 e5                	mov    %esp,%ebp
  800a37:	56                   	push   %esi
  800a38:	53                   	push   %ebx
  800a39:	8b 45 08             	mov    0x8(%ebp),%eax
  800a3c:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a3f:	89 c6                	mov    %eax,%esi
  800a41:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a44:	eb 1a                	jmp    800a60 <memcmp+0x2c>
		if (*s1 != *s2)
  800a46:	0f b6 08             	movzbl (%eax),%ecx
  800a49:	0f b6 1a             	movzbl (%edx),%ebx
  800a4c:	38 d9                	cmp    %bl,%cl
  800a4e:	74 0a                	je     800a5a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a50:	0f b6 c1             	movzbl %cl,%eax
  800a53:	0f b6 db             	movzbl %bl,%ebx
  800a56:	29 d8                	sub    %ebx,%eax
  800a58:	eb 0f                	jmp    800a69 <memcmp+0x35>
		s1++, s2++;
  800a5a:	83 c0 01             	add    $0x1,%eax
  800a5d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a60:	39 f0                	cmp    %esi,%eax
  800a62:	75 e2                	jne    800a46 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a64:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a69:	5b                   	pop    %ebx
  800a6a:	5e                   	pop    %esi
  800a6b:	5d                   	pop    %ebp
  800a6c:	c3                   	ret    

00800a6d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a6d:	55                   	push   %ebp
  800a6e:	89 e5                	mov    %esp,%ebp
  800a70:	53                   	push   %ebx
  800a71:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a74:	89 c1                	mov    %eax,%ecx
  800a76:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a79:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a7d:	eb 0a                	jmp    800a89 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a7f:	0f b6 10             	movzbl (%eax),%edx
  800a82:	39 da                	cmp    %ebx,%edx
  800a84:	74 07                	je     800a8d <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a86:	83 c0 01             	add    $0x1,%eax
  800a89:	39 c8                	cmp    %ecx,%eax
  800a8b:	72 f2                	jb     800a7f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a8d:	5b                   	pop    %ebx
  800a8e:	5d                   	pop    %ebp
  800a8f:	c3                   	ret    

00800a90 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a90:	55                   	push   %ebp
  800a91:	89 e5                	mov    %esp,%ebp
  800a93:	57                   	push   %edi
  800a94:	56                   	push   %esi
  800a95:	53                   	push   %ebx
  800a96:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a99:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a9c:	eb 03                	jmp    800aa1 <strtol+0x11>
		s++;
  800a9e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aa1:	0f b6 01             	movzbl (%ecx),%eax
  800aa4:	3c 20                	cmp    $0x20,%al
  800aa6:	74 f6                	je     800a9e <strtol+0xe>
  800aa8:	3c 09                	cmp    $0x9,%al
  800aaa:	74 f2                	je     800a9e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800aac:	3c 2b                	cmp    $0x2b,%al
  800aae:	75 0a                	jne    800aba <strtol+0x2a>
		s++;
  800ab0:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ab3:	bf 00 00 00 00       	mov    $0x0,%edi
  800ab8:	eb 11                	jmp    800acb <strtol+0x3b>
  800aba:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800abf:	3c 2d                	cmp    $0x2d,%al
  800ac1:	75 08                	jne    800acb <strtol+0x3b>
		s++, neg = 1;
  800ac3:	83 c1 01             	add    $0x1,%ecx
  800ac6:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800acb:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ad1:	75 15                	jne    800ae8 <strtol+0x58>
  800ad3:	80 39 30             	cmpb   $0x30,(%ecx)
  800ad6:	75 10                	jne    800ae8 <strtol+0x58>
  800ad8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800adc:	75 7c                	jne    800b5a <strtol+0xca>
		s += 2, base = 16;
  800ade:	83 c1 02             	add    $0x2,%ecx
  800ae1:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ae6:	eb 16                	jmp    800afe <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800ae8:	85 db                	test   %ebx,%ebx
  800aea:	75 12                	jne    800afe <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800aec:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800af1:	80 39 30             	cmpb   $0x30,(%ecx)
  800af4:	75 08                	jne    800afe <strtol+0x6e>
		s++, base = 8;
  800af6:	83 c1 01             	add    $0x1,%ecx
  800af9:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800afe:	b8 00 00 00 00       	mov    $0x0,%eax
  800b03:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b06:	0f b6 11             	movzbl (%ecx),%edx
  800b09:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b0c:	89 f3                	mov    %esi,%ebx
  800b0e:	80 fb 09             	cmp    $0x9,%bl
  800b11:	77 08                	ja     800b1b <strtol+0x8b>
			dig = *s - '0';
  800b13:	0f be d2             	movsbl %dl,%edx
  800b16:	83 ea 30             	sub    $0x30,%edx
  800b19:	eb 22                	jmp    800b3d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b1b:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b1e:	89 f3                	mov    %esi,%ebx
  800b20:	80 fb 19             	cmp    $0x19,%bl
  800b23:	77 08                	ja     800b2d <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b25:	0f be d2             	movsbl %dl,%edx
  800b28:	83 ea 57             	sub    $0x57,%edx
  800b2b:	eb 10                	jmp    800b3d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b2d:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b30:	89 f3                	mov    %esi,%ebx
  800b32:	80 fb 19             	cmp    $0x19,%bl
  800b35:	77 16                	ja     800b4d <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b37:	0f be d2             	movsbl %dl,%edx
  800b3a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b3d:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b40:	7d 0b                	jge    800b4d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b42:	83 c1 01             	add    $0x1,%ecx
  800b45:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b49:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b4b:	eb b9                	jmp    800b06 <strtol+0x76>

	if (endptr)
  800b4d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b51:	74 0d                	je     800b60 <strtol+0xd0>
		*endptr = (char *) s;
  800b53:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b56:	89 0e                	mov    %ecx,(%esi)
  800b58:	eb 06                	jmp    800b60 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b5a:	85 db                	test   %ebx,%ebx
  800b5c:	74 98                	je     800af6 <strtol+0x66>
  800b5e:	eb 9e                	jmp    800afe <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b60:	89 c2                	mov    %eax,%edx
  800b62:	f7 da                	neg    %edx
  800b64:	85 ff                	test   %edi,%edi
  800b66:	0f 45 c2             	cmovne %edx,%eax
}
  800b69:	5b                   	pop    %ebx
  800b6a:	5e                   	pop    %esi
  800b6b:	5f                   	pop    %edi
  800b6c:	5d                   	pop    %ebp
  800b6d:	c3                   	ret    

00800b6e <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b6e:	55                   	push   %ebp
  800b6f:	89 e5                	mov    %esp,%ebp
  800b71:	57                   	push   %edi
  800b72:	56                   	push   %esi
  800b73:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b74:	b8 00 00 00 00       	mov    $0x0,%eax
  800b79:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b7c:	8b 55 08             	mov    0x8(%ebp),%edx
  800b7f:	89 c3                	mov    %eax,%ebx
  800b81:	89 c7                	mov    %eax,%edi
  800b83:	89 c6                	mov    %eax,%esi
  800b85:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b87:	5b                   	pop    %ebx
  800b88:	5e                   	pop    %esi
  800b89:	5f                   	pop    %edi
  800b8a:	5d                   	pop    %ebp
  800b8b:	c3                   	ret    

00800b8c <sys_cgetc>:

int
sys_cgetc(void)
{
  800b8c:	55                   	push   %ebp
  800b8d:	89 e5                	mov    %esp,%ebp
  800b8f:	57                   	push   %edi
  800b90:	56                   	push   %esi
  800b91:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b92:	ba 00 00 00 00       	mov    $0x0,%edx
  800b97:	b8 01 00 00 00       	mov    $0x1,%eax
  800b9c:	89 d1                	mov    %edx,%ecx
  800b9e:	89 d3                	mov    %edx,%ebx
  800ba0:	89 d7                	mov    %edx,%edi
  800ba2:	89 d6                	mov    %edx,%esi
  800ba4:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ba6:	5b                   	pop    %ebx
  800ba7:	5e                   	pop    %esi
  800ba8:	5f                   	pop    %edi
  800ba9:	5d                   	pop    %ebp
  800baa:	c3                   	ret    

00800bab <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800bab:	55                   	push   %ebp
  800bac:	89 e5                	mov    %esp,%ebp
  800bae:	57                   	push   %edi
  800baf:	56                   	push   %esi
  800bb0:	53                   	push   %ebx
  800bb1:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bb4:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bb9:	b8 03 00 00 00       	mov    $0x3,%eax
  800bbe:	8b 55 08             	mov    0x8(%ebp),%edx
  800bc1:	89 cb                	mov    %ecx,%ebx
  800bc3:	89 cf                	mov    %ecx,%edi
  800bc5:	89 ce                	mov    %ecx,%esi
  800bc7:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bc9:	85 c0                	test   %eax,%eax
  800bcb:	7e 17                	jle    800be4 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bcd:	83 ec 0c             	sub    $0xc,%esp
  800bd0:	50                   	push   %eax
  800bd1:	6a 03                	push   $0x3
  800bd3:	68 a4 17 80 00       	push   $0x8017a4
  800bd8:	6a 23                	push   $0x23
  800bda:	68 c1 17 80 00       	push   $0x8017c1
  800bdf:	e8 66 f5 ff ff       	call   80014a <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800be4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800be7:	5b                   	pop    %ebx
  800be8:	5e                   	pop    %esi
  800be9:	5f                   	pop    %edi
  800bea:	5d                   	pop    %ebp
  800beb:	c3                   	ret    

00800bec <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bec:	55                   	push   %ebp
  800bed:	89 e5                	mov    %esp,%ebp
  800bef:	57                   	push   %edi
  800bf0:	56                   	push   %esi
  800bf1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bf2:	ba 00 00 00 00       	mov    $0x0,%edx
  800bf7:	b8 02 00 00 00       	mov    $0x2,%eax
  800bfc:	89 d1                	mov    %edx,%ecx
  800bfe:	89 d3                	mov    %edx,%ebx
  800c00:	89 d7                	mov    %edx,%edi
  800c02:	89 d6                	mov    %edx,%esi
  800c04:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c06:	5b                   	pop    %ebx
  800c07:	5e                   	pop    %esi
  800c08:	5f                   	pop    %edi
  800c09:	5d                   	pop    %ebp
  800c0a:	c3                   	ret    

00800c0b <sys_yield>:

void
sys_yield(void)
{
  800c0b:	55                   	push   %ebp
  800c0c:	89 e5                	mov    %esp,%ebp
  800c0e:	57                   	push   %edi
  800c0f:	56                   	push   %esi
  800c10:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c11:	ba 00 00 00 00       	mov    $0x0,%edx
  800c16:	b8 0a 00 00 00       	mov    $0xa,%eax
  800c1b:	89 d1                	mov    %edx,%ecx
  800c1d:	89 d3                	mov    %edx,%ebx
  800c1f:	89 d7                	mov    %edx,%edi
  800c21:	89 d6                	mov    %edx,%esi
  800c23:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800c25:	5b                   	pop    %ebx
  800c26:	5e                   	pop    %esi
  800c27:	5f                   	pop    %edi
  800c28:	5d                   	pop    %ebp
  800c29:	c3                   	ret    

00800c2a <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800c2a:	55                   	push   %ebp
  800c2b:	89 e5                	mov    %esp,%ebp
  800c2d:	57                   	push   %edi
  800c2e:	56                   	push   %esi
  800c2f:	53                   	push   %ebx
  800c30:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c33:	be 00 00 00 00       	mov    $0x0,%esi
  800c38:	b8 04 00 00 00       	mov    $0x4,%eax
  800c3d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c40:	8b 55 08             	mov    0x8(%ebp),%edx
  800c43:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c46:	89 f7                	mov    %esi,%edi
  800c48:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c4a:	85 c0                	test   %eax,%eax
  800c4c:	7e 17                	jle    800c65 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c4e:	83 ec 0c             	sub    $0xc,%esp
  800c51:	50                   	push   %eax
  800c52:	6a 04                	push   $0x4
  800c54:	68 a4 17 80 00       	push   $0x8017a4
  800c59:	6a 23                	push   $0x23
  800c5b:	68 c1 17 80 00       	push   $0x8017c1
  800c60:	e8 e5 f4 ff ff       	call   80014a <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800c65:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c68:	5b                   	pop    %ebx
  800c69:	5e                   	pop    %esi
  800c6a:	5f                   	pop    %edi
  800c6b:	5d                   	pop    %ebp
  800c6c:	c3                   	ret    

00800c6d <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800c6d:	55                   	push   %ebp
  800c6e:	89 e5                	mov    %esp,%ebp
  800c70:	57                   	push   %edi
  800c71:	56                   	push   %esi
  800c72:	53                   	push   %ebx
  800c73:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c76:	b8 05 00 00 00       	mov    $0x5,%eax
  800c7b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c7e:	8b 55 08             	mov    0x8(%ebp),%edx
  800c81:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c84:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c87:	8b 75 18             	mov    0x18(%ebp),%esi
  800c8a:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c8c:	85 c0                	test   %eax,%eax
  800c8e:	7e 17                	jle    800ca7 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c90:	83 ec 0c             	sub    $0xc,%esp
  800c93:	50                   	push   %eax
  800c94:	6a 05                	push   $0x5
  800c96:	68 a4 17 80 00       	push   $0x8017a4
  800c9b:	6a 23                	push   $0x23
  800c9d:	68 c1 17 80 00       	push   $0x8017c1
  800ca2:	e8 a3 f4 ff ff       	call   80014a <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800ca7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800caa:	5b                   	pop    %ebx
  800cab:	5e                   	pop    %esi
  800cac:	5f                   	pop    %edi
  800cad:	5d                   	pop    %ebp
  800cae:	c3                   	ret    

00800caf <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800caf:	55                   	push   %ebp
  800cb0:	89 e5                	mov    %esp,%ebp
  800cb2:	57                   	push   %edi
  800cb3:	56                   	push   %esi
  800cb4:	53                   	push   %ebx
  800cb5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cb8:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cbd:	b8 06 00 00 00       	mov    $0x6,%eax
  800cc2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cc5:	8b 55 08             	mov    0x8(%ebp),%edx
  800cc8:	89 df                	mov    %ebx,%edi
  800cca:	89 de                	mov    %ebx,%esi
  800ccc:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cce:	85 c0                	test   %eax,%eax
  800cd0:	7e 17                	jle    800ce9 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cd2:	83 ec 0c             	sub    $0xc,%esp
  800cd5:	50                   	push   %eax
  800cd6:	6a 06                	push   $0x6
  800cd8:	68 a4 17 80 00       	push   $0x8017a4
  800cdd:	6a 23                	push   $0x23
  800cdf:	68 c1 17 80 00       	push   $0x8017c1
  800ce4:	e8 61 f4 ff ff       	call   80014a <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800ce9:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cec:	5b                   	pop    %ebx
  800ced:	5e                   	pop    %esi
  800cee:	5f                   	pop    %edi
  800cef:	5d                   	pop    %ebp
  800cf0:	c3                   	ret    

00800cf1 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800cf1:	55                   	push   %ebp
  800cf2:	89 e5                	mov    %esp,%ebp
  800cf4:	57                   	push   %edi
  800cf5:	56                   	push   %esi
  800cf6:	53                   	push   %ebx
  800cf7:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cfa:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cff:	b8 08 00 00 00       	mov    $0x8,%eax
  800d04:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d07:	8b 55 08             	mov    0x8(%ebp),%edx
  800d0a:	89 df                	mov    %ebx,%edi
  800d0c:	89 de                	mov    %ebx,%esi
  800d0e:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d10:	85 c0                	test   %eax,%eax
  800d12:	7e 17                	jle    800d2b <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d14:	83 ec 0c             	sub    $0xc,%esp
  800d17:	50                   	push   %eax
  800d18:	6a 08                	push   $0x8
  800d1a:	68 a4 17 80 00       	push   $0x8017a4
  800d1f:	6a 23                	push   $0x23
  800d21:	68 c1 17 80 00       	push   $0x8017c1
  800d26:	e8 1f f4 ff ff       	call   80014a <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800d2b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d2e:	5b                   	pop    %ebx
  800d2f:	5e                   	pop    %esi
  800d30:	5f                   	pop    %edi
  800d31:	5d                   	pop    %ebp
  800d32:	c3                   	ret    

00800d33 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800d33:	55                   	push   %ebp
  800d34:	89 e5                	mov    %esp,%ebp
  800d36:	57                   	push   %edi
  800d37:	56                   	push   %esi
  800d38:	53                   	push   %ebx
  800d39:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d3c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d41:	b8 09 00 00 00       	mov    $0x9,%eax
  800d46:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d49:	8b 55 08             	mov    0x8(%ebp),%edx
  800d4c:	89 df                	mov    %ebx,%edi
  800d4e:	89 de                	mov    %ebx,%esi
  800d50:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d52:	85 c0                	test   %eax,%eax
  800d54:	7e 17                	jle    800d6d <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d56:	83 ec 0c             	sub    $0xc,%esp
  800d59:	50                   	push   %eax
  800d5a:	6a 09                	push   $0x9
  800d5c:	68 a4 17 80 00       	push   $0x8017a4
  800d61:	6a 23                	push   $0x23
  800d63:	68 c1 17 80 00       	push   $0x8017c1
  800d68:	e8 dd f3 ff ff       	call   80014a <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800d6d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d70:	5b                   	pop    %ebx
  800d71:	5e                   	pop    %esi
  800d72:	5f                   	pop    %edi
  800d73:	5d                   	pop    %ebp
  800d74:	c3                   	ret    

00800d75 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800d75:	55                   	push   %ebp
  800d76:	89 e5                	mov    %esp,%ebp
  800d78:	57                   	push   %edi
  800d79:	56                   	push   %esi
  800d7a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d7b:	be 00 00 00 00       	mov    $0x0,%esi
  800d80:	b8 0b 00 00 00       	mov    $0xb,%eax
  800d85:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d88:	8b 55 08             	mov    0x8(%ebp),%edx
  800d8b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d8e:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d91:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800d93:	5b                   	pop    %ebx
  800d94:	5e                   	pop    %esi
  800d95:	5f                   	pop    %edi
  800d96:	5d                   	pop    %ebp
  800d97:	c3                   	ret    

00800d98 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800d98:	55                   	push   %ebp
  800d99:	89 e5                	mov    %esp,%ebp
  800d9b:	57                   	push   %edi
  800d9c:	56                   	push   %esi
  800d9d:	53                   	push   %ebx
  800d9e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800da1:	b9 00 00 00 00       	mov    $0x0,%ecx
  800da6:	b8 0c 00 00 00       	mov    $0xc,%eax
  800dab:	8b 55 08             	mov    0x8(%ebp),%edx
  800dae:	89 cb                	mov    %ecx,%ebx
  800db0:	89 cf                	mov    %ecx,%edi
  800db2:	89 ce                	mov    %ecx,%esi
  800db4:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800db6:	85 c0                	test   %eax,%eax
  800db8:	7e 17                	jle    800dd1 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800dba:	83 ec 0c             	sub    $0xc,%esp
  800dbd:	50                   	push   %eax
  800dbe:	6a 0c                	push   $0xc
  800dc0:	68 a4 17 80 00       	push   $0x8017a4
  800dc5:	6a 23                	push   $0x23
  800dc7:	68 c1 17 80 00       	push   $0x8017c1
  800dcc:	e8 79 f3 ff ff       	call   80014a <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800dd1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800dd4:	5b                   	pop    %ebx
  800dd5:	5e                   	pop    %esi
  800dd6:	5f                   	pop    %edi
  800dd7:	5d                   	pop    %ebp
  800dd8:	c3                   	ret    

00800dd9 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800dd9:	55                   	push   %ebp
  800dda:	89 e5                	mov    %esp,%ebp
  800ddc:	56                   	push   %esi
  800ddd:	53                   	push   %ebx
  800dde:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void *) utf->utf_fault_va;
  800de1:	8b 18                	mov    (%eax),%ebx
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if((err&FEC_WR)==0||(uvpt[PGNUM(addr)]&PTE_COW)==0)
  800de3:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  800de7:	74 11                	je     800dfa <pgfault+0x21>
  800de9:	89 d8                	mov    %ebx,%eax
  800deb:	c1 e8 0c             	shr    $0xc,%eax
  800dee:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800df5:	f6 c4 08             	test   $0x8,%ah
  800df8:	75 14                	jne    800e0e <pgfault+0x35>
		panic("pgfault:It's not a write or non-COW page\n"); 
  800dfa:	83 ec 04             	sub    $0x4,%esp
  800dfd:	68 d0 17 80 00       	push   $0x8017d0
  800e02:	6a 1c                	push   $0x1c
  800e04:	68 5b 18 80 00       	push   $0x80185b
  800e09:	e8 3c f3 ff ff       	call   80014a <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	uint32_t envid=sys_getenvid();
  800e0e:	e8 d9 fd ff ff       	call   800bec <sys_getenvid>
  800e13:	89 c6                	mov    %eax,%esi
	if((r=sys_page_alloc(envid,PFTEMP,PTE_P|PTE_U|PTE_W))<0)
  800e15:	83 ec 04             	sub    $0x4,%esp
  800e18:	6a 07                	push   $0x7
  800e1a:	68 00 f0 7f 00       	push   $0x7ff000
  800e1f:	50                   	push   %eax
  800e20:	e8 05 fe ff ff       	call   800c2a <sys_page_alloc>
  800e25:	83 c4 10             	add    $0x10,%esp
  800e28:	85 c0                	test   %eax,%eax
  800e2a:	79 14                	jns    800e40 <pgfault+0x67>
		panic("pgfault: error in PFTEMP\n");
  800e2c:	83 ec 04             	sub    $0x4,%esp
  800e2f:	68 66 18 80 00       	push   $0x801866
  800e34:	6a 26                	push   $0x26
  800e36:	68 5b 18 80 00       	push   $0x80185b
  800e3b:	e8 0a f3 ff ff       	call   80014a <_panic>
	addr=ROUNDDOWN(addr,PGSIZE);
  800e40:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	memmove(PFTEMP,addr,PGSIZE); 
  800e46:	83 ec 04             	sub    $0x4,%esp
  800e49:	68 00 10 00 00       	push   $0x1000
  800e4e:	53                   	push   %ebx
  800e4f:	68 00 f0 7f 00       	push   $0x7ff000
  800e54:	e8 60 fb ff ff       	call   8009b9 <memmove>
	if((r=sys_page_unmap(envid,addr))<0)
  800e59:	83 c4 08             	add    $0x8,%esp
  800e5c:	53                   	push   %ebx
  800e5d:	56                   	push   %esi
  800e5e:	e8 4c fe ff ff       	call   800caf <sys_page_unmap>
  800e63:	83 c4 10             	add    $0x10,%esp
  800e66:	85 c0                	test   %eax,%eax
  800e68:	79 14                	jns    800e7e <pgfault+0xa5>
		panic("pgfault:unmap\n");
  800e6a:	83 ec 04             	sub    $0x4,%esp
  800e6d:	68 80 18 80 00       	push   $0x801880
  800e72:	6a 2a                	push   $0x2a
  800e74:	68 5b 18 80 00       	push   $0x80185b
  800e79:	e8 cc f2 ff ff       	call   80014a <_panic>
	if((r=sys_page_map(envid,PFTEMP,envid,addr,PTE_P|PTE_U|PTE_W))<0)
  800e7e:	83 ec 0c             	sub    $0xc,%esp
  800e81:	6a 07                	push   $0x7
  800e83:	53                   	push   %ebx
  800e84:	56                   	push   %esi
  800e85:	68 00 f0 7f 00       	push   $0x7ff000
  800e8a:	56                   	push   %esi
  800e8b:	e8 dd fd ff ff       	call   800c6d <sys_page_map>
  800e90:	83 c4 20             	add    $0x20,%esp
  800e93:	85 c0                	test   %eax,%eax
  800e95:	79 14                	jns    800eab <pgfault+0xd2>
		panic("pgfault:map\n");
  800e97:	83 ec 04             	sub    $0x4,%esp
  800e9a:	68 8f 18 80 00       	push   $0x80188f
  800e9f:	6a 2c                	push   $0x2c
  800ea1:	68 5b 18 80 00       	push   $0x80185b
  800ea6:	e8 9f f2 ff ff       	call   80014a <_panic>
	if((r=sys_page_unmap(envid,PFTEMP))<0)
  800eab:	83 ec 08             	sub    $0x8,%esp
  800eae:	68 00 f0 7f 00       	push   $0x7ff000
  800eb3:	56                   	push   %esi
  800eb4:	e8 f6 fd ff ff       	call   800caf <sys_page_unmap>
  800eb9:	83 c4 10             	add    $0x10,%esp
  800ebc:	85 c0                	test   %eax,%eax
  800ebe:	79 14                	jns    800ed4 <pgfault+0xfb>
		panic("pgfault:unmap PFTEMP\n");
  800ec0:	83 ec 04             	sub    $0x4,%esp
  800ec3:	68 9c 18 80 00       	push   $0x80189c
  800ec8:	6a 2e                	push   $0x2e
  800eca:	68 5b 18 80 00       	push   $0x80185b
  800ecf:	e8 76 f2 ff ff       	call   80014a <_panic>
	//panic("pgfault not implemented");
}
  800ed4:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800ed7:	5b                   	pop    %ebx
  800ed8:	5e                   	pop    %esi
  800ed9:	5d                   	pop    %ebp
  800eda:	c3                   	ret    

00800edb <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800edb:	55                   	push   %ebp
  800edc:	89 e5                	mov    %esp,%ebp
  800ede:	57                   	push   %edi
  800edf:	56                   	push   %esi
  800ee0:	53                   	push   %ebx
  800ee1:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	set_pgfault_handler(pgfault);
  800ee4:	68 d9 0d 80 00       	push   $0x800dd9
  800ee9:	e8 f1 02 00 00       	call   8011df <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	asm volatile("int %2"
  800eee:	b8 07 00 00 00       	mov    $0x7,%eax
  800ef3:	cd 30                	int    $0x30
  800ef5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800ef8:	89 c7                	mov    %eax,%edi
  800efa:	89 45 e0             	mov    %eax,-0x20(%ebp)
	envid_t envid=sys_exofork();
	uint32_t addr;
	uint32_t fenvid=sys_getenvid();
  800efd:	e8 ea fc ff ff       	call   800bec <sys_getenvid>
	if(envid<0)
  800f02:	83 c4 10             	add    $0x10,%esp
  800f05:	85 ff                	test   %edi,%edi
  800f07:	79 14                	jns    800f1d <fork+0x42>
		panic("fork not implemented");
  800f09:	83 ec 04             	sub    $0x4,%esp
  800f0c:	68 ef 18 80 00       	push   $0x8018ef
  800f11:	6a 6f                	push   $0x6f
  800f13:	68 5b 18 80 00       	push   $0x80185b
  800f18:	e8 2d f2 ff ff       	call   80014a <_panic>
  800f1d:	bb 00 00 80 00       	mov    $0x800000,%ebx
	else if(envid==0)
  800f22:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800f26:	75 1c                	jne    800f44 <fork+0x69>
	{
		thisenv=&envs[ENVX(fenvid)];
  800f28:	25 ff 03 00 00       	and    $0x3ff,%eax
  800f2d:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800f30:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800f35:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  800f3a:	b8 00 00 00 00       	mov    $0x0,%eax
  800f3f:	e9 73 01 00 00       	jmp    8010b7 <fork+0x1dc>
	}
	for(addr=UTEXT;addr<USTACKTOP;addr+=PGSIZE)
	{
		if(((uvpd[PDX(addr)]&PTE_P)>0)&&((uvpt[PGNUM(addr)]&PTE_P)>0))
  800f44:	89 d8                	mov    %ebx,%eax
  800f46:	c1 e8 16             	shr    $0x16,%eax
  800f49:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  800f50:	a8 01                	test   $0x1,%al
  800f52:	0f 84 c4 00 00 00    	je     80101c <fork+0x141>
  800f58:	89 de                	mov    %ebx,%esi
  800f5a:	c1 ee 0c             	shr    $0xc,%esi
  800f5d:	8b 04 b5 00 00 40 ef 	mov    -0x10c00000(,%esi,4),%eax
  800f64:	a8 01                	test   $0x1,%al
  800f66:	0f 84 b0 00 00 00    	je     80101c <fork+0x141>
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	uint32_t fenvid=sys_getenvid();
  800f6c:	e8 7b fc ff ff       	call   800bec <sys_getenvid>
  800f71:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int perm=PTE_P|PTE_U;
	// LAB 4: Your code here.
	uint32_t addr=pn*PGSIZE;
  800f74:	89 f7                	mov    %esi,%edi
  800f76:	c1 e7 0c             	shl    $0xc,%edi
	if((uvpt[pn]&PTE_W)>0||(uvpt[pn]&PTE_COW)>0)
  800f79:	8b 04 b5 00 00 40 ef 	mov    -0x10c00000(,%esi,4),%eax
  800f80:	a8 02                	test   $0x2,%al
  800f82:	75 0c                	jne    800f90 <fork+0xb5>
  800f84:	8b 04 b5 00 00 40 ef 	mov    -0x10c00000(,%esi,4),%eax
  800f8b:	f6 c4 08             	test   $0x8,%ah
  800f8e:	74 5f                	je     800fef <fork+0x114>
	{
		perm=perm|PTE_COW;

		if((r=sys_page_map(fenvid,(void *)addr,envid,(void *)addr,perm))<0)
  800f90:	83 ec 0c             	sub    $0xc,%esp
  800f93:	68 05 08 00 00       	push   $0x805
  800f98:	57                   	push   %edi
  800f99:	ff 75 e0             	pushl  -0x20(%ebp)
  800f9c:	57                   	push   %edi
  800f9d:	ff 75 e4             	pushl  -0x1c(%ebp)
  800fa0:	e8 c8 fc ff ff       	call   800c6d <sys_page_map>
  800fa5:	83 c4 20             	add    $0x20,%esp
  800fa8:	85 c0                	test   %eax,%eax
  800faa:	79 14                	jns    800fc0 <fork+0xe5>
			panic("duppage: sys_page_map error 1\n");
  800fac:	83 ec 04             	sub    $0x4,%esp
  800faf:	68 fc 17 80 00       	push   $0x8017fc
  800fb4:	6a 4a                	push   $0x4a
  800fb6:	68 5b 18 80 00       	push   $0x80185b
  800fbb:	e8 8a f1 ff ff       	call   80014a <_panic>
		if((r=sys_page_map(fenvid,(void *)addr,fenvid,(void *)addr,perm))<0)
  800fc0:	83 ec 0c             	sub    $0xc,%esp
  800fc3:	68 05 08 00 00       	push   $0x805
  800fc8:	57                   	push   %edi
  800fc9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800fcc:	50                   	push   %eax
  800fcd:	57                   	push   %edi
  800fce:	50                   	push   %eax
  800fcf:	e8 99 fc ff ff       	call   800c6d <sys_page_map>
  800fd4:	83 c4 20             	add    $0x20,%esp
  800fd7:	85 c0                	test   %eax,%eax
  800fd9:	79 41                	jns    80101c <fork+0x141>
			panic("duppage: sys_page_map error 2\n");
  800fdb:	83 ec 04             	sub    $0x4,%esp
  800fde:	68 1c 18 80 00       	push   $0x80181c
  800fe3:	6a 4c                	push   $0x4c
  800fe5:	68 5b 18 80 00       	push   $0x80185b
  800fea:	e8 5b f1 ff ff       	call   80014a <_panic>
	}
	else
	{
		if((r=sys_page_map(fenvid,(void *)addr,envid,(void *)addr,perm))<0)
  800fef:	83 ec 0c             	sub    $0xc,%esp
  800ff2:	6a 05                	push   $0x5
  800ff4:	57                   	push   %edi
  800ff5:	ff 75 e0             	pushl  -0x20(%ebp)
  800ff8:	57                   	push   %edi
  800ff9:	ff 75 e4             	pushl  -0x1c(%ebp)
  800ffc:	e8 6c fc ff ff       	call   800c6d <sys_page_map>
  801001:	83 c4 20             	add    $0x20,%esp
  801004:	85 c0                	test   %eax,%eax
  801006:	79 14                	jns    80101c <fork+0x141>
			panic("duppage: sys_page_map error 3\n"); 
  801008:	83 ec 04             	sub    $0x4,%esp
  80100b:	68 3c 18 80 00       	push   $0x80183c
  801010:	6a 51                	push   $0x51
  801012:	68 5b 18 80 00       	push   $0x80185b
  801017:	e8 2e f1 ff ff       	call   80014a <_panic>
	else if(envid==0)
	{
		thisenv=&envs[ENVX(fenvid)];
		return 0;
	}
	for(addr=UTEXT;addr<USTACKTOP;addr+=PGSIZE)
  80101c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  801022:	81 fb 00 e0 bf ee    	cmp    $0xeebfe000,%ebx
  801028:	0f 85 16 ff ff ff    	jne    800f44 <fork+0x69>
		{
			duppage(envid,PGNUM(addr));
	
		}
	}
	if(sys_page_alloc(envid,(void *)(UXSTACKTOP-PGSIZE),PTE_P|PTE_U|PTE_W)<0)
  80102e:	83 ec 04             	sub    $0x4,%esp
  801031:	6a 07                	push   $0x7
  801033:	68 00 f0 bf ee       	push   $0xeebff000
  801038:	ff 75 dc             	pushl  -0x24(%ebp)
  80103b:	e8 ea fb ff ff       	call   800c2a <sys_page_alloc>
  801040:	83 c4 10             	add    $0x10,%esp
  801043:	85 c0                	test   %eax,%eax
  801045:	79 14                	jns    80105b <fork+0x180>
		panic("fork: page alloc\n");
  801047:	83 ec 04             	sub    $0x4,%esp
  80104a:	68 b2 18 80 00       	push   $0x8018b2
  80104f:	6a 7e                	push   $0x7e
  801051:	68 5b 18 80 00       	push   $0x80185b
  801056:	e8 ef f0 ff ff       	call   80014a <_panic>
	extern void _pgfault_upcall(void);
	if((sys_env_set_pgfault_upcall(envid, _pgfault_upcall))<0)
  80105b:	83 ec 08             	sub    $0x8,%esp
  80105e:	68 36 12 80 00       	push   $0x801236
  801063:	ff 75 dc             	pushl  -0x24(%ebp)
  801066:	e8 c8 fc ff ff       	call   800d33 <sys_env_set_pgfault_upcall>
  80106b:	83 c4 10             	add    $0x10,%esp
  80106e:	85 c0                	test   %eax,%eax
  801070:	79 17                	jns    801089 <fork+0x1ae>
		panic("fork:set pgfault upcall\n");
  801072:	83 ec 04             	sub    $0x4,%esp
  801075:	68 c4 18 80 00       	push   $0x8018c4
  80107a:	68 81 00 00 00       	push   $0x81
  80107f:	68 5b 18 80 00       	push   $0x80185b
  801084:	e8 c1 f0 ff ff       	call   80014a <_panic>
	if((sys_env_set_status(envid,ENV_RUNNABLE))<0)
  801089:	83 ec 08             	sub    $0x8,%esp
  80108c:	6a 02                	push   $0x2
  80108e:	ff 75 dc             	pushl  -0x24(%ebp)
  801091:	e8 5b fc ff ff       	call   800cf1 <sys_env_set_status>
  801096:	83 c4 10             	add    $0x10,%esp
  801099:	85 c0                	test   %eax,%eax
  80109b:	79 17                	jns    8010b4 <fork+0x1d9>
		panic("fork:set status\n");
  80109d:	83 ec 04             	sub    $0x4,%esp
  8010a0:	68 dd 18 80 00       	push   $0x8018dd
  8010a5:	68 83 00 00 00       	push   $0x83
  8010aa:	68 5b 18 80 00       	push   $0x80185b
  8010af:	e8 96 f0 ff ff       	call   80014a <_panic>
	return envid;
  8010b4:	8b 45 dc             	mov    -0x24(%ebp),%eax
		
}
  8010b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8010ba:	5b                   	pop    %ebx
  8010bb:	5e                   	pop    %esi
  8010bc:	5f                   	pop    %edi
  8010bd:	5d                   	pop    %ebp
  8010be:	c3                   	ret    

008010bf <sfork>:

// Challenge!
int
sfork(void)
{
  8010bf:	55                   	push   %ebp
  8010c0:	89 e5                	mov    %esp,%ebp
  8010c2:	83 ec 0c             	sub    $0xc,%esp
	panic("sfork not implemented");
  8010c5:	68 ee 18 80 00       	push   $0x8018ee
  8010ca:	68 8c 00 00 00       	push   $0x8c
  8010cf:	68 5b 18 80 00       	push   $0x80185b
  8010d4:	e8 71 f0 ff ff       	call   80014a <_panic>

008010d9 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  8010d9:	55                   	push   %ebp
  8010da:	89 e5                	mov    %esp,%ebp
  8010dc:	56                   	push   %esi
  8010dd:	53                   	push   %ebx
  8010de:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8010e1:	8b 75 10             	mov    0x10(%ebp),%esi
	// LAB 4: Your code here.
	int r;
	r=sys_ipc_recv(pg);
  8010e4:	83 ec 0c             	sub    $0xc,%esp
  8010e7:	ff 75 0c             	pushl  0xc(%ebp)
  8010ea:	e8 a9 fc ff ff       	call   800d98 <sys_ipc_recv>
	if(from_env_store!=NULL)
  8010ef:	83 c4 10             	add    $0x10,%esp
  8010f2:	85 db                	test   %ebx,%ebx
  8010f4:	74 25                	je     80111b <ipc_recv+0x42>
	{
		if(r<0)
  8010f6:	85 c0                	test   %eax,%eax
  8010f8:	79 11                	jns    80110b <ipc_recv+0x32>
			*from_env_store=0;
  8010fa:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
			*perm_store=0;
		else
			*perm_store=thisenv->env_ipc_perm;
	}
	if(r<0)
		return 0;
  801100:	b8 00 00 00 00       	mov    $0x0,%eax
		if(r<0)
			*from_env_store=0;
		else
			*from_env_store=thisenv->env_ipc_from;
	}
	if(perm_store!=NULL)
  801105:	85 f6                	test   %esi,%esi
  801107:	74 46                	je     80114f <ipc_recv+0x76>
  801109:	eb 18                	jmp    801123 <ipc_recv+0x4a>
	if(from_env_store!=NULL)
	{
		if(r<0)
			*from_env_store=0;
		else
			*from_env_store=thisenv->env_ipc_from;
  80110b:	a1 04 20 80 00       	mov    0x802004,%eax
  801110:	8b 40 74             	mov    0x74(%eax),%eax
  801113:	89 03                	mov    %eax,(%ebx)
	}
	if(perm_store!=NULL)
  801115:	85 f6                	test   %esi,%esi
  801117:	75 17                	jne    801130 <ipc_recv+0x57>
  801119:	eb 25                	jmp    801140 <ipc_recv+0x67>
  80111b:	85 f6                	test   %esi,%esi
  80111d:	74 1d                	je     80113c <ipc_recv+0x63>
	{
		if(r<0)
  80111f:	85 c0                	test   %eax,%eax
  801121:	79 0d                	jns    801130 <ipc_recv+0x57>
			*perm_store=0;
  801123:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		else
			*perm_store=thisenv->env_ipc_perm;
	}
	if(r<0)
		return 0;
  801129:	b8 00 00 00 00       	mov    $0x0,%eax
  80112e:	eb 1f                	jmp    80114f <ipc_recv+0x76>
	if(perm_store!=NULL)
	{
		if(r<0)
			*perm_store=0;
		else
			*perm_store=thisenv->env_ipc_perm;
  801130:	a1 04 20 80 00       	mov    0x802004,%eax
  801135:	8b 40 78             	mov    0x78(%eax),%eax
  801138:	89 06                	mov    %eax,(%esi)
  80113a:	eb 04                	jmp    801140 <ipc_recv+0x67>
	}
	if(r<0)
  80113c:	85 c0                	test   %eax,%eax
  80113e:	78 0a                	js     80114a <ipc_recv+0x71>
		return 0;
	//panic("ipc_recv not implemented");
	return thisenv->env_ipc_value;
  801140:	a1 04 20 80 00       	mov    0x802004,%eax
  801145:	8b 40 70             	mov    0x70(%eax),%eax
  801148:	eb 05                	jmp    80114f <ipc_recv+0x76>
			*perm_store=0;
		else
			*perm_store=thisenv->env_ipc_perm;
	}
	if(r<0)
		return 0;
  80114a:	b8 00 00 00 00       	mov    $0x0,%eax
	//panic("ipc_recv not implemented");
	return thisenv->env_ipc_value;
}
  80114f:	8d 65 f8             	lea    -0x8(%ebp),%esp
  801152:	5b                   	pop    %ebx
  801153:	5e                   	pop    %esi
  801154:	5d                   	pop    %ebp
  801155:	c3                   	ret    

00801156 <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  801156:	55                   	push   %ebp
  801157:	89 e5                	mov    %esp,%ebp
  801159:	57                   	push   %edi
  80115a:	56                   	push   %esi
  80115b:	53                   	push   %ebx
  80115c:	83 ec 0c             	sub    $0xc,%esp
  80115f:	8b 7d 08             	mov    0x8(%ebp),%edi
  801162:	8b 75 0c             	mov    0xc(%ebp),%esi
	// LAB 4: Your code here.
	while(1)
	{
		int r=sys_ipc_try_send(to_env,val,pg,perm);
  801165:	ff 75 14             	pushl  0x14(%ebp)
  801168:	ff 75 10             	pushl  0x10(%ebp)
  80116b:	56                   	push   %esi
  80116c:	57                   	push   %edi
  80116d:	e8 03 fc ff ff       	call   800d75 <sys_ipc_try_send>
  801172:	89 c3                	mov    %eax,%ebx
		if(r<0&&r!= -E_IPC_NOT_RECV)
  801174:	c1 e8 1f             	shr    $0x1f,%eax
  801177:	83 c4 10             	add    $0x10,%esp
  80117a:	84 c0                	test   %al,%al
  80117c:	74 17                	je     801195 <ipc_send+0x3f>
  80117e:	83 fb f9             	cmp    $0xfffffff9,%ebx
  801181:	74 12                	je     801195 <ipc_send+0x3f>
			panic("ipc_send:%e\n",r);
  801183:	53                   	push   %ebx
  801184:	68 04 19 80 00       	push   $0x801904
  801189:	6a 40                	push   $0x40
  80118b:	68 11 19 80 00       	push   $0x801911
  801190:	e8 b5 ef ff ff       	call   80014a <_panic>
		sys_yield();
  801195:	e8 71 fa ff ff       	call   800c0b <sys_yield>
		if(r==0)
  80119a:	85 db                	test   %ebx,%ebx
  80119c:	75 c7                	jne    801165 <ipc_send+0xf>
			break;
	}
	//panic("ipc_send not implemented");
}
  80119e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8011a1:	5b                   	pop    %ebx
  8011a2:	5e                   	pop    %esi
  8011a3:	5f                   	pop    %edi
  8011a4:	5d                   	pop    %ebp
  8011a5:	c3                   	ret    

008011a6 <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  8011a6:	55                   	push   %ebp
  8011a7:	89 e5                	mov    %esp,%ebp
  8011a9:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  8011ac:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  8011b1:	6b d0 7c             	imul   $0x7c,%eax,%edx
  8011b4:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  8011ba:	8b 52 50             	mov    0x50(%edx),%edx
  8011bd:	39 ca                	cmp    %ecx,%edx
  8011bf:	75 0d                	jne    8011ce <ipc_find_env+0x28>
			return envs[i].env_id;
  8011c1:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8011c4:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8011c9:	8b 40 48             	mov    0x48(%eax),%eax
  8011cc:	eb 0f                	jmp    8011dd <ipc_find_env+0x37>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  8011ce:	83 c0 01             	add    $0x1,%eax
  8011d1:	3d 00 04 00 00       	cmp    $0x400,%eax
  8011d6:	75 d9                	jne    8011b1 <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  8011d8:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8011dd:	5d                   	pop    %ebp
  8011de:	c3                   	ret    

008011df <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  8011df:	55                   	push   %ebp
  8011e0:	89 e5                	mov    %esp,%ebp
  8011e2:	83 ec 08             	sub    $0x8,%esp
	int r;
	if (_pgfault_handler == 0) {
  8011e5:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  8011ec:	75 3e                	jne    80122c <set_pgfault_handler+0x4d>
		// First time through!
		// LAB 4: Your code here.
		if((r=sys_page_alloc(0, (void *)(UXSTACKTOP-PGSIZE), PTE_W|PTE_U|PTE_P))<0)
  8011ee:	83 ec 04             	sub    $0x4,%esp
  8011f1:	6a 07                	push   $0x7
  8011f3:	68 00 f0 bf ee       	push   $0xeebff000
  8011f8:	6a 00                	push   $0x0
  8011fa:	e8 2b fa ff ff       	call   800c2a <sys_page_alloc>
  8011ff:	83 c4 10             	add    $0x10,%esp
  801202:	85 c0                	test   %eax,%eax
  801204:	79 14                	jns    80121a <set_pgfault_handler+0x3b>
			panic("set_pgfault_handler not implemented");
  801206:	83 ec 04             	sub    $0x4,%esp
  801209:	68 1c 19 80 00       	push   $0x80191c
  80120e:	6a 20                	push   $0x20
  801210:	68 40 19 80 00       	push   $0x801940
  801215:	e8 30 ef ff ff       	call   80014a <_panic>
		sys_env_set_pgfault_upcall(0,_pgfault_upcall);
  80121a:	83 ec 08             	sub    $0x8,%esp
  80121d:	68 36 12 80 00       	push   $0x801236
  801222:	6a 00                	push   $0x0
  801224:	e8 0a fb ff ff       	call   800d33 <sys_env_set_pgfault_upcall>
  801229:	83 c4 10             	add    $0x10,%esp
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  80122c:	8b 45 08             	mov    0x8(%ebp),%eax
  80122f:	a3 08 20 80 00       	mov    %eax,0x802008
}
  801234:	c9                   	leave  
  801235:	c3                   	ret    

00801236 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  801236:	54                   	push   %esp
	movl _pgfault_handler, %eax
  801237:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  80123c:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  80123e:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	movl	0x30(%esp),%eax
  801241:	8b 44 24 30          	mov    0x30(%esp),%eax
	subl	$0x4,%eax
  801245:	83 e8 04             	sub    $0x4,%eax
	movl	%eax,0x30(%esp)
  801248:	89 44 24 30          	mov    %eax,0x30(%esp)
	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	movl	0x28(%esp),%ebx
  80124c:	8b 5c 24 28          	mov    0x28(%esp),%ebx
	movl	%ebx,(%eax)
  801250:	89 18                	mov    %ebx,(%eax)
	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $0x8,%esp
  801252:	83 c4 08             	add    $0x8,%esp
	popal
  801255:	61                   	popa   
	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	addl $0x4,%esp
  801256:	83 c4 04             	add    $0x4,%esp
	popfl
  801259:	9d                   	popf   
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	pop %esp
  80125a:	5c                   	pop    %esp
	ret
  80125b:	c3                   	ret    
  80125c:	66 90                	xchg   %ax,%ax
  80125e:	66 90                	xchg   %ax,%ax

00801260 <__udivdi3>:
  801260:	55                   	push   %ebp
  801261:	57                   	push   %edi
  801262:	56                   	push   %esi
  801263:	53                   	push   %ebx
  801264:	83 ec 1c             	sub    $0x1c,%esp
  801267:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  80126b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  80126f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  801273:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801277:	85 f6                	test   %esi,%esi
  801279:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80127d:	89 ca                	mov    %ecx,%edx
  80127f:	89 f8                	mov    %edi,%eax
  801281:	75 3d                	jne    8012c0 <__udivdi3+0x60>
  801283:	39 cf                	cmp    %ecx,%edi
  801285:	0f 87 c5 00 00 00    	ja     801350 <__udivdi3+0xf0>
  80128b:	85 ff                	test   %edi,%edi
  80128d:	89 fd                	mov    %edi,%ebp
  80128f:	75 0b                	jne    80129c <__udivdi3+0x3c>
  801291:	b8 01 00 00 00       	mov    $0x1,%eax
  801296:	31 d2                	xor    %edx,%edx
  801298:	f7 f7                	div    %edi
  80129a:	89 c5                	mov    %eax,%ebp
  80129c:	89 c8                	mov    %ecx,%eax
  80129e:	31 d2                	xor    %edx,%edx
  8012a0:	f7 f5                	div    %ebp
  8012a2:	89 c1                	mov    %eax,%ecx
  8012a4:	89 d8                	mov    %ebx,%eax
  8012a6:	89 cf                	mov    %ecx,%edi
  8012a8:	f7 f5                	div    %ebp
  8012aa:	89 c3                	mov    %eax,%ebx
  8012ac:	89 d8                	mov    %ebx,%eax
  8012ae:	89 fa                	mov    %edi,%edx
  8012b0:	83 c4 1c             	add    $0x1c,%esp
  8012b3:	5b                   	pop    %ebx
  8012b4:	5e                   	pop    %esi
  8012b5:	5f                   	pop    %edi
  8012b6:	5d                   	pop    %ebp
  8012b7:	c3                   	ret    
  8012b8:	90                   	nop
  8012b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8012c0:	39 ce                	cmp    %ecx,%esi
  8012c2:	77 74                	ja     801338 <__udivdi3+0xd8>
  8012c4:	0f bd fe             	bsr    %esi,%edi
  8012c7:	83 f7 1f             	xor    $0x1f,%edi
  8012ca:	0f 84 98 00 00 00    	je     801368 <__udivdi3+0x108>
  8012d0:	bb 20 00 00 00       	mov    $0x20,%ebx
  8012d5:	89 f9                	mov    %edi,%ecx
  8012d7:	89 c5                	mov    %eax,%ebp
  8012d9:	29 fb                	sub    %edi,%ebx
  8012db:	d3 e6                	shl    %cl,%esi
  8012dd:	89 d9                	mov    %ebx,%ecx
  8012df:	d3 ed                	shr    %cl,%ebp
  8012e1:	89 f9                	mov    %edi,%ecx
  8012e3:	d3 e0                	shl    %cl,%eax
  8012e5:	09 ee                	or     %ebp,%esi
  8012e7:	89 d9                	mov    %ebx,%ecx
  8012e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8012ed:	89 d5                	mov    %edx,%ebp
  8012ef:	8b 44 24 08          	mov    0x8(%esp),%eax
  8012f3:	d3 ed                	shr    %cl,%ebp
  8012f5:	89 f9                	mov    %edi,%ecx
  8012f7:	d3 e2                	shl    %cl,%edx
  8012f9:	89 d9                	mov    %ebx,%ecx
  8012fb:	d3 e8                	shr    %cl,%eax
  8012fd:	09 c2                	or     %eax,%edx
  8012ff:	89 d0                	mov    %edx,%eax
  801301:	89 ea                	mov    %ebp,%edx
  801303:	f7 f6                	div    %esi
  801305:	89 d5                	mov    %edx,%ebp
  801307:	89 c3                	mov    %eax,%ebx
  801309:	f7 64 24 0c          	mull   0xc(%esp)
  80130d:	39 d5                	cmp    %edx,%ebp
  80130f:	72 10                	jb     801321 <__udivdi3+0xc1>
  801311:	8b 74 24 08          	mov    0x8(%esp),%esi
  801315:	89 f9                	mov    %edi,%ecx
  801317:	d3 e6                	shl    %cl,%esi
  801319:	39 c6                	cmp    %eax,%esi
  80131b:	73 07                	jae    801324 <__udivdi3+0xc4>
  80131d:	39 d5                	cmp    %edx,%ebp
  80131f:	75 03                	jne    801324 <__udivdi3+0xc4>
  801321:	83 eb 01             	sub    $0x1,%ebx
  801324:	31 ff                	xor    %edi,%edi
  801326:	89 d8                	mov    %ebx,%eax
  801328:	89 fa                	mov    %edi,%edx
  80132a:	83 c4 1c             	add    $0x1c,%esp
  80132d:	5b                   	pop    %ebx
  80132e:	5e                   	pop    %esi
  80132f:	5f                   	pop    %edi
  801330:	5d                   	pop    %ebp
  801331:	c3                   	ret    
  801332:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801338:	31 ff                	xor    %edi,%edi
  80133a:	31 db                	xor    %ebx,%ebx
  80133c:	89 d8                	mov    %ebx,%eax
  80133e:	89 fa                	mov    %edi,%edx
  801340:	83 c4 1c             	add    $0x1c,%esp
  801343:	5b                   	pop    %ebx
  801344:	5e                   	pop    %esi
  801345:	5f                   	pop    %edi
  801346:	5d                   	pop    %ebp
  801347:	c3                   	ret    
  801348:	90                   	nop
  801349:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801350:	89 d8                	mov    %ebx,%eax
  801352:	f7 f7                	div    %edi
  801354:	31 ff                	xor    %edi,%edi
  801356:	89 c3                	mov    %eax,%ebx
  801358:	89 d8                	mov    %ebx,%eax
  80135a:	89 fa                	mov    %edi,%edx
  80135c:	83 c4 1c             	add    $0x1c,%esp
  80135f:	5b                   	pop    %ebx
  801360:	5e                   	pop    %esi
  801361:	5f                   	pop    %edi
  801362:	5d                   	pop    %ebp
  801363:	c3                   	ret    
  801364:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801368:	39 ce                	cmp    %ecx,%esi
  80136a:	72 0c                	jb     801378 <__udivdi3+0x118>
  80136c:	31 db                	xor    %ebx,%ebx
  80136e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  801372:	0f 87 34 ff ff ff    	ja     8012ac <__udivdi3+0x4c>
  801378:	bb 01 00 00 00       	mov    $0x1,%ebx
  80137d:	e9 2a ff ff ff       	jmp    8012ac <__udivdi3+0x4c>
  801382:	66 90                	xchg   %ax,%ax
  801384:	66 90                	xchg   %ax,%ax
  801386:	66 90                	xchg   %ax,%ax
  801388:	66 90                	xchg   %ax,%ax
  80138a:	66 90                	xchg   %ax,%ax
  80138c:	66 90                	xchg   %ax,%ax
  80138e:	66 90                	xchg   %ax,%ax

00801390 <__umoddi3>:
  801390:	55                   	push   %ebp
  801391:	57                   	push   %edi
  801392:	56                   	push   %esi
  801393:	53                   	push   %ebx
  801394:	83 ec 1c             	sub    $0x1c,%esp
  801397:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  80139b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80139f:	8b 74 24 34          	mov    0x34(%esp),%esi
  8013a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  8013a7:	85 d2                	test   %edx,%edx
  8013a9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8013ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8013b1:	89 f3                	mov    %esi,%ebx
  8013b3:	89 3c 24             	mov    %edi,(%esp)
  8013b6:	89 74 24 04          	mov    %esi,0x4(%esp)
  8013ba:	75 1c                	jne    8013d8 <__umoddi3+0x48>
  8013bc:	39 f7                	cmp    %esi,%edi
  8013be:	76 50                	jbe    801410 <__umoddi3+0x80>
  8013c0:	89 c8                	mov    %ecx,%eax
  8013c2:	89 f2                	mov    %esi,%edx
  8013c4:	f7 f7                	div    %edi
  8013c6:	89 d0                	mov    %edx,%eax
  8013c8:	31 d2                	xor    %edx,%edx
  8013ca:	83 c4 1c             	add    $0x1c,%esp
  8013cd:	5b                   	pop    %ebx
  8013ce:	5e                   	pop    %esi
  8013cf:	5f                   	pop    %edi
  8013d0:	5d                   	pop    %ebp
  8013d1:	c3                   	ret    
  8013d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8013d8:	39 f2                	cmp    %esi,%edx
  8013da:	89 d0                	mov    %edx,%eax
  8013dc:	77 52                	ja     801430 <__umoddi3+0xa0>
  8013de:	0f bd ea             	bsr    %edx,%ebp
  8013e1:	83 f5 1f             	xor    $0x1f,%ebp
  8013e4:	75 5a                	jne    801440 <__umoddi3+0xb0>
  8013e6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  8013ea:	0f 82 e0 00 00 00    	jb     8014d0 <__umoddi3+0x140>
  8013f0:	39 0c 24             	cmp    %ecx,(%esp)
  8013f3:	0f 86 d7 00 00 00    	jbe    8014d0 <__umoddi3+0x140>
  8013f9:	8b 44 24 08          	mov    0x8(%esp),%eax
  8013fd:	8b 54 24 04          	mov    0x4(%esp),%edx
  801401:	83 c4 1c             	add    $0x1c,%esp
  801404:	5b                   	pop    %ebx
  801405:	5e                   	pop    %esi
  801406:	5f                   	pop    %edi
  801407:	5d                   	pop    %ebp
  801408:	c3                   	ret    
  801409:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801410:	85 ff                	test   %edi,%edi
  801412:	89 fd                	mov    %edi,%ebp
  801414:	75 0b                	jne    801421 <__umoddi3+0x91>
  801416:	b8 01 00 00 00       	mov    $0x1,%eax
  80141b:	31 d2                	xor    %edx,%edx
  80141d:	f7 f7                	div    %edi
  80141f:	89 c5                	mov    %eax,%ebp
  801421:	89 f0                	mov    %esi,%eax
  801423:	31 d2                	xor    %edx,%edx
  801425:	f7 f5                	div    %ebp
  801427:	89 c8                	mov    %ecx,%eax
  801429:	f7 f5                	div    %ebp
  80142b:	89 d0                	mov    %edx,%eax
  80142d:	eb 99                	jmp    8013c8 <__umoddi3+0x38>
  80142f:	90                   	nop
  801430:	89 c8                	mov    %ecx,%eax
  801432:	89 f2                	mov    %esi,%edx
  801434:	83 c4 1c             	add    $0x1c,%esp
  801437:	5b                   	pop    %ebx
  801438:	5e                   	pop    %esi
  801439:	5f                   	pop    %edi
  80143a:	5d                   	pop    %ebp
  80143b:	c3                   	ret    
  80143c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801440:	8b 34 24             	mov    (%esp),%esi
  801443:	bf 20 00 00 00       	mov    $0x20,%edi
  801448:	89 e9                	mov    %ebp,%ecx
  80144a:	29 ef                	sub    %ebp,%edi
  80144c:	d3 e0                	shl    %cl,%eax
  80144e:	89 f9                	mov    %edi,%ecx
  801450:	89 f2                	mov    %esi,%edx
  801452:	d3 ea                	shr    %cl,%edx
  801454:	89 e9                	mov    %ebp,%ecx
  801456:	09 c2                	or     %eax,%edx
  801458:	89 d8                	mov    %ebx,%eax
  80145a:	89 14 24             	mov    %edx,(%esp)
  80145d:	89 f2                	mov    %esi,%edx
  80145f:	d3 e2                	shl    %cl,%edx
  801461:	89 f9                	mov    %edi,%ecx
  801463:	89 54 24 04          	mov    %edx,0x4(%esp)
  801467:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80146b:	d3 e8                	shr    %cl,%eax
  80146d:	89 e9                	mov    %ebp,%ecx
  80146f:	89 c6                	mov    %eax,%esi
  801471:	d3 e3                	shl    %cl,%ebx
  801473:	89 f9                	mov    %edi,%ecx
  801475:	89 d0                	mov    %edx,%eax
  801477:	d3 e8                	shr    %cl,%eax
  801479:	89 e9                	mov    %ebp,%ecx
  80147b:	09 d8                	or     %ebx,%eax
  80147d:	89 d3                	mov    %edx,%ebx
  80147f:	89 f2                	mov    %esi,%edx
  801481:	f7 34 24             	divl   (%esp)
  801484:	89 d6                	mov    %edx,%esi
  801486:	d3 e3                	shl    %cl,%ebx
  801488:	f7 64 24 04          	mull   0x4(%esp)
  80148c:	39 d6                	cmp    %edx,%esi
  80148e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801492:	89 d1                	mov    %edx,%ecx
  801494:	89 c3                	mov    %eax,%ebx
  801496:	72 08                	jb     8014a0 <__umoddi3+0x110>
  801498:	75 11                	jne    8014ab <__umoddi3+0x11b>
  80149a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80149e:	73 0b                	jae    8014ab <__umoddi3+0x11b>
  8014a0:	2b 44 24 04          	sub    0x4(%esp),%eax
  8014a4:	1b 14 24             	sbb    (%esp),%edx
  8014a7:	89 d1                	mov    %edx,%ecx
  8014a9:	89 c3                	mov    %eax,%ebx
  8014ab:	8b 54 24 08          	mov    0x8(%esp),%edx
  8014af:	29 da                	sub    %ebx,%edx
  8014b1:	19 ce                	sbb    %ecx,%esi
  8014b3:	89 f9                	mov    %edi,%ecx
  8014b5:	89 f0                	mov    %esi,%eax
  8014b7:	d3 e0                	shl    %cl,%eax
  8014b9:	89 e9                	mov    %ebp,%ecx
  8014bb:	d3 ea                	shr    %cl,%edx
  8014bd:	89 e9                	mov    %ebp,%ecx
  8014bf:	d3 ee                	shr    %cl,%esi
  8014c1:	09 d0                	or     %edx,%eax
  8014c3:	89 f2                	mov    %esi,%edx
  8014c5:	83 c4 1c             	add    $0x1c,%esp
  8014c8:	5b                   	pop    %ebx
  8014c9:	5e                   	pop    %esi
  8014ca:	5f                   	pop    %edi
  8014cb:	5d                   	pop    %ebp
  8014cc:	c3                   	ret    
  8014cd:	8d 76 00             	lea    0x0(%esi),%esi
  8014d0:	29 f9                	sub    %edi,%ecx
  8014d2:	19 d6                	sbb    %edx,%esi
  8014d4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8014d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8014dc:	e9 18 ff ff ff       	jmp    8013f9 <__umoddi3+0x69>
