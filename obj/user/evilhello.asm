
obj/user/evilhello:     file format elf32-i386


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
  80002c:	e8 19 00 00 00       	call   80004a <libmain>
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
	// try to print the kernel entry point as a string!  mua ha ha!
	sys_cputs((char*)0xf010000c, 100);
  800039:	6a 64                	push   $0x64
  80003b:	68 0c 00 10 f0       	push   $0xf010000c
  800040:	e8 4d 00 00 00       	call   800092 <sys_cputs>
}
  800045:	83 c4 10             	add    $0x10,%esp
  800048:	c9                   	leave  
  800049:	c3                   	ret    

0080004a <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80004a:	55                   	push   %ebp
  80004b:	89 e5                	mov    %esp,%ebp
  80004d:	83 ec 08             	sub    $0x8,%esp
  800050:	8b 45 08             	mov    0x8(%ebp),%eax
  800053:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800056:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80005d:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800060:	85 c0                	test   %eax,%eax
  800062:	7e 08                	jle    80006c <libmain+0x22>
		binaryname = argv[0];
  800064:	8b 0a                	mov    (%edx),%ecx
  800066:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  80006c:	83 ec 08             	sub    $0x8,%esp
  80006f:	52                   	push   %edx
  800070:	50                   	push   %eax
  800071:	e8 bd ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800076:	e8 05 00 00 00       	call   800080 <exit>
}
  80007b:	83 c4 10             	add    $0x10,%esp
  80007e:	c9                   	leave  
  80007f:	c3                   	ret    

00800080 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800080:	55                   	push   %ebp
  800081:	89 e5                	mov    %esp,%ebp
  800083:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800086:	6a 00                	push   $0x0
  800088:	e8 42 00 00 00       	call   8000cf <sys_env_destroy>
}
  80008d:	83 c4 10             	add    $0x10,%esp
  800090:	c9                   	leave  
  800091:	c3                   	ret    

00800092 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800092:	55                   	push   %ebp
  800093:	89 e5                	mov    %esp,%ebp
  800095:	57                   	push   %edi
  800096:	56                   	push   %esi
  800097:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800098:	b8 00 00 00 00       	mov    $0x0,%eax
  80009d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000a0:	8b 55 08             	mov    0x8(%ebp),%edx
  8000a3:	89 c3                	mov    %eax,%ebx
  8000a5:	89 c7                	mov    %eax,%edi
  8000a7:	89 c6                	mov    %eax,%esi
  8000a9:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000ab:	5b                   	pop    %ebx
  8000ac:	5e                   	pop    %esi
  8000ad:	5f                   	pop    %edi
  8000ae:	5d                   	pop    %ebp
  8000af:	c3                   	ret    

008000b0 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000b0:	55                   	push   %ebp
  8000b1:	89 e5                	mov    %esp,%ebp
  8000b3:	57                   	push   %edi
  8000b4:	56                   	push   %esi
  8000b5:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b6:	ba 00 00 00 00       	mov    $0x0,%edx
  8000bb:	b8 01 00 00 00       	mov    $0x1,%eax
  8000c0:	89 d1                	mov    %edx,%ecx
  8000c2:	89 d3                	mov    %edx,%ebx
  8000c4:	89 d7                	mov    %edx,%edi
  8000c6:	89 d6                	mov    %edx,%esi
  8000c8:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000ca:	5b                   	pop    %ebx
  8000cb:	5e                   	pop    %esi
  8000cc:	5f                   	pop    %edi
  8000cd:	5d                   	pop    %ebp
  8000ce:	c3                   	ret    

008000cf <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000cf:	55                   	push   %ebp
  8000d0:	89 e5                	mov    %esp,%ebp
  8000d2:	57                   	push   %edi
  8000d3:	56                   	push   %esi
  8000d4:	53                   	push   %ebx
  8000d5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d8:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000dd:	b8 03 00 00 00       	mov    $0x3,%eax
  8000e2:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e5:	89 cb                	mov    %ecx,%ebx
  8000e7:	89 cf                	mov    %ecx,%edi
  8000e9:	89 ce                	mov    %ecx,%esi
  8000eb:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000ed:	85 c0                	test   %eax,%eax
  8000ef:	7e 17                	jle    800108 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000f1:	83 ec 0c             	sub    $0xc,%esp
  8000f4:	50                   	push   %eax
  8000f5:	6a 03                	push   $0x3
  8000f7:	68 ee 0d 80 00       	push   $0x800dee
  8000fc:	6a 23                	push   $0x23
  8000fe:	68 0b 0e 80 00       	push   $0x800e0b
  800103:	e8 27 00 00 00       	call   80012f <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800108:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80010b:	5b                   	pop    %ebx
  80010c:	5e                   	pop    %esi
  80010d:	5f                   	pop    %edi
  80010e:	5d                   	pop    %ebp
  80010f:	c3                   	ret    

00800110 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800110:	55                   	push   %ebp
  800111:	89 e5                	mov    %esp,%ebp
  800113:	57                   	push   %edi
  800114:	56                   	push   %esi
  800115:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800116:	ba 00 00 00 00       	mov    $0x0,%edx
  80011b:	b8 02 00 00 00       	mov    $0x2,%eax
  800120:	89 d1                	mov    %edx,%ecx
  800122:	89 d3                	mov    %edx,%ebx
  800124:	89 d7                	mov    %edx,%edi
  800126:	89 d6                	mov    %edx,%esi
  800128:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80012a:	5b                   	pop    %ebx
  80012b:	5e                   	pop    %esi
  80012c:	5f                   	pop    %edi
  80012d:	5d                   	pop    %ebp
  80012e:	c3                   	ret    

0080012f <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80012f:	55                   	push   %ebp
  800130:	89 e5                	mov    %esp,%ebp
  800132:	56                   	push   %esi
  800133:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800134:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800137:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80013d:	e8 ce ff ff ff       	call   800110 <sys_getenvid>
  800142:	83 ec 0c             	sub    $0xc,%esp
  800145:	ff 75 0c             	pushl  0xc(%ebp)
  800148:	ff 75 08             	pushl  0x8(%ebp)
  80014b:	56                   	push   %esi
  80014c:	50                   	push   %eax
  80014d:	68 1c 0e 80 00       	push   $0x800e1c
  800152:	e8 b1 00 00 00       	call   800208 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800157:	83 c4 18             	add    $0x18,%esp
  80015a:	53                   	push   %ebx
  80015b:	ff 75 10             	pushl  0x10(%ebp)
  80015e:	e8 54 00 00 00       	call   8001b7 <vcprintf>
	cprintf("\n");
  800163:	c7 04 24 40 0e 80 00 	movl   $0x800e40,(%esp)
  80016a:	e8 99 00 00 00       	call   800208 <cprintf>
  80016f:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800172:	cc                   	int3   
  800173:	eb fd                	jmp    800172 <_panic+0x43>

00800175 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800175:	55                   	push   %ebp
  800176:	89 e5                	mov    %esp,%ebp
  800178:	53                   	push   %ebx
  800179:	83 ec 04             	sub    $0x4,%esp
  80017c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80017f:	8b 13                	mov    (%ebx),%edx
  800181:	8d 42 01             	lea    0x1(%edx),%eax
  800184:	89 03                	mov    %eax,(%ebx)
  800186:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800189:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80018d:	3d ff 00 00 00       	cmp    $0xff,%eax
  800192:	75 1a                	jne    8001ae <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800194:	83 ec 08             	sub    $0x8,%esp
  800197:	68 ff 00 00 00       	push   $0xff
  80019c:	8d 43 08             	lea    0x8(%ebx),%eax
  80019f:	50                   	push   %eax
  8001a0:	e8 ed fe ff ff       	call   800092 <sys_cputs>
		b->idx = 0;
  8001a5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001ab:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001ae:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001b2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001b5:	c9                   	leave  
  8001b6:	c3                   	ret    

008001b7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001b7:	55                   	push   %ebp
  8001b8:	89 e5                	mov    %esp,%ebp
  8001ba:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001c0:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001c7:	00 00 00 
	b.cnt = 0;
  8001ca:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001d1:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001d4:	ff 75 0c             	pushl  0xc(%ebp)
  8001d7:	ff 75 08             	pushl  0x8(%ebp)
  8001da:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001e0:	50                   	push   %eax
  8001e1:	68 75 01 80 00       	push   $0x800175
  8001e6:	e8 1a 01 00 00       	call   800305 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001eb:	83 c4 08             	add    $0x8,%esp
  8001ee:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001f4:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001fa:	50                   	push   %eax
  8001fb:	e8 92 fe ff ff       	call   800092 <sys_cputs>

	return b.cnt;
}
  800200:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800206:	c9                   	leave  
  800207:	c3                   	ret    

00800208 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800208:	55                   	push   %ebp
  800209:	89 e5                	mov    %esp,%ebp
  80020b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80020e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800211:	50                   	push   %eax
  800212:	ff 75 08             	pushl  0x8(%ebp)
  800215:	e8 9d ff ff ff       	call   8001b7 <vcprintf>
	va_end(ap);

	return cnt;
}
  80021a:	c9                   	leave  
  80021b:	c3                   	ret    

0080021c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80021c:	55                   	push   %ebp
  80021d:	89 e5                	mov    %esp,%ebp
  80021f:	57                   	push   %edi
  800220:	56                   	push   %esi
  800221:	53                   	push   %ebx
  800222:	83 ec 1c             	sub    $0x1c,%esp
  800225:	89 c7                	mov    %eax,%edi
  800227:	89 d6                	mov    %edx,%esi
  800229:	8b 45 08             	mov    0x8(%ebp),%eax
  80022c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80022f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800232:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800235:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800238:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800240:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800243:	39 d3                	cmp    %edx,%ebx
  800245:	72 05                	jb     80024c <printnum+0x30>
  800247:	39 45 10             	cmp    %eax,0x10(%ebp)
  80024a:	77 45                	ja     800291 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80024c:	83 ec 0c             	sub    $0xc,%esp
  80024f:	ff 75 18             	pushl  0x18(%ebp)
  800252:	8b 45 14             	mov    0x14(%ebp),%eax
  800255:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800258:	53                   	push   %ebx
  800259:	ff 75 10             	pushl  0x10(%ebp)
  80025c:	83 ec 08             	sub    $0x8,%esp
  80025f:	ff 75 e4             	pushl  -0x1c(%ebp)
  800262:	ff 75 e0             	pushl  -0x20(%ebp)
  800265:	ff 75 dc             	pushl  -0x24(%ebp)
  800268:	ff 75 d8             	pushl  -0x28(%ebp)
  80026b:	e8 f0 08 00 00       	call   800b60 <__udivdi3>
  800270:	83 c4 18             	add    $0x18,%esp
  800273:	52                   	push   %edx
  800274:	50                   	push   %eax
  800275:	89 f2                	mov    %esi,%edx
  800277:	89 f8                	mov    %edi,%eax
  800279:	e8 9e ff ff ff       	call   80021c <printnum>
  80027e:	83 c4 20             	add    $0x20,%esp
  800281:	eb 18                	jmp    80029b <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800283:	83 ec 08             	sub    $0x8,%esp
  800286:	56                   	push   %esi
  800287:	ff 75 18             	pushl  0x18(%ebp)
  80028a:	ff d7                	call   *%edi
  80028c:	83 c4 10             	add    $0x10,%esp
  80028f:	eb 03                	jmp    800294 <printnum+0x78>
  800291:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800294:	83 eb 01             	sub    $0x1,%ebx
  800297:	85 db                	test   %ebx,%ebx
  800299:	7f e8                	jg     800283 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80029b:	83 ec 08             	sub    $0x8,%esp
  80029e:	56                   	push   %esi
  80029f:	83 ec 04             	sub    $0x4,%esp
  8002a2:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002a5:	ff 75 e0             	pushl  -0x20(%ebp)
  8002a8:	ff 75 dc             	pushl  -0x24(%ebp)
  8002ab:	ff 75 d8             	pushl  -0x28(%ebp)
  8002ae:	e8 dd 09 00 00       	call   800c90 <__umoddi3>
  8002b3:	83 c4 14             	add    $0x14,%esp
  8002b6:	0f be 80 42 0e 80 00 	movsbl 0x800e42(%eax),%eax
  8002bd:	50                   	push   %eax
  8002be:	ff d7                	call   *%edi
}
  8002c0:	83 c4 10             	add    $0x10,%esp
  8002c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002c6:	5b                   	pop    %ebx
  8002c7:	5e                   	pop    %esi
  8002c8:	5f                   	pop    %edi
  8002c9:	5d                   	pop    %ebp
  8002ca:	c3                   	ret    

008002cb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002cb:	55                   	push   %ebp
  8002cc:	89 e5                	mov    %esp,%ebp
  8002ce:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002d1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002d5:	8b 10                	mov    (%eax),%edx
  8002d7:	3b 50 04             	cmp    0x4(%eax),%edx
  8002da:	73 0a                	jae    8002e6 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002dc:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002df:	89 08                	mov    %ecx,(%eax)
  8002e1:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e4:	88 02                	mov    %al,(%edx)
}
  8002e6:	5d                   	pop    %ebp
  8002e7:	c3                   	ret    

008002e8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002e8:	55                   	push   %ebp
  8002e9:	89 e5                	mov    %esp,%ebp
  8002eb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002ee:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002f1:	50                   	push   %eax
  8002f2:	ff 75 10             	pushl  0x10(%ebp)
  8002f5:	ff 75 0c             	pushl  0xc(%ebp)
  8002f8:	ff 75 08             	pushl  0x8(%ebp)
  8002fb:	e8 05 00 00 00       	call   800305 <vprintfmt>
	va_end(ap);
}
  800300:	83 c4 10             	add    $0x10,%esp
  800303:	c9                   	leave  
  800304:	c3                   	ret    

00800305 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800305:	55                   	push   %ebp
  800306:	89 e5                	mov    %esp,%ebp
  800308:	57                   	push   %edi
  800309:	56                   	push   %esi
  80030a:	53                   	push   %ebx
  80030b:	83 ec 2c             	sub    $0x2c,%esp
  80030e:	8b 75 08             	mov    0x8(%ebp),%esi
  800311:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800314:	8b 7d 10             	mov    0x10(%ebp),%edi
  800317:	eb 12                	jmp    80032b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800319:	85 c0                	test   %eax,%eax
  80031b:	0f 84 42 04 00 00    	je     800763 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800321:	83 ec 08             	sub    $0x8,%esp
  800324:	53                   	push   %ebx
  800325:	50                   	push   %eax
  800326:	ff d6                	call   *%esi
  800328:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80032b:	83 c7 01             	add    $0x1,%edi
  80032e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800332:	83 f8 25             	cmp    $0x25,%eax
  800335:	75 e2                	jne    800319 <vprintfmt+0x14>
  800337:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80033b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800342:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800349:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800350:	b9 00 00 00 00       	mov    $0x0,%ecx
  800355:	eb 07                	jmp    80035e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800357:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80035a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80035e:	8d 47 01             	lea    0x1(%edi),%eax
  800361:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800364:	0f b6 07             	movzbl (%edi),%eax
  800367:	0f b6 d0             	movzbl %al,%edx
  80036a:	83 e8 23             	sub    $0x23,%eax
  80036d:	3c 55                	cmp    $0x55,%al
  80036f:	0f 87 d3 03 00 00    	ja     800748 <vprintfmt+0x443>
  800375:	0f b6 c0             	movzbl %al,%eax
  800378:	ff 24 85 d0 0e 80 00 	jmp    *0x800ed0(,%eax,4)
  80037f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800382:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800386:	eb d6                	jmp    80035e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800388:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80038b:	b8 00 00 00 00       	mov    $0x0,%eax
  800390:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800393:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800396:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80039a:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  80039d:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8003a0:	83 f9 09             	cmp    $0x9,%ecx
  8003a3:	77 3f                	ja     8003e4 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003a5:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003a8:	eb e9                	jmp    800393 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003aa:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ad:	8b 00                	mov    (%eax),%eax
  8003af:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b5:	8d 40 04             	lea    0x4(%eax),%eax
  8003b8:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003be:	eb 2a                	jmp    8003ea <vprintfmt+0xe5>
  8003c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003c3:	85 c0                	test   %eax,%eax
  8003c5:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ca:	0f 49 d0             	cmovns %eax,%edx
  8003cd:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003d3:	eb 89                	jmp    80035e <vprintfmt+0x59>
  8003d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003d8:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003df:	e9 7a ff ff ff       	jmp    80035e <vprintfmt+0x59>
  8003e4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003e7:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8003ea:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003ee:	0f 89 6a ff ff ff    	jns    80035e <vprintfmt+0x59>
				width = precision, precision = -1;
  8003f4:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003fa:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800401:	e9 58 ff ff ff       	jmp    80035e <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800406:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800409:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80040c:	e9 4d ff ff ff       	jmp    80035e <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800411:	8b 45 14             	mov    0x14(%ebp),%eax
  800414:	8d 78 04             	lea    0x4(%eax),%edi
  800417:	83 ec 08             	sub    $0x8,%esp
  80041a:	53                   	push   %ebx
  80041b:	ff 30                	pushl  (%eax)
  80041d:	ff d6                	call   *%esi
			break;
  80041f:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800422:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800425:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800428:	e9 fe fe ff ff       	jmp    80032b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80042d:	8b 45 14             	mov    0x14(%ebp),%eax
  800430:	8d 78 04             	lea    0x4(%eax),%edi
  800433:	8b 00                	mov    (%eax),%eax
  800435:	99                   	cltd   
  800436:	31 d0                	xor    %edx,%eax
  800438:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80043a:	83 f8 06             	cmp    $0x6,%eax
  80043d:	7f 0b                	jg     80044a <vprintfmt+0x145>
  80043f:	8b 14 85 28 10 80 00 	mov    0x801028(,%eax,4),%edx
  800446:	85 d2                	test   %edx,%edx
  800448:	75 1b                	jne    800465 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80044a:	50                   	push   %eax
  80044b:	68 5a 0e 80 00       	push   $0x800e5a
  800450:	53                   	push   %ebx
  800451:	56                   	push   %esi
  800452:	e8 91 fe ff ff       	call   8002e8 <printfmt>
  800457:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80045a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800460:	e9 c6 fe ff ff       	jmp    80032b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800465:	52                   	push   %edx
  800466:	68 63 0e 80 00       	push   $0x800e63
  80046b:	53                   	push   %ebx
  80046c:	56                   	push   %esi
  80046d:	e8 76 fe ff ff       	call   8002e8 <printfmt>
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
  80047b:	e9 ab fe ff ff       	jmp    80032b <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800480:	8b 45 14             	mov    0x14(%ebp),%eax
  800483:	83 c0 04             	add    $0x4,%eax
  800486:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800489:	8b 45 14             	mov    0x14(%ebp),%eax
  80048c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80048e:	85 ff                	test   %edi,%edi
  800490:	b8 53 0e 80 00       	mov    $0x800e53,%eax
  800495:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800498:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80049c:	0f 8e 94 00 00 00    	jle    800536 <vprintfmt+0x231>
  8004a2:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004a6:	0f 84 98 00 00 00    	je     800544 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ac:	83 ec 08             	sub    $0x8,%esp
  8004af:	ff 75 d0             	pushl  -0x30(%ebp)
  8004b2:	57                   	push   %edi
  8004b3:	e8 33 03 00 00       	call   8007eb <strnlen>
  8004b8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004bb:	29 c1                	sub    %eax,%ecx
  8004bd:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004c0:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004c3:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004c7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004ca:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004cd:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004cf:	eb 0f                	jmp    8004e0 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004d1:	83 ec 08             	sub    $0x8,%esp
  8004d4:	53                   	push   %ebx
  8004d5:	ff 75 e0             	pushl  -0x20(%ebp)
  8004d8:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004da:	83 ef 01             	sub    $0x1,%edi
  8004dd:	83 c4 10             	add    $0x10,%esp
  8004e0:	85 ff                	test   %edi,%edi
  8004e2:	7f ed                	jg     8004d1 <vprintfmt+0x1cc>
  8004e4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004e7:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004ea:	85 c9                	test   %ecx,%ecx
  8004ec:	b8 00 00 00 00       	mov    $0x0,%eax
  8004f1:	0f 49 c1             	cmovns %ecx,%eax
  8004f4:	29 c1                	sub    %eax,%ecx
  8004f6:	89 75 08             	mov    %esi,0x8(%ebp)
  8004f9:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004fc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004ff:	89 cb                	mov    %ecx,%ebx
  800501:	eb 4d                	jmp    800550 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800503:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800507:	74 1b                	je     800524 <vprintfmt+0x21f>
  800509:	0f be c0             	movsbl %al,%eax
  80050c:	83 e8 20             	sub    $0x20,%eax
  80050f:	83 f8 5e             	cmp    $0x5e,%eax
  800512:	76 10                	jbe    800524 <vprintfmt+0x21f>
					putch('?', putdat);
  800514:	83 ec 08             	sub    $0x8,%esp
  800517:	ff 75 0c             	pushl  0xc(%ebp)
  80051a:	6a 3f                	push   $0x3f
  80051c:	ff 55 08             	call   *0x8(%ebp)
  80051f:	83 c4 10             	add    $0x10,%esp
  800522:	eb 0d                	jmp    800531 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800524:	83 ec 08             	sub    $0x8,%esp
  800527:	ff 75 0c             	pushl  0xc(%ebp)
  80052a:	52                   	push   %edx
  80052b:	ff 55 08             	call   *0x8(%ebp)
  80052e:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800531:	83 eb 01             	sub    $0x1,%ebx
  800534:	eb 1a                	jmp    800550 <vprintfmt+0x24b>
  800536:	89 75 08             	mov    %esi,0x8(%ebp)
  800539:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80053c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80053f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800542:	eb 0c                	jmp    800550 <vprintfmt+0x24b>
  800544:	89 75 08             	mov    %esi,0x8(%ebp)
  800547:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80054a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80054d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800550:	83 c7 01             	add    $0x1,%edi
  800553:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800557:	0f be d0             	movsbl %al,%edx
  80055a:	85 d2                	test   %edx,%edx
  80055c:	74 23                	je     800581 <vprintfmt+0x27c>
  80055e:	85 f6                	test   %esi,%esi
  800560:	78 a1                	js     800503 <vprintfmt+0x1fe>
  800562:	83 ee 01             	sub    $0x1,%esi
  800565:	79 9c                	jns    800503 <vprintfmt+0x1fe>
  800567:	89 df                	mov    %ebx,%edi
  800569:	8b 75 08             	mov    0x8(%ebp),%esi
  80056c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80056f:	eb 18                	jmp    800589 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800571:	83 ec 08             	sub    $0x8,%esp
  800574:	53                   	push   %ebx
  800575:	6a 20                	push   $0x20
  800577:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800579:	83 ef 01             	sub    $0x1,%edi
  80057c:	83 c4 10             	add    $0x10,%esp
  80057f:	eb 08                	jmp    800589 <vprintfmt+0x284>
  800581:	89 df                	mov    %ebx,%edi
  800583:	8b 75 08             	mov    0x8(%ebp),%esi
  800586:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800589:	85 ff                	test   %edi,%edi
  80058b:	7f e4                	jg     800571 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80058d:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800590:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800593:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800596:	e9 90 fd ff ff       	jmp    80032b <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80059b:	83 f9 01             	cmp    $0x1,%ecx
  80059e:	7e 19                	jle    8005b9 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8005a0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a3:	8b 50 04             	mov    0x4(%eax),%edx
  8005a6:	8b 00                	mov    (%eax),%eax
  8005a8:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005ab:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005ae:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b1:	8d 40 08             	lea    0x8(%eax),%eax
  8005b4:	89 45 14             	mov    %eax,0x14(%ebp)
  8005b7:	eb 38                	jmp    8005f1 <vprintfmt+0x2ec>
	else if (lflag)
  8005b9:	85 c9                	test   %ecx,%ecx
  8005bb:	74 1b                	je     8005d8 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005bd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c0:	8b 00                	mov    (%eax),%eax
  8005c2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005c5:	89 c1                	mov    %eax,%ecx
  8005c7:	c1 f9 1f             	sar    $0x1f,%ecx
  8005ca:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d0:	8d 40 04             	lea    0x4(%eax),%eax
  8005d3:	89 45 14             	mov    %eax,0x14(%ebp)
  8005d6:	eb 19                	jmp    8005f1 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005db:	8b 00                	mov    (%eax),%eax
  8005dd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005e0:	89 c1                	mov    %eax,%ecx
  8005e2:	c1 f9 1f             	sar    $0x1f,%ecx
  8005e5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005e8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005eb:	8d 40 04             	lea    0x4(%eax),%eax
  8005ee:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005f1:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005f4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005f7:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005fc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800600:	0f 89 0e 01 00 00    	jns    800714 <vprintfmt+0x40f>
				putch('-', putdat);
  800606:	83 ec 08             	sub    $0x8,%esp
  800609:	53                   	push   %ebx
  80060a:	6a 2d                	push   $0x2d
  80060c:	ff d6                	call   *%esi
				num = -(long long) num;
  80060e:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800611:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800614:	f7 da                	neg    %edx
  800616:	83 d1 00             	adc    $0x0,%ecx
  800619:	f7 d9                	neg    %ecx
  80061b:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80061e:	b8 0a 00 00 00       	mov    $0xa,%eax
  800623:	e9 ec 00 00 00       	jmp    800714 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800628:	83 f9 01             	cmp    $0x1,%ecx
  80062b:	7e 18                	jle    800645 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80062d:	8b 45 14             	mov    0x14(%ebp),%eax
  800630:	8b 10                	mov    (%eax),%edx
  800632:	8b 48 04             	mov    0x4(%eax),%ecx
  800635:	8d 40 08             	lea    0x8(%eax),%eax
  800638:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80063b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800640:	e9 cf 00 00 00       	jmp    800714 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800645:	85 c9                	test   %ecx,%ecx
  800647:	74 1a                	je     800663 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800649:	8b 45 14             	mov    0x14(%ebp),%eax
  80064c:	8b 10                	mov    (%eax),%edx
  80064e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800653:	8d 40 04             	lea    0x4(%eax),%eax
  800656:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800659:	b8 0a 00 00 00       	mov    $0xa,%eax
  80065e:	e9 b1 00 00 00       	jmp    800714 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800663:	8b 45 14             	mov    0x14(%ebp),%eax
  800666:	8b 10                	mov    (%eax),%edx
  800668:	b9 00 00 00 00       	mov    $0x0,%ecx
  80066d:	8d 40 04             	lea    0x4(%eax),%eax
  800670:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800673:	b8 0a 00 00 00       	mov    $0xa,%eax
  800678:	e9 97 00 00 00       	jmp    800714 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  80067d:	83 ec 08             	sub    $0x8,%esp
  800680:	53                   	push   %ebx
  800681:	6a 58                	push   $0x58
  800683:	ff d6                	call   *%esi
			putch('X', putdat);
  800685:	83 c4 08             	add    $0x8,%esp
  800688:	53                   	push   %ebx
  800689:	6a 58                	push   $0x58
  80068b:	ff d6                	call   *%esi
			putch('X', putdat);
  80068d:	83 c4 08             	add    $0x8,%esp
  800690:	53                   	push   %ebx
  800691:	6a 58                	push   $0x58
  800693:	ff d6                	call   *%esi
			break;
  800695:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800698:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  80069b:	e9 8b fc ff ff       	jmp    80032b <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8006a0:	83 ec 08             	sub    $0x8,%esp
  8006a3:	53                   	push   %ebx
  8006a4:	6a 30                	push   $0x30
  8006a6:	ff d6                	call   *%esi
			putch('x', putdat);
  8006a8:	83 c4 08             	add    $0x8,%esp
  8006ab:	53                   	push   %ebx
  8006ac:	6a 78                	push   $0x78
  8006ae:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006b0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b3:	8b 10                	mov    (%eax),%edx
  8006b5:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006ba:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006bd:	8d 40 04             	lea    0x4(%eax),%eax
  8006c0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006c3:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006c8:	eb 4a                	jmp    800714 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006ca:	83 f9 01             	cmp    $0x1,%ecx
  8006cd:	7e 15                	jle    8006e4 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006cf:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d2:	8b 10                	mov    (%eax),%edx
  8006d4:	8b 48 04             	mov    0x4(%eax),%ecx
  8006d7:	8d 40 08             	lea    0x8(%eax),%eax
  8006da:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006dd:	b8 10 00 00 00       	mov    $0x10,%eax
  8006e2:	eb 30                	jmp    800714 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006e4:	85 c9                	test   %ecx,%ecx
  8006e6:	74 17                	je     8006ff <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8006e8:	8b 45 14             	mov    0x14(%ebp),%eax
  8006eb:	8b 10                	mov    (%eax),%edx
  8006ed:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006f2:	8d 40 04             	lea    0x4(%eax),%eax
  8006f5:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006f8:	b8 10 00 00 00       	mov    $0x10,%eax
  8006fd:	eb 15                	jmp    800714 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8006ff:	8b 45 14             	mov    0x14(%ebp),%eax
  800702:	8b 10                	mov    (%eax),%edx
  800704:	b9 00 00 00 00       	mov    $0x0,%ecx
  800709:	8d 40 04             	lea    0x4(%eax),%eax
  80070c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80070f:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800714:	83 ec 0c             	sub    $0xc,%esp
  800717:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80071b:	57                   	push   %edi
  80071c:	ff 75 e0             	pushl  -0x20(%ebp)
  80071f:	50                   	push   %eax
  800720:	51                   	push   %ecx
  800721:	52                   	push   %edx
  800722:	89 da                	mov    %ebx,%edx
  800724:	89 f0                	mov    %esi,%eax
  800726:	e8 f1 fa ff ff       	call   80021c <printnum>
			break;
  80072b:	83 c4 20             	add    $0x20,%esp
  80072e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800731:	e9 f5 fb ff ff       	jmp    80032b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800736:	83 ec 08             	sub    $0x8,%esp
  800739:	53                   	push   %ebx
  80073a:	52                   	push   %edx
  80073b:	ff d6                	call   *%esi
			break;
  80073d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800740:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800743:	e9 e3 fb ff ff       	jmp    80032b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800748:	83 ec 08             	sub    $0x8,%esp
  80074b:	53                   	push   %ebx
  80074c:	6a 25                	push   $0x25
  80074e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800750:	83 c4 10             	add    $0x10,%esp
  800753:	eb 03                	jmp    800758 <vprintfmt+0x453>
  800755:	83 ef 01             	sub    $0x1,%edi
  800758:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80075c:	75 f7                	jne    800755 <vprintfmt+0x450>
  80075e:	e9 c8 fb ff ff       	jmp    80032b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800763:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800766:	5b                   	pop    %ebx
  800767:	5e                   	pop    %esi
  800768:	5f                   	pop    %edi
  800769:	5d                   	pop    %ebp
  80076a:	c3                   	ret    

0080076b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80076b:	55                   	push   %ebp
  80076c:	89 e5                	mov    %esp,%ebp
  80076e:	83 ec 18             	sub    $0x18,%esp
  800771:	8b 45 08             	mov    0x8(%ebp),%eax
  800774:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800777:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80077a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80077e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800781:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800788:	85 c0                	test   %eax,%eax
  80078a:	74 26                	je     8007b2 <vsnprintf+0x47>
  80078c:	85 d2                	test   %edx,%edx
  80078e:	7e 22                	jle    8007b2 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800790:	ff 75 14             	pushl  0x14(%ebp)
  800793:	ff 75 10             	pushl  0x10(%ebp)
  800796:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800799:	50                   	push   %eax
  80079a:	68 cb 02 80 00       	push   $0x8002cb
  80079f:	e8 61 fb ff ff       	call   800305 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007a4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007a7:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007ad:	83 c4 10             	add    $0x10,%esp
  8007b0:	eb 05                	jmp    8007b7 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007b2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007b7:	c9                   	leave  
  8007b8:	c3                   	ret    

008007b9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007b9:	55                   	push   %ebp
  8007ba:	89 e5                	mov    %esp,%ebp
  8007bc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007bf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007c2:	50                   	push   %eax
  8007c3:	ff 75 10             	pushl  0x10(%ebp)
  8007c6:	ff 75 0c             	pushl  0xc(%ebp)
  8007c9:	ff 75 08             	pushl  0x8(%ebp)
  8007cc:	e8 9a ff ff ff       	call   80076b <vsnprintf>
	va_end(ap);

	return rc;
}
  8007d1:	c9                   	leave  
  8007d2:	c3                   	ret    

008007d3 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007d3:	55                   	push   %ebp
  8007d4:	89 e5                	mov    %esp,%ebp
  8007d6:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007d9:	b8 00 00 00 00       	mov    $0x0,%eax
  8007de:	eb 03                	jmp    8007e3 <strlen+0x10>
		n++;
  8007e0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007e3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007e7:	75 f7                	jne    8007e0 <strlen+0xd>
		n++;
	return n;
}
  8007e9:	5d                   	pop    %ebp
  8007ea:	c3                   	ret    

008007eb <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007eb:	55                   	push   %ebp
  8007ec:	89 e5                	mov    %esp,%ebp
  8007ee:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007f1:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007f4:	ba 00 00 00 00       	mov    $0x0,%edx
  8007f9:	eb 03                	jmp    8007fe <strnlen+0x13>
		n++;
  8007fb:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007fe:	39 c2                	cmp    %eax,%edx
  800800:	74 08                	je     80080a <strnlen+0x1f>
  800802:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800806:	75 f3                	jne    8007fb <strnlen+0x10>
  800808:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80080a:	5d                   	pop    %ebp
  80080b:	c3                   	ret    

0080080c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80080c:	55                   	push   %ebp
  80080d:	89 e5                	mov    %esp,%ebp
  80080f:	53                   	push   %ebx
  800810:	8b 45 08             	mov    0x8(%ebp),%eax
  800813:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800816:	89 c2                	mov    %eax,%edx
  800818:	83 c2 01             	add    $0x1,%edx
  80081b:	83 c1 01             	add    $0x1,%ecx
  80081e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800822:	88 5a ff             	mov    %bl,-0x1(%edx)
  800825:	84 db                	test   %bl,%bl
  800827:	75 ef                	jne    800818 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800829:	5b                   	pop    %ebx
  80082a:	5d                   	pop    %ebp
  80082b:	c3                   	ret    

0080082c <strcat>:

char *
strcat(char *dst, const char *src)
{
  80082c:	55                   	push   %ebp
  80082d:	89 e5                	mov    %esp,%ebp
  80082f:	53                   	push   %ebx
  800830:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800833:	53                   	push   %ebx
  800834:	e8 9a ff ff ff       	call   8007d3 <strlen>
  800839:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80083c:	ff 75 0c             	pushl  0xc(%ebp)
  80083f:	01 d8                	add    %ebx,%eax
  800841:	50                   	push   %eax
  800842:	e8 c5 ff ff ff       	call   80080c <strcpy>
	return dst;
}
  800847:	89 d8                	mov    %ebx,%eax
  800849:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80084c:	c9                   	leave  
  80084d:	c3                   	ret    

0080084e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80084e:	55                   	push   %ebp
  80084f:	89 e5                	mov    %esp,%ebp
  800851:	56                   	push   %esi
  800852:	53                   	push   %ebx
  800853:	8b 75 08             	mov    0x8(%ebp),%esi
  800856:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800859:	89 f3                	mov    %esi,%ebx
  80085b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80085e:	89 f2                	mov    %esi,%edx
  800860:	eb 0f                	jmp    800871 <strncpy+0x23>
		*dst++ = *src;
  800862:	83 c2 01             	add    $0x1,%edx
  800865:	0f b6 01             	movzbl (%ecx),%eax
  800868:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80086b:	80 39 01             	cmpb   $0x1,(%ecx)
  80086e:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800871:	39 da                	cmp    %ebx,%edx
  800873:	75 ed                	jne    800862 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800875:	89 f0                	mov    %esi,%eax
  800877:	5b                   	pop    %ebx
  800878:	5e                   	pop    %esi
  800879:	5d                   	pop    %ebp
  80087a:	c3                   	ret    

0080087b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80087b:	55                   	push   %ebp
  80087c:	89 e5                	mov    %esp,%ebp
  80087e:	56                   	push   %esi
  80087f:	53                   	push   %ebx
  800880:	8b 75 08             	mov    0x8(%ebp),%esi
  800883:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800886:	8b 55 10             	mov    0x10(%ebp),%edx
  800889:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80088b:	85 d2                	test   %edx,%edx
  80088d:	74 21                	je     8008b0 <strlcpy+0x35>
  80088f:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800893:	89 f2                	mov    %esi,%edx
  800895:	eb 09                	jmp    8008a0 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800897:	83 c2 01             	add    $0x1,%edx
  80089a:	83 c1 01             	add    $0x1,%ecx
  80089d:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008a0:	39 c2                	cmp    %eax,%edx
  8008a2:	74 09                	je     8008ad <strlcpy+0x32>
  8008a4:	0f b6 19             	movzbl (%ecx),%ebx
  8008a7:	84 db                	test   %bl,%bl
  8008a9:	75 ec                	jne    800897 <strlcpy+0x1c>
  8008ab:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008ad:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008b0:	29 f0                	sub    %esi,%eax
}
  8008b2:	5b                   	pop    %ebx
  8008b3:	5e                   	pop    %esi
  8008b4:	5d                   	pop    %ebp
  8008b5:	c3                   	ret    

008008b6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008b6:	55                   	push   %ebp
  8008b7:	89 e5                	mov    %esp,%ebp
  8008b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008bc:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008bf:	eb 06                	jmp    8008c7 <strcmp+0x11>
		p++, q++;
  8008c1:	83 c1 01             	add    $0x1,%ecx
  8008c4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008c7:	0f b6 01             	movzbl (%ecx),%eax
  8008ca:	84 c0                	test   %al,%al
  8008cc:	74 04                	je     8008d2 <strcmp+0x1c>
  8008ce:	3a 02                	cmp    (%edx),%al
  8008d0:	74 ef                	je     8008c1 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008d2:	0f b6 c0             	movzbl %al,%eax
  8008d5:	0f b6 12             	movzbl (%edx),%edx
  8008d8:	29 d0                	sub    %edx,%eax
}
  8008da:	5d                   	pop    %ebp
  8008db:	c3                   	ret    

008008dc <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008dc:	55                   	push   %ebp
  8008dd:	89 e5                	mov    %esp,%ebp
  8008df:	53                   	push   %ebx
  8008e0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008e6:	89 c3                	mov    %eax,%ebx
  8008e8:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008eb:	eb 06                	jmp    8008f3 <strncmp+0x17>
		n--, p++, q++;
  8008ed:	83 c0 01             	add    $0x1,%eax
  8008f0:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008f3:	39 d8                	cmp    %ebx,%eax
  8008f5:	74 15                	je     80090c <strncmp+0x30>
  8008f7:	0f b6 08             	movzbl (%eax),%ecx
  8008fa:	84 c9                	test   %cl,%cl
  8008fc:	74 04                	je     800902 <strncmp+0x26>
  8008fe:	3a 0a                	cmp    (%edx),%cl
  800900:	74 eb                	je     8008ed <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800902:	0f b6 00             	movzbl (%eax),%eax
  800905:	0f b6 12             	movzbl (%edx),%edx
  800908:	29 d0                	sub    %edx,%eax
  80090a:	eb 05                	jmp    800911 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80090c:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800911:	5b                   	pop    %ebx
  800912:	5d                   	pop    %ebp
  800913:	c3                   	ret    

00800914 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800914:	55                   	push   %ebp
  800915:	89 e5                	mov    %esp,%ebp
  800917:	8b 45 08             	mov    0x8(%ebp),%eax
  80091a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80091e:	eb 07                	jmp    800927 <strchr+0x13>
		if (*s == c)
  800920:	38 ca                	cmp    %cl,%dl
  800922:	74 0f                	je     800933 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800924:	83 c0 01             	add    $0x1,%eax
  800927:	0f b6 10             	movzbl (%eax),%edx
  80092a:	84 d2                	test   %dl,%dl
  80092c:	75 f2                	jne    800920 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80092e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800933:	5d                   	pop    %ebp
  800934:	c3                   	ret    

00800935 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800935:	55                   	push   %ebp
  800936:	89 e5                	mov    %esp,%ebp
  800938:	8b 45 08             	mov    0x8(%ebp),%eax
  80093b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80093f:	eb 03                	jmp    800944 <strfind+0xf>
  800941:	83 c0 01             	add    $0x1,%eax
  800944:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800947:	38 ca                	cmp    %cl,%dl
  800949:	74 04                	je     80094f <strfind+0x1a>
  80094b:	84 d2                	test   %dl,%dl
  80094d:	75 f2                	jne    800941 <strfind+0xc>
			break;
	return (char *) s;
}
  80094f:	5d                   	pop    %ebp
  800950:	c3                   	ret    

00800951 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800951:	55                   	push   %ebp
  800952:	89 e5                	mov    %esp,%ebp
  800954:	57                   	push   %edi
  800955:	56                   	push   %esi
  800956:	53                   	push   %ebx
  800957:	8b 7d 08             	mov    0x8(%ebp),%edi
  80095a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80095d:	85 c9                	test   %ecx,%ecx
  80095f:	74 36                	je     800997 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800961:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800967:	75 28                	jne    800991 <memset+0x40>
  800969:	f6 c1 03             	test   $0x3,%cl
  80096c:	75 23                	jne    800991 <memset+0x40>
		c &= 0xFF;
  80096e:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800972:	89 d3                	mov    %edx,%ebx
  800974:	c1 e3 08             	shl    $0x8,%ebx
  800977:	89 d6                	mov    %edx,%esi
  800979:	c1 e6 18             	shl    $0x18,%esi
  80097c:	89 d0                	mov    %edx,%eax
  80097e:	c1 e0 10             	shl    $0x10,%eax
  800981:	09 f0                	or     %esi,%eax
  800983:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800985:	89 d8                	mov    %ebx,%eax
  800987:	09 d0                	or     %edx,%eax
  800989:	c1 e9 02             	shr    $0x2,%ecx
  80098c:	fc                   	cld    
  80098d:	f3 ab                	rep stos %eax,%es:(%edi)
  80098f:	eb 06                	jmp    800997 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800991:	8b 45 0c             	mov    0xc(%ebp),%eax
  800994:	fc                   	cld    
  800995:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800997:	89 f8                	mov    %edi,%eax
  800999:	5b                   	pop    %ebx
  80099a:	5e                   	pop    %esi
  80099b:	5f                   	pop    %edi
  80099c:	5d                   	pop    %ebp
  80099d:	c3                   	ret    

0080099e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80099e:	55                   	push   %ebp
  80099f:	89 e5                	mov    %esp,%ebp
  8009a1:	57                   	push   %edi
  8009a2:	56                   	push   %esi
  8009a3:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a6:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009a9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009ac:	39 c6                	cmp    %eax,%esi
  8009ae:	73 35                	jae    8009e5 <memmove+0x47>
  8009b0:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009b3:	39 d0                	cmp    %edx,%eax
  8009b5:	73 2e                	jae    8009e5 <memmove+0x47>
		s += n;
		d += n;
  8009b7:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009ba:	89 d6                	mov    %edx,%esi
  8009bc:	09 fe                	or     %edi,%esi
  8009be:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009c4:	75 13                	jne    8009d9 <memmove+0x3b>
  8009c6:	f6 c1 03             	test   $0x3,%cl
  8009c9:	75 0e                	jne    8009d9 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009cb:	83 ef 04             	sub    $0x4,%edi
  8009ce:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009d1:	c1 e9 02             	shr    $0x2,%ecx
  8009d4:	fd                   	std    
  8009d5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009d7:	eb 09                	jmp    8009e2 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009d9:	83 ef 01             	sub    $0x1,%edi
  8009dc:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009df:	fd                   	std    
  8009e0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009e2:	fc                   	cld    
  8009e3:	eb 1d                	jmp    800a02 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009e5:	89 f2                	mov    %esi,%edx
  8009e7:	09 c2                	or     %eax,%edx
  8009e9:	f6 c2 03             	test   $0x3,%dl
  8009ec:	75 0f                	jne    8009fd <memmove+0x5f>
  8009ee:	f6 c1 03             	test   $0x3,%cl
  8009f1:	75 0a                	jne    8009fd <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8009f3:	c1 e9 02             	shr    $0x2,%ecx
  8009f6:	89 c7                	mov    %eax,%edi
  8009f8:	fc                   	cld    
  8009f9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009fb:	eb 05                	jmp    800a02 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009fd:	89 c7                	mov    %eax,%edi
  8009ff:	fc                   	cld    
  800a00:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a02:	5e                   	pop    %esi
  800a03:	5f                   	pop    %edi
  800a04:	5d                   	pop    %ebp
  800a05:	c3                   	ret    

00800a06 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a06:	55                   	push   %ebp
  800a07:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a09:	ff 75 10             	pushl  0x10(%ebp)
  800a0c:	ff 75 0c             	pushl  0xc(%ebp)
  800a0f:	ff 75 08             	pushl  0x8(%ebp)
  800a12:	e8 87 ff ff ff       	call   80099e <memmove>
}
  800a17:	c9                   	leave  
  800a18:	c3                   	ret    

00800a19 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a19:	55                   	push   %ebp
  800a1a:	89 e5                	mov    %esp,%ebp
  800a1c:	56                   	push   %esi
  800a1d:	53                   	push   %ebx
  800a1e:	8b 45 08             	mov    0x8(%ebp),%eax
  800a21:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a24:	89 c6                	mov    %eax,%esi
  800a26:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a29:	eb 1a                	jmp    800a45 <memcmp+0x2c>
		if (*s1 != *s2)
  800a2b:	0f b6 08             	movzbl (%eax),%ecx
  800a2e:	0f b6 1a             	movzbl (%edx),%ebx
  800a31:	38 d9                	cmp    %bl,%cl
  800a33:	74 0a                	je     800a3f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a35:	0f b6 c1             	movzbl %cl,%eax
  800a38:	0f b6 db             	movzbl %bl,%ebx
  800a3b:	29 d8                	sub    %ebx,%eax
  800a3d:	eb 0f                	jmp    800a4e <memcmp+0x35>
		s1++, s2++;
  800a3f:	83 c0 01             	add    $0x1,%eax
  800a42:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a45:	39 f0                	cmp    %esi,%eax
  800a47:	75 e2                	jne    800a2b <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a49:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a4e:	5b                   	pop    %ebx
  800a4f:	5e                   	pop    %esi
  800a50:	5d                   	pop    %ebp
  800a51:	c3                   	ret    

00800a52 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a52:	55                   	push   %ebp
  800a53:	89 e5                	mov    %esp,%ebp
  800a55:	53                   	push   %ebx
  800a56:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a59:	89 c1                	mov    %eax,%ecx
  800a5b:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a5e:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a62:	eb 0a                	jmp    800a6e <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a64:	0f b6 10             	movzbl (%eax),%edx
  800a67:	39 da                	cmp    %ebx,%edx
  800a69:	74 07                	je     800a72 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a6b:	83 c0 01             	add    $0x1,%eax
  800a6e:	39 c8                	cmp    %ecx,%eax
  800a70:	72 f2                	jb     800a64 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a72:	5b                   	pop    %ebx
  800a73:	5d                   	pop    %ebp
  800a74:	c3                   	ret    

00800a75 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a75:	55                   	push   %ebp
  800a76:	89 e5                	mov    %esp,%ebp
  800a78:	57                   	push   %edi
  800a79:	56                   	push   %esi
  800a7a:	53                   	push   %ebx
  800a7b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a7e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a81:	eb 03                	jmp    800a86 <strtol+0x11>
		s++;
  800a83:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a86:	0f b6 01             	movzbl (%ecx),%eax
  800a89:	3c 20                	cmp    $0x20,%al
  800a8b:	74 f6                	je     800a83 <strtol+0xe>
  800a8d:	3c 09                	cmp    $0x9,%al
  800a8f:	74 f2                	je     800a83 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a91:	3c 2b                	cmp    $0x2b,%al
  800a93:	75 0a                	jne    800a9f <strtol+0x2a>
		s++;
  800a95:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a98:	bf 00 00 00 00       	mov    $0x0,%edi
  800a9d:	eb 11                	jmp    800ab0 <strtol+0x3b>
  800a9f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800aa4:	3c 2d                	cmp    $0x2d,%al
  800aa6:	75 08                	jne    800ab0 <strtol+0x3b>
		s++, neg = 1;
  800aa8:	83 c1 01             	add    $0x1,%ecx
  800aab:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ab0:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ab6:	75 15                	jne    800acd <strtol+0x58>
  800ab8:	80 39 30             	cmpb   $0x30,(%ecx)
  800abb:	75 10                	jne    800acd <strtol+0x58>
  800abd:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ac1:	75 7c                	jne    800b3f <strtol+0xca>
		s += 2, base = 16;
  800ac3:	83 c1 02             	add    $0x2,%ecx
  800ac6:	bb 10 00 00 00       	mov    $0x10,%ebx
  800acb:	eb 16                	jmp    800ae3 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800acd:	85 db                	test   %ebx,%ebx
  800acf:	75 12                	jne    800ae3 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ad1:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ad6:	80 39 30             	cmpb   $0x30,(%ecx)
  800ad9:	75 08                	jne    800ae3 <strtol+0x6e>
		s++, base = 8;
  800adb:	83 c1 01             	add    $0x1,%ecx
  800ade:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800ae3:	b8 00 00 00 00       	mov    $0x0,%eax
  800ae8:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800aeb:	0f b6 11             	movzbl (%ecx),%edx
  800aee:	8d 72 d0             	lea    -0x30(%edx),%esi
  800af1:	89 f3                	mov    %esi,%ebx
  800af3:	80 fb 09             	cmp    $0x9,%bl
  800af6:	77 08                	ja     800b00 <strtol+0x8b>
			dig = *s - '0';
  800af8:	0f be d2             	movsbl %dl,%edx
  800afb:	83 ea 30             	sub    $0x30,%edx
  800afe:	eb 22                	jmp    800b22 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b00:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b03:	89 f3                	mov    %esi,%ebx
  800b05:	80 fb 19             	cmp    $0x19,%bl
  800b08:	77 08                	ja     800b12 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b0a:	0f be d2             	movsbl %dl,%edx
  800b0d:	83 ea 57             	sub    $0x57,%edx
  800b10:	eb 10                	jmp    800b22 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b12:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b15:	89 f3                	mov    %esi,%ebx
  800b17:	80 fb 19             	cmp    $0x19,%bl
  800b1a:	77 16                	ja     800b32 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b1c:	0f be d2             	movsbl %dl,%edx
  800b1f:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b22:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b25:	7d 0b                	jge    800b32 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b27:	83 c1 01             	add    $0x1,%ecx
  800b2a:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b2e:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b30:	eb b9                	jmp    800aeb <strtol+0x76>

	if (endptr)
  800b32:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b36:	74 0d                	je     800b45 <strtol+0xd0>
		*endptr = (char *) s;
  800b38:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b3b:	89 0e                	mov    %ecx,(%esi)
  800b3d:	eb 06                	jmp    800b45 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b3f:	85 db                	test   %ebx,%ebx
  800b41:	74 98                	je     800adb <strtol+0x66>
  800b43:	eb 9e                	jmp    800ae3 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b45:	89 c2                	mov    %eax,%edx
  800b47:	f7 da                	neg    %edx
  800b49:	85 ff                	test   %edi,%edi
  800b4b:	0f 45 c2             	cmovne %edx,%eax
}
  800b4e:	5b                   	pop    %ebx
  800b4f:	5e                   	pop    %esi
  800b50:	5f                   	pop    %edi
  800b51:	5d                   	pop    %ebp
  800b52:	c3                   	ret    
  800b53:	66 90                	xchg   %ax,%ax
  800b55:	66 90                	xchg   %ax,%ax
  800b57:	66 90                	xchg   %ax,%ax
  800b59:	66 90                	xchg   %ax,%ax
  800b5b:	66 90                	xchg   %ax,%ax
  800b5d:	66 90                	xchg   %ax,%ax
  800b5f:	90                   	nop

00800b60 <__udivdi3>:
  800b60:	55                   	push   %ebp
  800b61:	57                   	push   %edi
  800b62:	56                   	push   %esi
  800b63:	53                   	push   %ebx
  800b64:	83 ec 1c             	sub    $0x1c,%esp
  800b67:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b6b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b6f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b73:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b77:	85 f6                	test   %esi,%esi
  800b79:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b7d:	89 ca                	mov    %ecx,%edx
  800b7f:	89 f8                	mov    %edi,%eax
  800b81:	75 3d                	jne    800bc0 <__udivdi3+0x60>
  800b83:	39 cf                	cmp    %ecx,%edi
  800b85:	0f 87 c5 00 00 00    	ja     800c50 <__udivdi3+0xf0>
  800b8b:	85 ff                	test   %edi,%edi
  800b8d:	89 fd                	mov    %edi,%ebp
  800b8f:	75 0b                	jne    800b9c <__udivdi3+0x3c>
  800b91:	b8 01 00 00 00       	mov    $0x1,%eax
  800b96:	31 d2                	xor    %edx,%edx
  800b98:	f7 f7                	div    %edi
  800b9a:	89 c5                	mov    %eax,%ebp
  800b9c:	89 c8                	mov    %ecx,%eax
  800b9e:	31 d2                	xor    %edx,%edx
  800ba0:	f7 f5                	div    %ebp
  800ba2:	89 c1                	mov    %eax,%ecx
  800ba4:	89 d8                	mov    %ebx,%eax
  800ba6:	89 cf                	mov    %ecx,%edi
  800ba8:	f7 f5                	div    %ebp
  800baa:	89 c3                	mov    %eax,%ebx
  800bac:	89 d8                	mov    %ebx,%eax
  800bae:	89 fa                	mov    %edi,%edx
  800bb0:	83 c4 1c             	add    $0x1c,%esp
  800bb3:	5b                   	pop    %ebx
  800bb4:	5e                   	pop    %esi
  800bb5:	5f                   	pop    %edi
  800bb6:	5d                   	pop    %ebp
  800bb7:	c3                   	ret    
  800bb8:	90                   	nop
  800bb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bc0:	39 ce                	cmp    %ecx,%esi
  800bc2:	77 74                	ja     800c38 <__udivdi3+0xd8>
  800bc4:	0f bd fe             	bsr    %esi,%edi
  800bc7:	83 f7 1f             	xor    $0x1f,%edi
  800bca:	0f 84 98 00 00 00    	je     800c68 <__udivdi3+0x108>
  800bd0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800bd5:	89 f9                	mov    %edi,%ecx
  800bd7:	89 c5                	mov    %eax,%ebp
  800bd9:	29 fb                	sub    %edi,%ebx
  800bdb:	d3 e6                	shl    %cl,%esi
  800bdd:	89 d9                	mov    %ebx,%ecx
  800bdf:	d3 ed                	shr    %cl,%ebp
  800be1:	89 f9                	mov    %edi,%ecx
  800be3:	d3 e0                	shl    %cl,%eax
  800be5:	09 ee                	or     %ebp,%esi
  800be7:	89 d9                	mov    %ebx,%ecx
  800be9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bed:	89 d5                	mov    %edx,%ebp
  800bef:	8b 44 24 08          	mov    0x8(%esp),%eax
  800bf3:	d3 ed                	shr    %cl,%ebp
  800bf5:	89 f9                	mov    %edi,%ecx
  800bf7:	d3 e2                	shl    %cl,%edx
  800bf9:	89 d9                	mov    %ebx,%ecx
  800bfb:	d3 e8                	shr    %cl,%eax
  800bfd:	09 c2                	or     %eax,%edx
  800bff:	89 d0                	mov    %edx,%eax
  800c01:	89 ea                	mov    %ebp,%edx
  800c03:	f7 f6                	div    %esi
  800c05:	89 d5                	mov    %edx,%ebp
  800c07:	89 c3                	mov    %eax,%ebx
  800c09:	f7 64 24 0c          	mull   0xc(%esp)
  800c0d:	39 d5                	cmp    %edx,%ebp
  800c0f:	72 10                	jb     800c21 <__udivdi3+0xc1>
  800c11:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c15:	89 f9                	mov    %edi,%ecx
  800c17:	d3 e6                	shl    %cl,%esi
  800c19:	39 c6                	cmp    %eax,%esi
  800c1b:	73 07                	jae    800c24 <__udivdi3+0xc4>
  800c1d:	39 d5                	cmp    %edx,%ebp
  800c1f:	75 03                	jne    800c24 <__udivdi3+0xc4>
  800c21:	83 eb 01             	sub    $0x1,%ebx
  800c24:	31 ff                	xor    %edi,%edi
  800c26:	89 d8                	mov    %ebx,%eax
  800c28:	89 fa                	mov    %edi,%edx
  800c2a:	83 c4 1c             	add    $0x1c,%esp
  800c2d:	5b                   	pop    %ebx
  800c2e:	5e                   	pop    %esi
  800c2f:	5f                   	pop    %edi
  800c30:	5d                   	pop    %ebp
  800c31:	c3                   	ret    
  800c32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c38:	31 ff                	xor    %edi,%edi
  800c3a:	31 db                	xor    %ebx,%ebx
  800c3c:	89 d8                	mov    %ebx,%eax
  800c3e:	89 fa                	mov    %edi,%edx
  800c40:	83 c4 1c             	add    $0x1c,%esp
  800c43:	5b                   	pop    %ebx
  800c44:	5e                   	pop    %esi
  800c45:	5f                   	pop    %edi
  800c46:	5d                   	pop    %ebp
  800c47:	c3                   	ret    
  800c48:	90                   	nop
  800c49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c50:	89 d8                	mov    %ebx,%eax
  800c52:	f7 f7                	div    %edi
  800c54:	31 ff                	xor    %edi,%edi
  800c56:	89 c3                	mov    %eax,%ebx
  800c58:	89 d8                	mov    %ebx,%eax
  800c5a:	89 fa                	mov    %edi,%edx
  800c5c:	83 c4 1c             	add    $0x1c,%esp
  800c5f:	5b                   	pop    %ebx
  800c60:	5e                   	pop    %esi
  800c61:	5f                   	pop    %edi
  800c62:	5d                   	pop    %ebp
  800c63:	c3                   	ret    
  800c64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c68:	39 ce                	cmp    %ecx,%esi
  800c6a:	72 0c                	jb     800c78 <__udivdi3+0x118>
  800c6c:	31 db                	xor    %ebx,%ebx
  800c6e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c72:	0f 87 34 ff ff ff    	ja     800bac <__udivdi3+0x4c>
  800c78:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c7d:	e9 2a ff ff ff       	jmp    800bac <__udivdi3+0x4c>
  800c82:	66 90                	xchg   %ax,%ax
  800c84:	66 90                	xchg   %ax,%ax
  800c86:	66 90                	xchg   %ax,%ax
  800c88:	66 90                	xchg   %ax,%ax
  800c8a:	66 90                	xchg   %ax,%ax
  800c8c:	66 90                	xchg   %ax,%ax
  800c8e:	66 90                	xchg   %ax,%ax

00800c90 <__umoddi3>:
  800c90:	55                   	push   %ebp
  800c91:	57                   	push   %edi
  800c92:	56                   	push   %esi
  800c93:	53                   	push   %ebx
  800c94:	83 ec 1c             	sub    $0x1c,%esp
  800c97:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c9b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c9f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800ca3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800ca7:	85 d2                	test   %edx,%edx
  800ca9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800cad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800cb1:	89 f3                	mov    %esi,%ebx
  800cb3:	89 3c 24             	mov    %edi,(%esp)
  800cb6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cba:	75 1c                	jne    800cd8 <__umoddi3+0x48>
  800cbc:	39 f7                	cmp    %esi,%edi
  800cbe:	76 50                	jbe    800d10 <__umoddi3+0x80>
  800cc0:	89 c8                	mov    %ecx,%eax
  800cc2:	89 f2                	mov    %esi,%edx
  800cc4:	f7 f7                	div    %edi
  800cc6:	89 d0                	mov    %edx,%eax
  800cc8:	31 d2                	xor    %edx,%edx
  800cca:	83 c4 1c             	add    $0x1c,%esp
  800ccd:	5b                   	pop    %ebx
  800cce:	5e                   	pop    %esi
  800ccf:	5f                   	pop    %edi
  800cd0:	5d                   	pop    %ebp
  800cd1:	c3                   	ret    
  800cd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cd8:	39 f2                	cmp    %esi,%edx
  800cda:	89 d0                	mov    %edx,%eax
  800cdc:	77 52                	ja     800d30 <__umoddi3+0xa0>
  800cde:	0f bd ea             	bsr    %edx,%ebp
  800ce1:	83 f5 1f             	xor    $0x1f,%ebp
  800ce4:	75 5a                	jne    800d40 <__umoddi3+0xb0>
  800ce6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800cea:	0f 82 e0 00 00 00    	jb     800dd0 <__umoddi3+0x140>
  800cf0:	39 0c 24             	cmp    %ecx,(%esp)
  800cf3:	0f 86 d7 00 00 00    	jbe    800dd0 <__umoddi3+0x140>
  800cf9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800cfd:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d01:	83 c4 1c             	add    $0x1c,%esp
  800d04:	5b                   	pop    %ebx
  800d05:	5e                   	pop    %esi
  800d06:	5f                   	pop    %edi
  800d07:	5d                   	pop    %ebp
  800d08:	c3                   	ret    
  800d09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d10:	85 ff                	test   %edi,%edi
  800d12:	89 fd                	mov    %edi,%ebp
  800d14:	75 0b                	jne    800d21 <__umoddi3+0x91>
  800d16:	b8 01 00 00 00       	mov    $0x1,%eax
  800d1b:	31 d2                	xor    %edx,%edx
  800d1d:	f7 f7                	div    %edi
  800d1f:	89 c5                	mov    %eax,%ebp
  800d21:	89 f0                	mov    %esi,%eax
  800d23:	31 d2                	xor    %edx,%edx
  800d25:	f7 f5                	div    %ebp
  800d27:	89 c8                	mov    %ecx,%eax
  800d29:	f7 f5                	div    %ebp
  800d2b:	89 d0                	mov    %edx,%eax
  800d2d:	eb 99                	jmp    800cc8 <__umoddi3+0x38>
  800d2f:	90                   	nop
  800d30:	89 c8                	mov    %ecx,%eax
  800d32:	89 f2                	mov    %esi,%edx
  800d34:	83 c4 1c             	add    $0x1c,%esp
  800d37:	5b                   	pop    %ebx
  800d38:	5e                   	pop    %esi
  800d39:	5f                   	pop    %edi
  800d3a:	5d                   	pop    %ebp
  800d3b:	c3                   	ret    
  800d3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d40:	8b 34 24             	mov    (%esp),%esi
  800d43:	bf 20 00 00 00       	mov    $0x20,%edi
  800d48:	89 e9                	mov    %ebp,%ecx
  800d4a:	29 ef                	sub    %ebp,%edi
  800d4c:	d3 e0                	shl    %cl,%eax
  800d4e:	89 f9                	mov    %edi,%ecx
  800d50:	89 f2                	mov    %esi,%edx
  800d52:	d3 ea                	shr    %cl,%edx
  800d54:	89 e9                	mov    %ebp,%ecx
  800d56:	09 c2                	or     %eax,%edx
  800d58:	89 d8                	mov    %ebx,%eax
  800d5a:	89 14 24             	mov    %edx,(%esp)
  800d5d:	89 f2                	mov    %esi,%edx
  800d5f:	d3 e2                	shl    %cl,%edx
  800d61:	89 f9                	mov    %edi,%ecx
  800d63:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d67:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d6b:	d3 e8                	shr    %cl,%eax
  800d6d:	89 e9                	mov    %ebp,%ecx
  800d6f:	89 c6                	mov    %eax,%esi
  800d71:	d3 e3                	shl    %cl,%ebx
  800d73:	89 f9                	mov    %edi,%ecx
  800d75:	89 d0                	mov    %edx,%eax
  800d77:	d3 e8                	shr    %cl,%eax
  800d79:	89 e9                	mov    %ebp,%ecx
  800d7b:	09 d8                	or     %ebx,%eax
  800d7d:	89 d3                	mov    %edx,%ebx
  800d7f:	89 f2                	mov    %esi,%edx
  800d81:	f7 34 24             	divl   (%esp)
  800d84:	89 d6                	mov    %edx,%esi
  800d86:	d3 e3                	shl    %cl,%ebx
  800d88:	f7 64 24 04          	mull   0x4(%esp)
  800d8c:	39 d6                	cmp    %edx,%esi
  800d8e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d92:	89 d1                	mov    %edx,%ecx
  800d94:	89 c3                	mov    %eax,%ebx
  800d96:	72 08                	jb     800da0 <__umoddi3+0x110>
  800d98:	75 11                	jne    800dab <__umoddi3+0x11b>
  800d9a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d9e:	73 0b                	jae    800dab <__umoddi3+0x11b>
  800da0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800da4:	1b 14 24             	sbb    (%esp),%edx
  800da7:	89 d1                	mov    %edx,%ecx
  800da9:	89 c3                	mov    %eax,%ebx
  800dab:	8b 54 24 08          	mov    0x8(%esp),%edx
  800daf:	29 da                	sub    %ebx,%edx
  800db1:	19 ce                	sbb    %ecx,%esi
  800db3:	89 f9                	mov    %edi,%ecx
  800db5:	89 f0                	mov    %esi,%eax
  800db7:	d3 e0                	shl    %cl,%eax
  800db9:	89 e9                	mov    %ebp,%ecx
  800dbb:	d3 ea                	shr    %cl,%edx
  800dbd:	89 e9                	mov    %ebp,%ecx
  800dbf:	d3 ee                	shr    %cl,%esi
  800dc1:	09 d0                	or     %edx,%eax
  800dc3:	89 f2                	mov    %esi,%edx
  800dc5:	83 c4 1c             	add    $0x1c,%esp
  800dc8:	5b                   	pop    %ebx
  800dc9:	5e                   	pop    %esi
  800dca:	5f                   	pop    %edi
  800dcb:	5d                   	pop    %ebp
  800dcc:	c3                   	ret    
  800dcd:	8d 76 00             	lea    0x0(%esi),%esi
  800dd0:	29 f9                	sub    %edi,%ecx
  800dd2:	19 d6                	sbb    %edx,%esi
  800dd4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800dd8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ddc:	e9 18 ff ff ff       	jmp    800cf9 <__umoddi3+0x69>
