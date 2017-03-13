
obj/user/buggyhello:     file format elf32-i386


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
  80002c:	e8 16 00 00 00       	call   800047 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_cputs((char*)1, 1);
  800039:	6a 01                	push   $0x1
  80003b:	6a 01                	push   $0x1
  80003d:	e8 4d 00 00 00       	call   80008f <sys_cputs>
}
  800042:	83 c4 10             	add    $0x10,%esp
  800045:	c9                   	leave  
  800046:	c3                   	ret    

00800047 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800047:	55                   	push   %ebp
  800048:	89 e5                	mov    %esp,%ebp
  80004a:	83 ec 08             	sub    $0x8,%esp
  80004d:	8b 45 08             	mov    0x8(%ebp),%eax
  800050:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800053:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80005a:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80005d:	85 c0                	test   %eax,%eax
  80005f:	7e 08                	jle    800069 <libmain+0x22>
		binaryname = argv[0];
  800061:	8b 0a                	mov    (%edx),%ecx
  800063:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800069:	83 ec 08             	sub    $0x8,%esp
  80006c:	52                   	push   %edx
  80006d:	50                   	push   %eax
  80006e:	e8 c0 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800073:	e8 05 00 00 00       	call   80007d <exit>
}
  800078:	83 c4 10             	add    $0x10,%esp
  80007b:	c9                   	leave  
  80007c:	c3                   	ret    

0080007d <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80007d:	55                   	push   %ebp
  80007e:	89 e5                	mov    %esp,%ebp
  800080:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800083:	6a 00                	push   $0x0
  800085:	e8 42 00 00 00       	call   8000cc <sys_env_destroy>
}
  80008a:	83 c4 10             	add    $0x10,%esp
  80008d:	c9                   	leave  
  80008e:	c3                   	ret    

0080008f <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  80008f:	55                   	push   %ebp
  800090:	89 e5                	mov    %esp,%ebp
  800092:	57                   	push   %edi
  800093:	56                   	push   %esi
  800094:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800095:	b8 00 00 00 00       	mov    $0x0,%eax
  80009a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80009d:	8b 55 08             	mov    0x8(%ebp),%edx
  8000a0:	89 c3                	mov    %eax,%ebx
  8000a2:	89 c7                	mov    %eax,%edi
  8000a4:	89 c6                	mov    %eax,%esi
  8000a6:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000a8:	5b                   	pop    %ebx
  8000a9:	5e                   	pop    %esi
  8000aa:	5f                   	pop    %edi
  8000ab:	5d                   	pop    %ebp
  8000ac:	c3                   	ret    

008000ad <sys_cgetc>:

int
sys_cgetc(void)
{
  8000ad:	55                   	push   %ebp
  8000ae:	89 e5                	mov    %esp,%ebp
  8000b0:	57                   	push   %edi
  8000b1:	56                   	push   %esi
  8000b2:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b3:	ba 00 00 00 00       	mov    $0x0,%edx
  8000b8:	b8 01 00 00 00       	mov    $0x1,%eax
  8000bd:	89 d1                	mov    %edx,%ecx
  8000bf:	89 d3                	mov    %edx,%ebx
  8000c1:	89 d7                	mov    %edx,%edi
  8000c3:	89 d6                	mov    %edx,%esi
  8000c5:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000c7:	5b                   	pop    %ebx
  8000c8:	5e                   	pop    %esi
  8000c9:	5f                   	pop    %edi
  8000ca:	5d                   	pop    %ebp
  8000cb:	c3                   	ret    

008000cc <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000cc:	55                   	push   %ebp
  8000cd:	89 e5                	mov    %esp,%ebp
  8000cf:	57                   	push   %edi
  8000d0:	56                   	push   %esi
  8000d1:	53                   	push   %ebx
  8000d2:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d5:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000da:	b8 03 00 00 00       	mov    $0x3,%eax
  8000df:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e2:	89 cb                	mov    %ecx,%ebx
  8000e4:	89 cf                	mov    %ecx,%edi
  8000e6:	89 ce                	mov    %ecx,%esi
  8000e8:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000ea:	85 c0                	test   %eax,%eax
  8000ec:	7e 17                	jle    800105 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000ee:	83 ec 0c             	sub    $0xc,%esp
  8000f1:	50                   	push   %eax
  8000f2:	6a 03                	push   $0x3
  8000f4:	68 de 0d 80 00       	push   $0x800dde
  8000f9:	6a 23                	push   $0x23
  8000fb:	68 fb 0d 80 00       	push   $0x800dfb
  800100:	e8 27 00 00 00       	call   80012c <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800105:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800108:	5b                   	pop    %ebx
  800109:	5e                   	pop    %esi
  80010a:	5f                   	pop    %edi
  80010b:	5d                   	pop    %ebp
  80010c:	c3                   	ret    

0080010d <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80010d:	55                   	push   %ebp
  80010e:	89 e5                	mov    %esp,%ebp
  800110:	57                   	push   %edi
  800111:	56                   	push   %esi
  800112:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800113:	ba 00 00 00 00       	mov    $0x0,%edx
  800118:	b8 02 00 00 00       	mov    $0x2,%eax
  80011d:	89 d1                	mov    %edx,%ecx
  80011f:	89 d3                	mov    %edx,%ebx
  800121:	89 d7                	mov    %edx,%edi
  800123:	89 d6                	mov    %edx,%esi
  800125:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800127:	5b                   	pop    %ebx
  800128:	5e                   	pop    %esi
  800129:	5f                   	pop    %edi
  80012a:	5d                   	pop    %ebp
  80012b:	c3                   	ret    

0080012c <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80012c:	55                   	push   %ebp
  80012d:	89 e5                	mov    %esp,%ebp
  80012f:	56                   	push   %esi
  800130:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800131:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800134:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80013a:	e8 ce ff ff ff       	call   80010d <sys_getenvid>
  80013f:	83 ec 0c             	sub    $0xc,%esp
  800142:	ff 75 0c             	pushl  0xc(%ebp)
  800145:	ff 75 08             	pushl  0x8(%ebp)
  800148:	56                   	push   %esi
  800149:	50                   	push   %eax
  80014a:	68 0c 0e 80 00       	push   $0x800e0c
  80014f:	e8 b1 00 00 00       	call   800205 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800154:	83 c4 18             	add    $0x18,%esp
  800157:	53                   	push   %ebx
  800158:	ff 75 10             	pushl  0x10(%ebp)
  80015b:	e8 54 00 00 00       	call   8001b4 <vcprintf>
	cprintf("\n");
  800160:	c7 04 24 30 0e 80 00 	movl   $0x800e30,(%esp)
  800167:	e8 99 00 00 00       	call   800205 <cprintf>
  80016c:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80016f:	cc                   	int3   
  800170:	eb fd                	jmp    80016f <_panic+0x43>

00800172 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800172:	55                   	push   %ebp
  800173:	89 e5                	mov    %esp,%ebp
  800175:	53                   	push   %ebx
  800176:	83 ec 04             	sub    $0x4,%esp
  800179:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80017c:	8b 13                	mov    (%ebx),%edx
  80017e:	8d 42 01             	lea    0x1(%edx),%eax
  800181:	89 03                	mov    %eax,(%ebx)
  800183:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800186:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80018a:	3d ff 00 00 00       	cmp    $0xff,%eax
  80018f:	75 1a                	jne    8001ab <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800191:	83 ec 08             	sub    $0x8,%esp
  800194:	68 ff 00 00 00       	push   $0xff
  800199:	8d 43 08             	lea    0x8(%ebx),%eax
  80019c:	50                   	push   %eax
  80019d:	e8 ed fe ff ff       	call   80008f <sys_cputs>
		b->idx = 0;
  8001a2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001a8:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001ab:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001af:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001b2:	c9                   	leave  
  8001b3:	c3                   	ret    

008001b4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001b4:	55                   	push   %ebp
  8001b5:	89 e5                	mov    %esp,%ebp
  8001b7:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001bd:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001c4:	00 00 00 
	b.cnt = 0;
  8001c7:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001ce:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001d1:	ff 75 0c             	pushl  0xc(%ebp)
  8001d4:	ff 75 08             	pushl  0x8(%ebp)
  8001d7:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001dd:	50                   	push   %eax
  8001de:	68 72 01 80 00       	push   $0x800172
  8001e3:	e8 1a 01 00 00       	call   800302 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001e8:	83 c4 08             	add    $0x8,%esp
  8001eb:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001f1:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001f7:	50                   	push   %eax
  8001f8:	e8 92 fe ff ff       	call   80008f <sys_cputs>

	return b.cnt;
}
  8001fd:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800203:	c9                   	leave  
  800204:	c3                   	ret    

00800205 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800205:	55                   	push   %ebp
  800206:	89 e5                	mov    %esp,%ebp
  800208:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80020b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80020e:	50                   	push   %eax
  80020f:	ff 75 08             	pushl  0x8(%ebp)
  800212:	e8 9d ff ff ff       	call   8001b4 <vcprintf>
	va_end(ap);

	return cnt;
}
  800217:	c9                   	leave  
  800218:	c3                   	ret    

00800219 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800219:	55                   	push   %ebp
  80021a:	89 e5                	mov    %esp,%ebp
  80021c:	57                   	push   %edi
  80021d:	56                   	push   %esi
  80021e:	53                   	push   %ebx
  80021f:	83 ec 1c             	sub    $0x1c,%esp
  800222:	89 c7                	mov    %eax,%edi
  800224:	89 d6                	mov    %edx,%esi
  800226:	8b 45 08             	mov    0x8(%ebp),%eax
  800229:	8b 55 0c             	mov    0xc(%ebp),%edx
  80022c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80022f:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800232:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800235:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80023d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800240:	39 d3                	cmp    %edx,%ebx
  800242:	72 05                	jb     800249 <printnum+0x30>
  800244:	39 45 10             	cmp    %eax,0x10(%ebp)
  800247:	77 45                	ja     80028e <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800249:	83 ec 0c             	sub    $0xc,%esp
  80024c:	ff 75 18             	pushl  0x18(%ebp)
  80024f:	8b 45 14             	mov    0x14(%ebp),%eax
  800252:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800255:	53                   	push   %ebx
  800256:	ff 75 10             	pushl  0x10(%ebp)
  800259:	83 ec 08             	sub    $0x8,%esp
  80025c:	ff 75 e4             	pushl  -0x1c(%ebp)
  80025f:	ff 75 e0             	pushl  -0x20(%ebp)
  800262:	ff 75 dc             	pushl  -0x24(%ebp)
  800265:	ff 75 d8             	pushl  -0x28(%ebp)
  800268:	e8 e3 08 00 00       	call   800b50 <__udivdi3>
  80026d:	83 c4 18             	add    $0x18,%esp
  800270:	52                   	push   %edx
  800271:	50                   	push   %eax
  800272:	89 f2                	mov    %esi,%edx
  800274:	89 f8                	mov    %edi,%eax
  800276:	e8 9e ff ff ff       	call   800219 <printnum>
  80027b:	83 c4 20             	add    $0x20,%esp
  80027e:	eb 18                	jmp    800298 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800280:	83 ec 08             	sub    $0x8,%esp
  800283:	56                   	push   %esi
  800284:	ff 75 18             	pushl  0x18(%ebp)
  800287:	ff d7                	call   *%edi
  800289:	83 c4 10             	add    $0x10,%esp
  80028c:	eb 03                	jmp    800291 <printnum+0x78>
  80028e:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800291:	83 eb 01             	sub    $0x1,%ebx
  800294:	85 db                	test   %ebx,%ebx
  800296:	7f e8                	jg     800280 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800298:	83 ec 08             	sub    $0x8,%esp
  80029b:	56                   	push   %esi
  80029c:	83 ec 04             	sub    $0x4,%esp
  80029f:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002a2:	ff 75 e0             	pushl  -0x20(%ebp)
  8002a5:	ff 75 dc             	pushl  -0x24(%ebp)
  8002a8:	ff 75 d8             	pushl  -0x28(%ebp)
  8002ab:	e8 d0 09 00 00       	call   800c80 <__umoddi3>
  8002b0:	83 c4 14             	add    $0x14,%esp
  8002b3:	0f be 80 32 0e 80 00 	movsbl 0x800e32(%eax),%eax
  8002ba:	50                   	push   %eax
  8002bb:	ff d7                	call   *%edi
}
  8002bd:	83 c4 10             	add    $0x10,%esp
  8002c0:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002c3:	5b                   	pop    %ebx
  8002c4:	5e                   	pop    %esi
  8002c5:	5f                   	pop    %edi
  8002c6:	5d                   	pop    %ebp
  8002c7:	c3                   	ret    

008002c8 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002c8:	55                   	push   %ebp
  8002c9:	89 e5                	mov    %esp,%ebp
  8002cb:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002ce:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002d2:	8b 10                	mov    (%eax),%edx
  8002d4:	3b 50 04             	cmp    0x4(%eax),%edx
  8002d7:	73 0a                	jae    8002e3 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002d9:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002dc:	89 08                	mov    %ecx,(%eax)
  8002de:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e1:	88 02                	mov    %al,(%edx)
}
  8002e3:	5d                   	pop    %ebp
  8002e4:	c3                   	ret    

008002e5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002e5:	55                   	push   %ebp
  8002e6:	89 e5                	mov    %esp,%ebp
  8002e8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002eb:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002ee:	50                   	push   %eax
  8002ef:	ff 75 10             	pushl  0x10(%ebp)
  8002f2:	ff 75 0c             	pushl  0xc(%ebp)
  8002f5:	ff 75 08             	pushl  0x8(%ebp)
  8002f8:	e8 05 00 00 00       	call   800302 <vprintfmt>
	va_end(ap);
}
  8002fd:	83 c4 10             	add    $0x10,%esp
  800300:	c9                   	leave  
  800301:	c3                   	ret    

00800302 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800302:	55                   	push   %ebp
  800303:	89 e5                	mov    %esp,%ebp
  800305:	57                   	push   %edi
  800306:	56                   	push   %esi
  800307:	53                   	push   %ebx
  800308:	83 ec 2c             	sub    $0x2c,%esp
  80030b:	8b 75 08             	mov    0x8(%ebp),%esi
  80030e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800311:	8b 7d 10             	mov    0x10(%ebp),%edi
  800314:	eb 12                	jmp    800328 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800316:	85 c0                	test   %eax,%eax
  800318:	0f 84 42 04 00 00    	je     800760 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  80031e:	83 ec 08             	sub    $0x8,%esp
  800321:	53                   	push   %ebx
  800322:	50                   	push   %eax
  800323:	ff d6                	call   *%esi
  800325:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800328:	83 c7 01             	add    $0x1,%edi
  80032b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80032f:	83 f8 25             	cmp    $0x25,%eax
  800332:	75 e2                	jne    800316 <vprintfmt+0x14>
  800334:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800338:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80033f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800346:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80034d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800352:	eb 07                	jmp    80035b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800354:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800357:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80035b:	8d 47 01             	lea    0x1(%edi),%eax
  80035e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800361:	0f b6 07             	movzbl (%edi),%eax
  800364:	0f b6 d0             	movzbl %al,%edx
  800367:	83 e8 23             	sub    $0x23,%eax
  80036a:	3c 55                	cmp    $0x55,%al
  80036c:	0f 87 d3 03 00 00    	ja     800745 <vprintfmt+0x443>
  800372:	0f b6 c0             	movzbl %al,%eax
  800375:	ff 24 85 c0 0e 80 00 	jmp    *0x800ec0(,%eax,4)
  80037c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80037f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800383:	eb d6                	jmp    80035b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800385:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800388:	b8 00 00 00 00       	mov    $0x0,%eax
  80038d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800390:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800393:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800397:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  80039a:	8d 4a d0             	lea    -0x30(%edx),%ecx
  80039d:	83 f9 09             	cmp    $0x9,%ecx
  8003a0:	77 3f                	ja     8003e1 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003a2:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003a5:	eb e9                	jmp    800390 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003a7:	8b 45 14             	mov    0x14(%ebp),%eax
  8003aa:	8b 00                	mov    (%eax),%eax
  8003ac:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003af:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b2:	8d 40 04             	lea    0x4(%eax),%eax
  8003b5:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003bb:	eb 2a                	jmp    8003e7 <vprintfmt+0xe5>
  8003bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003c0:	85 c0                	test   %eax,%eax
  8003c2:	ba 00 00 00 00       	mov    $0x0,%edx
  8003c7:	0f 49 d0             	cmovns %eax,%edx
  8003ca:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003d0:	eb 89                	jmp    80035b <vprintfmt+0x59>
  8003d2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003d5:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003dc:	e9 7a ff ff ff       	jmp    80035b <vprintfmt+0x59>
  8003e1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003e4:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8003e7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003eb:	0f 89 6a ff ff ff    	jns    80035b <vprintfmt+0x59>
				width = precision, precision = -1;
  8003f1:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003f4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003f7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003fe:	e9 58 ff ff ff       	jmp    80035b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800403:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800406:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800409:	e9 4d ff ff ff       	jmp    80035b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80040e:	8b 45 14             	mov    0x14(%ebp),%eax
  800411:	8d 78 04             	lea    0x4(%eax),%edi
  800414:	83 ec 08             	sub    $0x8,%esp
  800417:	53                   	push   %ebx
  800418:	ff 30                	pushl  (%eax)
  80041a:	ff d6                	call   *%esi
			break;
  80041c:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80041f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800422:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800425:	e9 fe fe ff ff       	jmp    800328 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80042a:	8b 45 14             	mov    0x14(%ebp),%eax
  80042d:	8d 78 04             	lea    0x4(%eax),%edi
  800430:	8b 00                	mov    (%eax),%eax
  800432:	99                   	cltd   
  800433:	31 d0                	xor    %edx,%eax
  800435:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800437:	83 f8 06             	cmp    $0x6,%eax
  80043a:	7f 0b                	jg     800447 <vprintfmt+0x145>
  80043c:	8b 14 85 18 10 80 00 	mov    0x801018(,%eax,4),%edx
  800443:	85 d2                	test   %edx,%edx
  800445:	75 1b                	jne    800462 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800447:	50                   	push   %eax
  800448:	68 4a 0e 80 00       	push   $0x800e4a
  80044d:	53                   	push   %ebx
  80044e:	56                   	push   %esi
  80044f:	e8 91 fe ff ff       	call   8002e5 <printfmt>
  800454:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800457:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80045d:	e9 c6 fe ff ff       	jmp    800328 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800462:	52                   	push   %edx
  800463:	68 53 0e 80 00       	push   $0x800e53
  800468:	53                   	push   %ebx
  800469:	56                   	push   %esi
  80046a:	e8 76 fe ff ff       	call   8002e5 <printfmt>
  80046f:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800472:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800475:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800478:	e9 ab fe ff ff       	jmp    800328 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80047d:	8b 45 14             	mov    0x14(%ebp),%eax
  800480:	83 c0 04             	add    $0x4,%eax
  800483:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800486:	8b 45 14             	mov    0x14(%ebp),%eax
  800489:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80048b:	85 ff                	test   %edi,%edi
  80048d:	b8 43 0e 80 00       	mov    $0x800e43,%eax
  800492:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800495:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800499:	0f 8e 94 00 00 00    	jle    800533 <vprintfmt+0x231>
  80049f:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004a3:	0f 84 98 00 00 00    	je     800541 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004a9:	83 ec 08             	sub    $0x8,%esp
  8004ac:	ff 75 d0             	pushl  -0x30(%ebp)
  8004af:	57                   	push   %edi
  8004b0:	e8 33 03 00 00       	call   8007e8 <strnlen>
  8004b5:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004b8:	29 c1                	sub    %eax,%ecx
  8004ba:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004bd:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004c0:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004c4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004c7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004ca:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004cc:	eb 0f                	jmp    8004dd <vprintfmt+0x1db>
					putch(padc, putdat);
  8004ce:	83 ec 08             	sub    $0x8,%esp
  8004d1:	53                   	push   %ebx
  8004d2:	ff 75 e0             	pushl  -0x20(%ebp)
  8004d5:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d7:	83 ef 01             	sub    $0x1,%edi
  8004da:	83 c4 10             	add    $0x10,%esp
  8004dd:	85 ff                	test   %edi,%edi
  8004df:	7f ed                	jg     8004ce <vprintfmt+0x1cc>
  8004e1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004e4:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004e7:	85 c9                	test   %ecx,%ecx
  8004e9:	b8 00 00 00 00       	mov    $0x0,%eax
  8004ee:	0f 49 c1             	cmovns %ecx,%eax
  8004f1:	29 c1                	sub    %eax,%ecx
  8004f3:	89 75 08             	mov    %esi,0x8(%ebp)
  8004f6:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004f9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004fc:	89 cb                	mov    %ecx,%ebx
  8004fe:	eb 4d                	jmp    80054d <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800500:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800504:	74 1b                	je     800521 <vprintfmt+0x21f>
  800506:	0f be c0             	movsbl %al,%eax
  800509:	83 e8 20             	sub    $0x20,%eax
  80050c:	83 f8 5e             	cmp    $0x5e,%eax
  80050f:	76 10                	jbe    800521 <vprintfmt+0x21f>
					putch('?', putdat);
  800511:	83 ec 08             	sub    $0x8,%esp
  800514:	ff 75 0c             	pushl  0xc(%ebp)
  800517:	6a 3f                	push   $0x3f
  800519:	ff 55 08             	call   *0x8(%ebp)
  80051c:	83 c4 10             	add    $0x10,%esp
  80051f:	eb 0d                	jmp    80052e <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800521:	83 ec 08             	sub    $0x8,%esp
  800524:	ff 75 0c             	pushl  0xc(%ebp)
  800527:	52                   	push   %edx
  800528:	ff 55 08             	call   *0x8(%ebp)
  80052b:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80052e:	83 eb 01             	sub    $0x1,%ebx
  800531:	eb 1a                	jmp    80054d <vprintfmt+0x24b>
  800533:	89 75 08             	mov    %esi,0x8(%ebp)
  800536:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800539:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80053c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80053f:	eb 0c                	jmp    80054d <vprintfmt+0x24b>
  800541:	89 75 08             	mov    %esi,0x8(%ebp)
  800544:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800547:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80054a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80054d:	83 c7 01             	add    $0x1,%edi
  800550:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800554:	0f be d0             	movsbl %al,%edx
  800557:	85 d2                	test   %edx,%edx
  800559:	74 23                	je     80057e <vprintfmt+0x27c>
  80055b:	85 f6                	test   %esi,%esi
  80055d:	78 a1                	js     800500 <vprintfmt+0x1fe>
  80055f:	83 ee 01             	sub    $0x1,%esi
  800562:	79 9c                	jns    800500 <vprintfmt+0x1fe>
  800564:	89 df                	mov    %ebx,%edi
  800566:	8b 75 08             	mov    0x8(%ebp),%esi
  800569:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80056c:	eb 18                	jmp    800586 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80056e:	83 ec 08             	sub    $0x8,%esp
  800571:	53                   	push   %ebx
  800572:	6a 20                	push   $0x20
  800574:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800576:	83 ef 01             	sub    $0x1,%edi
  800579:	83 c4 10             	add    $0x10,%esp
  80057c:	eb 08                	jmp    800586 <vprintfmt+0x284>
  80057e:	89 df                	mov    %ebx,%edi
  800580:	8b 75 08             	mov    0x8(%ebp),%esi
  800583:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800586:	85 ff                	test   %edi,%edi
  800588:	7f e4                	jg     80056e <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80058a:	8b 45 cc             	mov    -0x34(%ebp),%eax
  80058d:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800590:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800593:	e9 90 fd ff ff       	jmp    800328 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800598:	83 f9 01             	cmp    $0x1,%ecx
  80059b:	7e 19                	jle    8005b6 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  80059d:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a0:	8b 50 04             	mov    0x4(%eax),%edx
  8005a3:	8b 00                	mov    (%eax),%eax
  8005a5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005a8:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005ab:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ae:	8d 40 08             	lea    0x8(%eax),%eax
  8005b1:	89 45 14             	mov    %eax,0x14(%ebp)
  8005b4:	eb 38                	jmp    8005ee <vprintfmt+0x2ec>
	else if (lflag)
  8005b6:	85 c9                	test   %ecx,%ecx
  8005b8:	74 1b                	je     8005d5 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005ba:	8b 45 14             	mov    0x14(%ebp),%eax
  8005bd:	8b 00                	mov    (%eax),%eax
  8005bf:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005c2:	89 c1                	mov    %eax,%ecx
  8005c4:	c1 f9 1f             	sar    $0x1f,%ecx
  8005c7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005ca:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cd:	8d 40 04             	lea    0x4(%eax),%eax
  8005d0:	89 45 14             	mov    %eax,0x14(%ebp)
  8005d3:	eb 19                	jmp    8005ee <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d8:	8b 00                	mov    (%eax),%eax
  8005da:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005dd:	89 c1                	mov    %eax,%ecx
  8005df:	c1 f9 1f             	sar    $0x1f,%ecx
  8005e2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e8:	8d 40 04             	lea    0x4(%eax),%eax
  8005eb:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005ee:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005f1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005f4:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005f9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005fd:	0f 89 0e 01 00 00    	jns    800711 <vprintfmt+0x40f>
				putch('-', putdat);
  800603:	83 ec 08             	sub    $0x8,%esp
  800606:	53                   	push   %ebx
  800607:	6a 2d                	push   $0x2d
  800609:	ff d6                	call   *%esi
				num = -(long long) num;
  80060b:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80060e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800611:	f7 da                	neg    %edx
  800613:	83 d1 00             	adc    $0x0,%ecx
  800616:	f7 d9                	neg    %ecx
  800618:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80061b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800620:	e9 ec 00 00 00       	jmp    800711 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800625:	83 f9 01             	cmp    $0x1,%ecx
  800628:	7e 18                	jle    800642 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80062a:	8b 45 14             	mov    0x14(%ebp),%eax
  80062d:	8b 10                	mov    (%eax),%edx
  80062f:	8b 48 04             	mov    0x4(%eax),%ecx
  800632:	8d 40 08             	lea    0x8(%eax),%eax
  800635:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800638:	b8 0a 00 00 00       	mov    $0xa,%eax
  80063d:	e9 cf 00 00 00       	jmp    800711 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800642:	85 c9                	test   %ecx,%ecx
  800644:	74 1a                	je     800660 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800646:	8b 45 14             	mov    0x14(%ebp),%eax
  800649:	8b 10                	mov    (%eax),%edx
  80064b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800650:	8d 40 04             	lea    0x4(%eax),%eax
  800653:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800656:	b8 0a 00 00 00       	mov    $0xa,%eax
  80065b:	e9 b1 00 00 00       	jmp    800711 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800660:	8b 45 14             	mov    0x14(%ebp),%eax
  800663:	8b 10                	mov    (%eax),%edx
  800665:	b9 00 00 00 00       	mov    $0x0,%ecx
  80066a:	8d 40 04             	lea    0x4(%eax),%eax
  80066d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800670:	b8 0a 00 00 00       	mov    $0xa,%eax
  800675:	e9 97 00 00 00       	jmp    800711 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  80067a:	83 ec 08             	sub    $0x8,%esp
  80067d:	53                   	push   %ebx
  80067e:	6a 58                	push   $0x58
  800680:	ff d6                	call   *%esi
			putch('X', putdat);
  800682:	83 c4 08             	add    $0x8,%esp
  800685:	53                   	push   %ebx
  800686:	6a 58                	push   $0x58
  800688:	ff d6                	call   *%esi
			putch('X', putdat);
  80068a:	83 c4 08             	add    $0x8,%esp
  80068d:	53                   	push   %ebx
  80068e:	6a 58                	push   $0x58
  800690:	ff d6                	call   *%esi
			break;
  800692:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800695:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  800698:	e9 8b fc ff ff       	jmp    800328 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  80069d:	83 ec 08             	sub    $0x8,%esp
  8006a0:	53                   	push   %ebx
  8006a1:	6a 30                	push   $0x30
  8006a3:	ff d6                	call   *%esi
			putch('x', putdat);
  8006a5:	83 c4 08             	add    $0x8,%esp
  8006a8:	53                   	push   %ebx
  8006a9:	6a 78                	push   $0x78
  8006ab:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006ad:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b0:	8b 10                	mov    (%eax),%edx
  8006b2:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006b7:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006ba:	8d 40 04             	lea    0x4(%eax),%eax
  8006bd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006c0:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006c5:	eb 4a                	jmp    800711 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006c7:	83 f9 01             	cmp    $0x1,%ecx
  8006ca:	7e 15                	jle    8006e1 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006cc:	8b 45 14             	mov    0x14(%ebp),%eax
  8006cf:	8b 10                	mov    (%eax),%edx
  8006d1:	8b 48 04             	mov    0x4(%eax),%ecx
  8006d4:	8d 40 08             	lea    0x8(%eax),%eax
  8006d7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006da:	b8 10 00 00 00       	mov    $0x10,%eax
  8006df:	eb 30                	jmp    800711 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006e1:	85 c9                	test   %ecx,%ecx
  8006e3:	74 17                	je     8006fc <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8006e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e8:	8b 10                	mov    (%eax),%edx
  8006ea:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006ef:	8d 40 04             	lea    0x4(%eax),%eax
  8006f2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006f5:	b8 10 00 00 00       	mov    $0x10,%eax
  8006fa:	eb 15                	jmp    800711 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8006fc:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ff:	8b 10                	mov    (%eax),%edx
  800701:	b9 00 00 00 00       	mov    $0x0,%ecx
  800706:	8d 40 04             	lea    0x4(%eax),%eax
  800709:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80070c:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800711:	83 ec 0c             	sub    $0xc,%esp
  800714:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800718:	57                   	push   %edi
  800719:	ff 75 e0             	pushl  -0x20(%ebp)
  80071c:	50                   	push   %eax
  80071d:	51                   	push   %ecx
  80071e:	52                   	push   %edx
  80071f:	89 da                	mov    %ebx,%edx
  800721:	89 f0                	mov    %esi,%eax
  800723:	e8 f1 fa ff ff       	call   800219 <printnum>
			break;
  800728:	83 c4 20             	add    $0x20,%esp
  80072b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80072e:	e9 f5 fb ff ff       	jmp    800328 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800733:	83 ec 08             	sub    $0x8,%esp
  800736:	53                   	push   %ebx
  800737:	52                   	push   %edx
  800738:	ff d6                	call   *%esi
			break;
  80073a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80073d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800740:	e9 e3 fb ff ff       	jmp    800328 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800745:	83 ec 08             	sub    $0x8,%esp
  800748:	53                   	push   %ebx
  800749:	6a 25                	push   $0x25
  80074b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80074d:	83 c4 10             	add    $0x10,%esp
  800750:	eb 03                	jmp    800755 <vprintfmt+0x453>
  800752:	83 ef 01             	sub    $0x1,%edi
  800755:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800759:	75 f7                	jne    800752 <vprintfmt+0x450>
  80075b:	e9 c8 fb ff ff       	jmp    800328 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800760:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800763:	5b                   	pop    %ebx
  800764:	5e                   	pop    %esi
  800765:	5f                   	pop    %edi
  800766:	5d                   	pop    %ebp
  800767:	c3                   	ret    

00800768 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800768:	55                   	push   %ebp
  800769:	89 e5                	mov    %esp,%ebp
  80076b:	83 ec 18             	sub    $0x18,%esp
  80076e:	8b 45 08             	mov    0x8(%ebp),%eax
  800771:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800774:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800777:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80077b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80077e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800785:	85 c0                	test   %eax,%eax
  800787:	74 26                	je     8007af <vsnprintf+0x47>
  800789:	85 d2                	test   %edx,%edx
  80078b:	7e 22                	jle    8007af <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80078d:	ff 75 14             	pushl  0x14(%ebp)
  800790:	ff 75 10             	pushl  0x10(%ebp)
  800793:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800796:	50                   	push   %eax
  800797:	68 c8 02 80 00       	push   $0x8002c8
  80079c:	e8 61 fb ff ff       	call   800302 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007a4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007aa:	83 c4 10             	add    $0x10,%esp
  8007ad:	eb 05                	jmp    8007b4 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007af:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007b4:	c9                   	leave  
  8007b5:	c3                   	ret    

008007b6 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007b6:	55                   	push   %ebp
  8007b7:	89 e5                	mov    %esp,%ebp
  8007b9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007bc:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007bf:	50                   	push   %eax
  8007c0:	ff 75 10             	pushl  0x10(%ebp)
  8007c3:	ff 75 0c             	pushl  0xc(%ebp)
  8007c6:	ff 75 08             	pushl  0x8(%ebp)
  8007c9:	e8 9a ff ff ff       	call   800768 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007ce:	c9                   	leave  
  8007cf:	c3                   	ret    

008007d0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007d0:	55                   	push   %ebp
  8007d1:	89 e5                	mov    %esp,%ebp
  8007d3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007d6:	b8 00 00 00 00       	mov    $0x0,%eax
  8007db:	eb 03                	jmp    8007e0 <strlen+0x10>
		n++;
  8007dd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007e0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007e4:	75 f7                	jne    8007dd <strlen+0xd>
		n++;
	return n;
}
  8007e6:	5d                   	pop    %ebp
  8007e7:	c3                   	ret    

008007e8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007e8:	55                   	push   %ebp
  8007e9:	89 e5                	mov    %esp,%ebp
  8007eb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007ee:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007f1:	ba 00 00 00 00       	mov    $0x0,%edx
  8007f6:	eb 03                	jmp    8007fb <strnlen+0x13>
		n++;
  8007f8:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007fb:	39 c2                	cmp    %eax,%edx
  8007fd:	74 08                	je     800807 <strnlen+0x1f>
  8007ff:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800803:	75 f3                	jne    8007f8 <strnlen+0x10>
  800805:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800807:	5d                   	pop    %ebp
  800808:	c3                   	ret    

00800809 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800809:	55                   	push   %ebp
  80080a:	89 e5                	mov    %esp,%ebp
  80080c:	53                   	push   %ebx
  80080d:	8b 45 08             	mov    0x8(%ebp),%eax
  800810:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800813:	89 c2                	mov    %eax,%edx
  800815:	83 c2 01             	add    $0x1,%edx
  800818:	83 c1 01             	add    $0x1,%ecx
  80081b:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80081f:	88 5a ff             	mov    %bl,-0x1(%edx)
  800822:	84 db                	test   %bl,%bl
  800824:	75 ef                	jne    800815 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800826:	5b                   	pop    %ebx
  800827:	5d                   	pop    %ebp
  800828:	c3                   	ret    

00800829 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800829:	55                   	push   %ebp
  80082a:	89 e5                	mov    %esp,%ebp
  80082c:	53                   	push   %ebx
  80082d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800830:	53                   	push   %ebx
  800831:	e8 9a ff ff ff       	call   8007d0 <strlen>
  800836:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800839:	ff 75 0c             	pushl  0xc(%ebp)
  80083c:	01 d8                	add    %ebx,%eax
  80083e:	50                   	push   %eax
  80083f:	e8 c5 ff ff ff       	call   800809 <strcpy>
	return dst;
}
  800844:	89 d8                	mov    %ebx,%eax
  800846:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800849:	c9                   	leave  
  80084a:	c3                   	ret    

0080084b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80084b:	55                   	push   %ebp
  80084c:	89 e5                	mov    %esp,%ebp
  80084e:	56                   	push   %esi
  80084f:	53                   	push   %ebx
  800850:	8b 75 08             	mov    0x8(%ebp),%esi
  800853:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800856:	89 f3                	mov    %esi,%ebx
  800858:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80085b:	89 f2                	mov    %esi,%edx
  80085d:	eb 0f                	jmp    80086e <strncpy+0x23>
		*dst++ = *src;
  80085f:	83 c2 01             	add    $0x1,%edx
  800862:	0f b6 01             	movzbl (%ecx),%eax
  800865:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800868:	80 39 01             	cmpb   $0x1,(%ecx)
  80086b:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80086e:	39 da                	cmp    %ebx,%edx
  800870:	75 ed                	jne    80085f <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800872:	89 f0                	mov    %esi,%eax
  800874:	5b                   	pop    %ebx
  800875:	5e                   	pop    %esi
  800876:	5d                   	pop    %ebp
  800877:	c3                   	ret    

00800878 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800878:	55                   	push   %ebp
  800879:	89 e5                	mov    %esp,%ebp
  80087b:	56                   	push   %esi
  80087c:	53                   	push   %ebx
  80087d:	8b 75 08             	mov    0x8(%ebp),%esi
  800880:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800883:	8b 55 10             	mov    0x10(%ebp),%edx
  800886:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800888:	85 d2                	test   %edx,%edx
  80088a:	74 21                	je     8008ad <strlcpy+0x35>
  80088c:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800890:	89 f2                	mov    %esi,%edx
  800892:	eb 09                	jmp    80089d <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800894:	83 c2 01             	add    $0x1,%edx
  800897:	83 c1 01             	add    $0x1,%ecx
  80089a:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80089d:	39 c2                	cmp    %eax,%edx
  80089f:	74 09                	je     8008aa <strlcpy+0x32>
  8008a1:	0f b6 19             	movzbl (%ecx),%ebx
  8008a4:	84 db                	test   %bl,%bl
  8008a6:	75 ec                	jne    800894 <strlcpy+0x1c>
  8008a8:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008aa:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008ad:	29 f0                	sub    %esi,%eax
}
  8008af:	5b                   	pop    %ebx
  8008b0:	5e                   	pop    %esi
  8008b1:	5d                   	pop    %ebp
  8008b2:	c3                   	ret    

008008b3 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008b3:	55                   	push   %ebp
  8008b4:	89 e5                	mov    %esp,%ebp
  8008b6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008b9:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008bc:	eb 06                	jmp    8008c4 <strcmp+0x11>
		p++, q++;
  8008be:	83 c1 01             	add    $0x1,%ecx
  8008c1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008c4:	0f b6 01             	movzbl (%ecx),%eax
  8008c7:	84 c0                	test   %al,%al
  8008c9:	74 04                	je     8008cf <strcmp+0x1c>
  8008cb:	3a 02                	cmp    (%edx),%al
  8008cd:	74 ef                	je     8008be <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008cf:	0f b6 c0             	movzbl %al,%eax
  8008d2:	0f b6 12             	movzbl (%edx),%edx
  8008d5:	29 d0                	sub    %edx,%eax
}
  8008d7:	5d                   	pop    %ebp
  8008d8:	c3                   	ret    

008008d9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008d9:	55                   	push   %ebp
  8008da:	89 e5                	mov    %esp,%ebp
  8008dc:	53                   	push   %ebx
  8008dd:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e0:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008e3:	89 c3                	mov    %eax,%ebx
  8008e5:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008e8:	eb 06                	jmp    8008f0 <strncmp+0x17>
		n--, p++, q++;
  8008ea:	83 c0 01             	add    $0x1,%eax
  8008ed:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008f0:	39 d8                	cmp    %ebx,%eax
  8008f2:	74 15                	je     800909 <strncmp+0x30>
  8008f4:	0f b6 08             	movzbl (%eax),%ecx
  8008f7:	84 c9                	test   %cl,%cl
  8008f9:	74 04                	je     8008ff <strncmp+0x26>
  8008fb:	3a 0a                	cmp    (%edx),%cl
  8008fd:	74 eb                	je     8008ea <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ff:	0f b6 00             	movzbl (%eax),%eax
  800902:	0f b6 12             	movzbl (%edx),%edx
  800905:	29 d0                	sub    %edx,%eax
  800907:	eb 05                	jmp    80090e <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800909:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80090e:	5b                   	pop    %ebx
  80090f:	5d                   	pop    %ebp
  800910:	c3                   	ret    

00800911 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800911:	55                   	push   %ebp
  800912:	89 e5                	mov    %esp,%ebp
  800914:	8b 45 08             	mov    0x8(%ebp),%eax
  800917:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80091b:	eb 07                	jmp    800924 <strchr+0x13>
		if (*s == c)
  80091d:	38 ca                	cmp    %cl,%dl
  80091f:	74 0f                	je     800930 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800921:	83 c0 01             	add    $0x1,%eax
  800924:	0f b6 10             	movzbl (%eax),%edx
  800927:	84 d2                	test   %dl,%dl
  800929:	75 f2                	jne    80091d <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80092b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800930:	5d                   	pop    %ebp
  800931:	c3                   	ret    

00800932 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800932:	55                   	push   %ebp
  800933:	89 e5                	mov    %esp,%ebp
  800935:	8b 45 08             	mov    0x8(%ebp),%eax
  800938:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80093c:	eb 03                	jmp    800941 <strfind+0xf>
  80093e:	83 c0 01             	add    $0x1,%eax
  800941:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800944:	38 ca                	cmp    %cl,%dl
  800946:	74 04                	je     80094c <strfind+0x1a>
  800948:	84 d2                	test   %dl,%dl
  80094a:	75 f2                	jne    80093e <strfind+0xc>
			break;
	return (char *) s;
}
  80094c:	5d                   	pop    %ebp
  80094d:	c3                   	ret    

0080094e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80094e:	55                   	push   %ebp
  80094f:	89 e5                	mov    %esp,%ebp
  800951:	57                   	push   %edi
  800952:	56                   	push   %esi
  800953:	53                   	push   %ebx
  800954:	8b 7d 08             	mov    0x8(%ebp),%edi
  800957:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80095a:	85 c9                	test   %ecx,%ecx
  80095c:	74 36                	je     800994 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80095e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800964:	75 28                	jne    80098e <memset+0x40>
  800966:	f6 c1 03             	test   $0x3,%cl
  800969:	75 23                	jne    80098e <memset+0x40>
		c &= 0xFF;
  80096b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80096f:	89 d3                	mov    %edx,%ebx
  800971:	c1 e3 08             	shl    $0x8,%ebx
  800974:	89 d6                	mov    %edx,%esi
  800976:	c1 e6 18             	shl    $0x18,%esi
  800979:	89 d0                	mov    %edx,%eax
  80097b:	c1 e0 10             	shl    $0x10,%eax
  80097e:	09 f0                	or     %esi,%eax
  800980:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800982:	89 d8                	mov    %ebx,%eax
  800984:	09 d0                	or     %edx,%eax
  800986:	c1 e9 02             	shr    $0x2,%ecx
  800989:	fc                   	cld    
  80098a:	f3 ab                	rep stos %eax,%es:(%edi)
  80098c:	eb 06                	jmp    800994 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80098e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800991:	fc                   	cld    
  800992:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800994:	89 f8                	mov    %edi,%eax
  800996:	5b                   	pop    %ebx
  800997:	5e                   	pop    %esi
  800998:	5f                   	pop    %edi
  800999:	5d                   	pop    %ebp
  80099a:	c3                   	ret    

0080099b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80099b:	55                   	push   %ebp
  80099c:	89 e5                	mov    %esp,%ebp
  80099e:	57                   	push   %edi
  80099f:	56                   	push   %esi
  8009a0:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a3:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009a6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009a9:	39 c6                	cmp    %eax,%esi
  8009ab:	73 35                	jae    8009e2 <memmove+0x47>
  8009ad:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009b0:	39 d0                	cmp    %edx,%eax
  8009b2:	73 2e                	jae    8009e2 <memmove+0x47>
		s += n;
		d += n;
  8009b4:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009b7:	89 d6                	mov    %edx,%esi
  8009b9:	09 fe                	or     %edi,%esi
  8009bb:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009c1:	75 13                	jne    8009d6 <memmove+0x3b>
  8009c3:	f6 c1 03             	test   $0x3,%cl
  8009c6:	75 0e                	jne    8009d6 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009c8:	83 ef 04             	sub    $0x4,%edi
  8009cb:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009ce:	c1 e9 02             	shr    $0x2,%ecx
  8009d1:	fd                   	std    
  8009d2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009d4:	eb 09                	jmp    8009df <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009d6:	83 ef 01             	sub    $0x1,%edi
  8009d9:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009dc:	fd                   	std    
  8009dd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009df:	fc                   	cld    
  8009e0:	eb 1d                	jmp    8009ff <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009e2:	89 f2                	mov    %esi,%edx
  8009e4:	09 c2                	or     %eax,%edx
  8009e6:	f6 c2 03             	test   $0x3,%dl
  8009e9:	75 0f                	jne    8009fa <memmove+0x5f>
  8009eb:	f6 c1 03             	test   $0x3,%cl
  8009ee:	75 0a                	jne    8009fa <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8009f0:	c1 e9 02             	shr    $0x2,%ecx
  8009f3:	89 c7                	mov    %eax,%edi
  8009f5:	fc                   	cld    
  8009f6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009f8:	eb 05                	jmp    8009ff <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009fa:	89 c7                	mov    %eax,%edi
  8009fc:	fc                   	cld    
  8009fd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009ff:	5e                   	pop    %esi
  800a00:	5f                   	pop    %edi
  800a01:	5d                   	pop    %ebp
  800a02:	c3                   	ret    

00800a03 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a03:	55                   	push   %ebp
  800a04:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a06:	ff 75 10             	pushl  0x10(%ebp)
  800a09:	ff 75 0c             	pushl  0xc(%ebp)
  800a0c:	ff 75 08             	pushl  0x8(%ebp)
  800a0f:	e8 87 ff ff ff       	call   80099b <memmove>
}
  800a14:	c9                   	leave  
  800a15:	c3                   	ret    

00800a16 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a16:	55                   	push   %ebp
  800a17:	89 e5                	mov    %esp,%ebp
  800a19:	56                   	push   %esi
  800a1a:	53                   	push   %ebx
  800a1b:	8b 45 08             	mov    0x8(%ebp),%eax
  800a1e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a21:	89 c6                	mov    %eax,%esi
  800a23:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a26:	eb 1a                	jmp    800a42 <memcmp+0x2c>
		if (*s1 != *s2)
  800a28:	0f b6 08             	movzbl (%eax),%ecx
  800a2b:	0f b6 1a             	movzbl (%edx),%ebx
  800a2e:	38 d9                	cmp    %bl,%cl
  800a30:	74 0a                	je     800a3c <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a32:	0f b6 c1             	movzbl %cl,%eax
  800a35:	0f b6 db             	movzbl %bl,%ebx
  800a38:	29 d8                	sub    %ebx,%eax
  800a3a:	eb 0f                	jmp    800a4b <memcmp+0x35>
		s1++, s2++;
  800a3c:	83 c0 01             	add    $0x1,%eax
  800a3f:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a42:	39 f0                	cmp    %esi,%eax
  800a44:	75 e2                	jne    800a28 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a46:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a4b:	5b                   	pop    %ebx
  800a4c:	5e                   	pop    %esi
  800a4d:	5d                   	pop    %ebp
  800a4e:	c3                   	ret    

00800a4f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a4f:	55                   	push   %ebp
  800a50:	89 e5                	mov    %esp,%ebp
  800a52:	53                   	push   %ebx
  800a53:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a56:	89 c1                	mov    %eax,%ecx
  800a58:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a5b:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a5f:	eb 0a                	jmp    800a6b <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a61:	0f b6 10             	movzbl (%eax),%edx
  800a64:	39 da                	cmp    %ebx,%edx
  800a66:	74 07                	je     800a6f <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a68:	83 c0 01             	add    $0x1,%eax
  800a6b:	39 c8                	cmp    %ecx,%eax
  800a6d:	72 f2                	jb     800a61 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a6f:	5b                   	pop    %ebx
  800a70:	5d                   	pop    %ebp
  800a71:	c3                   	ret    

00800a72 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a72:	55                   	push   %ebp
  800a73:	89 e5                	mov    %esp,%ebp
  800a75:	57                   	push   %edi
  800a76:	56                   	push   %esi
  800a77:	53                   	push   %ebx
  800a78:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a7b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a7e:	eb 03                	jmp    800a83 <strtol+0x11>
		s++;
  800a80:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a83:	0f b6 01             	movzbl (%ecx),%eax
  800a86:	3c 20                	cmp    $0x20,%al
  800a88:	74 f6                	je     800a80 <strtol+0xe>
  800a8a:	3c 09                	cmp    $0x9,%al
  800a8c:	74 f2                	je     800a80 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a8e:	3c 2b                	cmp    $0x2b,%al
  800a90:	75 0a                	jne    800a9c <strtol+0x2a>
		s++;
  800a92:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a95:	bf 00 00 00 00       	mov    $0x0,%edi
  800a9a:	eb 11                	jmp    800aad <strtol+0x3b>
  800a9c:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800aa1:	3c 2d                	cmp    $0x2d,%al
  800aa3:	75 08                	jne    800aad <strtol+0x3b>
		s++, neg = 1;
  800aa5:	83 c1 01             	add    $0x1,%ecx
  800aa8:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800aad:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ab3:	75 15                	jne    800aca <strtol+0x58>
  800ab5:	80 39 30             	cmpb   $0x30,(%ecx)
  800ab8:	75 10                	jne    800aca <strtol+0x58>
  800aba:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800abe:	75 7c                	jne    800b3c <strtol+0xca>
		s += 2, base = 16;
  800ac0:	83 c1 02             	add    $0x2,%ecx
  800ac3:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ac8:	eb 16                	jmp    800ae0 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800aca:	85 db                	test   %ebx,%ebx
  800acc:	75 12                	jne    800ae0 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ace:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ad3:	80 39 30             	cmpb   $0x30,(%ecx)
  800ad6:	75 08                	jne    800ae0 <strtol+0x6e>
		s++, base = 8;
  800ad8:	83 c1 01             	add    $0x1,%ecx
  800adb:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800ae0:	b8 00 00 00 00       	mov    $0x0,%eax
  800ae5:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800ae8:	0f b6 11             	movzbl (%ecx),%edx
  800aeb:	8d 72 d0             	lea    -0x30(%edx),%esi
  800aee:	89 f3                	mov    %esi,%ebx
  800af0:	80 fb 09             	cmp    $0x9,%bl
  800af3:	77 08                	ja     800afd <strtol+0x8b>
			dig = *s - '0';
  800af5:	0f be d2             	movsbl %dl,%edx
  800af8:	83 ea 30             	sub    $0x30,%edx
  800afb:	eb 22                	jmp    800b1f <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800afd:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b00:	89 f3                	mov    %esi,%ebx
  800b02:	80 fb 19             	cmp    $0x19,%bl
  800b05:	77 08                	ja     800b0f <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b07:	0f be d2             	movsbl %dl,%edx
  800b0a:	83 ea 57             	sub    $0x57,%edx
  800b0d:	eb 10                	jmp    800b1f <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b0f:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b12:	89 f3                	mov    %esi,%ebx
  800b14:	80 fb 19             	cmp    $0x19,%bl
  800b17:	77 16                	ja     800b2f <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b19:	0f be d2             	movsbl %dl,%edx
  800b1c:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b1f:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b22:	7d 0b                	jge    800b2f <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b24:	83 c1 01             	add    $0x1,%ecx
  800b27:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b2b:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b2d:	eb b9                	jmp    800ae8 <strtol+0x76>

	if (endptr)
  800b2f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b33:	74 0d                	je     800b42 <strtol+0xd0>
		*endptr = (char *) s;
  800b35:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b38:	89 0e                	mov    %ecx,(%esi)
  800b3a:	eb 06                	jmp    800b42 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b3c:	85 db                	test   %ebx,%ebx
  800b3e:	74 98                	je     800ad8 <strtol+0x66>
  800b40:	eb 9e                	jmp    800ae0 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b42:	89 c2                	mov    %eax,%edx
  800b44:	f7 da                	neg    %edx
  800b46:	85 ff                	test   %edi,%edi
  800b48:	0f 45 c2             	cmovne %edx,%eax
}
  800b4b:	5b                   	pop    %ebx
  800b4c:	5e                   	pop    %esi
  800b4d:	5f                   	pop    %edi
  800b4e:	5d                   	pop    %ebp
  800b4f:	c3                   	ret    

00800b50 <__udivdi3>:
  800b50:	55                   	push   %ebp
  800b51:	57                   	push   %edi
  800b52:	56                   	push   %esi
  800b53:	53                   	push   %ebx
  800b54:	83 ec 1c             	sub    $0x1c,%esp
  800b57:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b5b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b5f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b63:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b67:	85 f6                	test   %esi,%esi
  800b69:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b6d:	89 ca                	mov    %ecx,%edx
  800b6f:	89 f8                	mov    %edi,%eax
  800b71:	75 3d                	jne    800bb0 <__udivdi3+0x60>
  800b73:	39 cf                	cmp    %ecx,%edi
  800b75:	0f 87 c5 00 00 00    	ja     800c40 <__udivdi3+0xf0>
  800b7b:	85 ff                	test   %edi,%edi
  800b7d:	89 fd                	mov    %edi,%ebp
  800b7f:	75 0b                	jne    800b8c <__udivdi3+0x3c>
  800b81:	b8 01 00 00 00       	mov    $0x1,%eax
  800b86:	31 d2                	xor    %edx,%edx
  800b88:	f7 f7                	div    %edi
  800b8a:	89 c5                	mov    %eax,%ebp
  800b8c:	89 c8                	mov    %ecx,%eax
  800b8e:	31 d2                	xor    %edx,%edx
  800b90:	f7 f5                	div    %ebp
  800b92:	89 c1                	mov    %eax,%ecx
  800b94:	89 d8                	mov    %ebx,%eax
  800b96:	89 cf                	mov    %ecx,%edi
  800b98:	f7 f5                	div    %ebp
  800b9a:	89 c3                	mov    %eax,%ebx
  800b9c:	89 d8                	mov    %ebx,%eax
  800b9e:	89 fa                	mov    %edi,%edx
  800ba0:	83 c4 1c             	add    $0x1c,%esp
  800ba3:	5b                   	pop    %ebx
  800ba4:	5e                   	pop    %esi
  800ba5:	5f                   	pop    %edi
  800ba6:	5d                   	pop    %ebp
  800ba7:	c3                   	ret    
  800ba8:	90                   	nop
  800ba9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bb0:	39 ce                	cmp    %ecx,%esi
  800bb2:	77 74                	ja     800c28 <__udivdi3+0xd8>
  800bb4:	0f bd fe             	bsr    %esi,%edi
  800bb7:	83 f7 1f             	xor    $0x1f,%edi
  800bba:	0f 84 98 00 00 00    	je     800c58 <__udivdi3+0x108>
  800bc0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800bc5:	89 f9                	mov    %edi,%ecx
  800bc7:	89 c5                	mov    %eax,%ebp
  800bc9:	29 fb                	sub    %edi,%ebx
  800bcb:	d3 e6                	shl    %cl,%esi
  800bcd:	89 d9                	mov    %ebx,%ecx
  800bcf:	d3 ed                	shr    %cl,%ebp
  800bd1:	89 f9                	mov    %edi,%ecx
  800bd3:	d3 e0                	shl    %cl,%eax
  800bd5:	09 ee                	or     %ebp,%esi
  800bd7:	89 d9                	mov    %ebx,%ecx
  800bd9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bdd:	89 d5                	mov    %edx,%ebp
  800bdf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800be3:	d3 ed                	shr    %cl,%ebp
  800be5:	89 f9                	mov    %edi,%ecx
  800be7:	d3 e2                	shl    %cl,%edx
  800be9:	89 d9                	mov    %ebx,%ecx
  800beb:	d3 e8                	shr    %cl,%eax
  800bed:	09 c2                	or     %eax,%edx
  800bef:	89 d0                	mov    %edx,%eax
  800bf1:	89 ea                	mov    %ebp,%edx
  800bf3:	f7 f6                	div    %esi
  800bf5:	89 d5                	mov    %edx,%ebp
  800bf7:	89 c3                	mov    %eax,%ebx
  800bf9:	f7 64 24 0c          	mull   0xc(%esp)
  800bfd:	39 d5                	cmp    %edx,%ebp
  800bff:	72 10                	jb     800c11 <__udivdi3+0xc1>
  800c01:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c05:	89 f9                	mov    %edi,%ecx
  800c07:	d3 e6                	shl    %cl,%esi
  800c09:	39 c6                	cmp    %eax,%esi
  800c0b:	73 07                	jae    800c14 <__udivdi3+0xc4>
  800c0d:	39 d5                	cmp    %edx,%ebp
  800c0f:	75 03                	jne    800c14 <__udivdi3+0xc4>
  800c11:	83 eb 01             	sub    $0x1,%ebx
  800c14:	31 ff                	xor    %edi,%edi
  800c16:	89 d8                	mov    %ebx,%eax
  800c18:	89 fa                	mov    %edi,%edx
  800c1a:	83 c4 1c             	add    $0x1c,%esp
  800c1d:	5b                   	pop    %ebx
  800c1e:	5e                   	pop    %esi
  800c1f:	5f                   	pop    %edi
  800c20:	5d                   	pop    %ebp
  800c21:	c3                   	ret    
  800c22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c28:	31 ff                	xor    %edi,%edi
  800c2a:	31 db                	xor    %ebx,%ebx
  800c2c:	89 d8                	mov    %ebx,%eax
  800c2e:	89 fa                	mov    %edi,%edx
  800c30:	83 c4 1c             	add    $0x1c,%esp
  800c33:	5b                   	pop    %ebx
  800c34:	5e                   	pop    %esi
  800c35:	5f                   	pop    %edi
  800c36:	5d                   	pop    %ebp
  800c37:	c3                   	ret    
  800c38:	90                   	nop
  800c39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c40:	89 d8                	mov    %ebx,%eax
  800c42:	f7 f7                	div    %edi
  800c44:	31 ff                	xor    %edi,%edi
  800c46:	89 c3                	mov    %eax,%ebx
  800c48:	89 d8                	mov    %ebx,%eax
  800c4a:	89 fa                	mov    %edi,%edx
  800c4c:	83 c4 1c             	add    $0x1c,%esp
  800c4f:	5b                   	pop    %ebx
  800c50:	5e                   	pop    %esi
  800c51:	5f                   	pop    %edi
  800c52:	5d                   	pop    %ebp
  800c53:	c3                   	ret    
  800c54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c58:	39 ce                	cmp    %ecx,%esi
  800c5a:	72 0c                	jb     800c68 <__udivdi3+0x118>
  800c5c:	31 db                	xor    %ebx,%ebx
  800c5e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c62:	0f 87 34 ff ff ff    	ja     800b9c <__udivdi3+0x4c>
  800c68:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c6d:	e9 2a ff ff ff       	jmp    800b9c <__udivdi3+0x4c>
  800c72:	66 90                	xchg   %ax,%ax
  800c74:	66 90                	xchg   %ax,%ax
  800c76:	66 90                	xchg   %ax,%ax
  800c78:	66 90                	xchg   %ax,%ax
  800c7a:	66 90                	xchg   %ax,%ax
  800c7c:	66 90                	xchg   %ax,%ax
  800c7e:	66 90                	xchg   %ax,%ax

00800c80 <__umoddi3>:
  800c80:	55                   	push   %ebp
  800c81:	57                   	push   %edi
  800c82:	56                   	push   %esi
  800c83:	53                   	push   %ebx
  800c84:	83 ec 1c             	sub    $0x1c,%esp
  800c87:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c8b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c8f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c93:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c97:	85 d2                	test   %edx,%edx
  800c99:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c9d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ca1:	89 f3                	mov    %esi,%ebx
  800ca3:	89 3c 24             	mov    %edi,(%esp)
  800ca6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800caa:	75 1c                	jne    800cc8 <__umoddi3+0x48>
  800cac:	39 f7                	cmp    %esi,%edi
  800cae:	76 50                	jbe    800d00 <__umoddi3+0x80>
  800cb0:	89 c8                	mov    %ecx,%eax
  800cb2:	89 f2                	mov    %esi,%edx
  800cb4:	f7 f7                	div    %edi
  800cb6:	89 d0                	mov    %edx,%eax
  800cb8:	31 d2                	xor    %edx,%edx
  800cba:	83 c4 1c             	add    $0x1c,%esp
  800cbd:	5b                   	pop    %ebx
  800cbe:	5e                   	pop    %esi
  800cbf:	5f                   	pop    %edi
  800cc0:	5d                   	pop    %ebp
  800cc1:	c3                   	ret    
  800cc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cc8:	39 f2                	cmp    %esi,%edx
  800cca:	89 d0                	mov    %edx,%eax
  800ccc:	77 52                	ja     800d20 <__umoddi3+0xa0>
  800cce:	0f bd ea             	bsr    %edx,%ebp
  800cd1:	83 f5 1f             	xor    $0x1f,%ebp
  800cd4:	75 5a                	jne    800d30 <__umoddi3+0xb0>
  800cd6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800cda:	0f 82 e0 00 00 00    	jb     800dc0 <__umoddi3+0x140>
  800ce0:	39 0c 24             	cmp    %ecx,(%esp)
  800ce3:	0f 86 d7 00 00 00    	jbe    800dc0 <__umoddi3+0x140>
  800ce9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ced:	8b 54 24 04          	mov    0x4(%esp),%edx
  800cf1:	83 c4 1c             	add    $0x1c,%esp
  800cf4:	5b                   	pop    %ebx
  800cf5:	5e                   	pop    %esi
  800cf6:	5f                   	pop    %edi
  800cf7:	5d                   	pop    %ebp
  800cf8:	c3                   	ret    
  800cf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d00:	85 ff                	test   %edi,%edi
  800d02:	89 fd                	mov    %edi,%ebp
  800d04:	75 0b                	jne    800d11 <__umoddi3+0x91>
  800d06:	b8 01 00 00 00       	mov    $0x1,%eax
  800d0b:	31 d2                	xor    %edx,%edx
  800d0d:	f7 f7                	div    %edi
  800d0f:	89 c5                	mov    %eax,%ebp
  800d11:	89 f0                	mov    %esi,%eax
  800d13:	31 d2                	xor    %edx,%edx
  800d15:	f7 f5                	div    %ebp
  800d17:	89 c8                	mov    %ecx,%eax
  800d19:	f7 f5                	div    %ebp
  800d1b:	89 d0                	mov    %edx,%eax
  800d1d:	eb 99                	jmp    800cb8 <__umoddi3+0x38>
  800d1f:	90                   	nop
  800d20:	89 c8                	mov    %ecx,%eax
  800d22:	89 f2                	mov    %esi,%edx
  800d24:	83 c4 1c             	add    $0x1c,%esp
  800d27:	5b                   	pop    %ebx
  800d28:	5e                   	pop    %esi
  800d29:	5f                   	pop    %edi
  800d2a:	5d                   	pop    %ebp
  800d2b:	c3                   	ret    
  800d2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d30:	8b 34 24             	mov    (%esp),%esi
  800d33:	bf 20 00 00 00       	mov    $0x20,%edi
  800d38:	89 e9                	mov    %ebp,%ecx
  800d3a:	29 ef                	sub    %ebp,%edi
  800d3c:	d3 e0                	shl    %cl,%eax
  800d3e:	89 f9                	mov    %edi,%ecx
  800d40:	89 f2                	mov    %esi,%edx
  800d42:	d3 ea                	shr    %cl,%edx
  800d44:	89 e9                	mov    %ebp,%ecx
  800d46:	09 c2                	or     %eax,%edx
  800d48:	89 d8                	mov    %ebx,%eax
  800d4a:	89 14 24             	mov    %edx,(%esp)
  800d4d:	89 f2                	mov    %esi,%edx
  800d4f:	d3 e2                	shl    %cl,%edx
  800d51:	89 f9                	mov    %edi,%ecx
  800d53:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d57:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d5b:	d3 e8                	shr    %cl,%eax
  800d5d:	89 e9                	mov    %ebp,%ecx
  800d5f:	89 c6                	mov    %eax,%esi
  800d61:	d3 e3                	shl    %cl,%ebx
  800d63:	89 f9                	mov    %edi,%ecx
  800d65:	89 d0                	mov    %edx,%eax
  800d67:	d3 e8                	shr    %cl,%eax
  800d69:	89 e9                	mov    %ebp,%ecx
  800d6b:	09 d8                	or     %ebx,%eax
  800d6d:	89 d3                	mov    %edx,%ebx
  800d6f:	89 f2                	mov    %esi,%edx
  800d71:	f7 34 24             	divl   (%esp)
  800d74:	89 d6                	mov    %edx,%esi
  800d76:	d3 e3                	shl    %cl,%ebx
  800d78:	f7 64 24 04          	mull   0x4(%esp)
  800d7c:	39 d6                	cmp    %edx,%esi
  800d7e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d82:	89 d1                	mov    %edx,%ecx
  800d84:	89 c3                	mov    %eax,%ebx
  800d86:	72 08                	jb     800d90 <__umoddi3+0x110>
  800d88:	75 11                	jne    800d9b <__umoddi3+0x11b>
  800d8a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d8e:	73 0b                	jae    800d9b <__umoddi3+0x11b>
  800d90:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d94:	1b 14 24             	sbb    (%esp),%edx
  800d97:	89 d1                	mov    %edx,%ecx
  800d99:	89 c3                	mov    %eax,%ebx
  800d9b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d9f:	29 da                	sub    %ebx,%edx
  800da1:	19 ce                	sbb    %ecx,%esi
  800da3:	89 f9                	mov    %edi,%ecx
  800da5:	89 f0                	mov    %esi,%eax
  800da7:	d3 e0                	shl    %cl,%eax
  800da9:	89 e9                	mov    %ebp,%ecx
  800dab:	d3 ea                	shr    %cl,%edx
  800dad:	89 e9                	mov    %ebp,%ecx
  800daf:	d3 ee                	shr    %cl,%esi
  800db1:	09 d0                	or     %edx,%eax
  800db3:	89 f2                	mov    %esi,%edx
  800db5:	83 c4 1c             	add    $0x1c,%esp
  800db8:	5b                   	pop    %ebx
  800db9:	5e                   	pop    %esi
  800dba:	5f                   	pop    %edi
  800dbb:	5d                   	pop    %ebp
  800dbc:	c3                   	ret    
  800dbd:	8d 76 00             	lea    0x0(%esi),%esi
  800dc0:	29 f9                	sub    %edi,%ecx
  800dc2:	19 d6                	sbb    %edx,%esi
  800dc4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800dc8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dcc:	e9 18 ff ff ff       	jmp    800ce9 <__umoddi3+0x69>
