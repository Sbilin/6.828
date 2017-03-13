
obj/user/faultwritekernel:     file format elf32-i386


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
  80002c:	e8 11 00 00 00       	call   800042 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	*(unsigned*)0xf0100000 = 0;
  800036:	c7 05 00 00 10 f0 00 	movl   $0x0,0xf0100000
  80003d:	00 00 00 
}
  800040:	5d                   	pop    %ebp
  800041:	c3                   	ret    

00800042 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800042:	55                   	push   %ebp
  800043:	89 e5                	mov    %esp,%ebp
  800045:	83 ec 08             	sub    $0x8,%esp
  800048:	8b 45 08             	mov    0x8(%ebp),%eax
  80004b:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80004e:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800055:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800058:	85 c0                	test   %eax,%eax
  80005a:	7e 08                	jle    800064 <libmain+0x22>
		binaryname = argv[0];
  80005c:	8b 0a                	mov    (%edx),%ecx
  80005e:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800064:	83 ec 08             	sub    $0x8,%esp
  800067:	52                   	push   %edx
  800068:	50                   	push   %eax
  800069:	e8 c5 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80006e:	e8 05 00 00 00       	call   800078 <exit>
}
  800073:	83 c4 10             	add    $0x10,%esp
  800076:	c9                   	leave  
  800077:	c3                   	ret    

00800078 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800078:	55                   	push   %ebp
  800079:	89 e5                	mov    %esp,%ebp
  80007b:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80007e:	6a 00                	push   $0x0
  800080:	e8 42 00 00 00       	call   8000c7 <sys_env_destroy>
}
  800085:	83 c4 10             	add    $0x10,%esp
  800088:	c9                   	leave  
  800089:	c3                   	ret    

0080008a <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  80008a:	55                   	push   %ebp
  80008b:	89 e5                	mov    %esp,%ebp
  80008d:	57                   	push   %edi
  80008e:	56                   	push   %esi
  80008f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800090:	b8 00 00 00 00       	mov    $0x0,%eax
  800095:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800098:	8b 55 08             	mov    0x8(%ebp),%edx
  80009b:	89 c3                	mov    %eax,%ebx
  80009d:	89 c7                	mov    %eax,%edi
  80009f:	89 c6                	mov    %eax,%esi
  8000a1:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000a3:	5b                   	pop    %ebx
  8000a4:	5e                   	pop    %esi
  8000a5:	5f                   	pop    %edi
  8000a6:	5d                   	pop    %ebp
  8000a7:	c3                   	ret    

008000a8 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000a8:	55                   	push   %ebp
  8000a9:	89 e5                	mov    %esp,%ebp
  8000ab:	57                   	push   %edi
  8000ac:	56                   	push   %esi
  8000ad:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000ae:	ba 00 00 00 00       	mov    $0x0,%edx
  8000b3:	b8 01 00 00 00       	mov    $0x1,%eax
  8000b8:	89 d1                	mov    %edx,%ecx
  8000ba:	89 d3                	mov    %edx,%ebx
  8000bc:	89 d7                	mov    %edx,%edi
  8000be:	89 d6                	mov    %edx,%esi
  8000c0:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000c2:	5b                   	pop    %ebx
  8000c3:	5e                   	pop    %esi
  8000c4:	5f                   	pop    %edi
  8000c5:	5d                   	pop    %ebp
  8000c6:	c3                   	ret    

008000c7 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000c7:	55                   	push   %ebp
  8000c8:	89 e5                	mov    %esp,%ebp
  8000ca:	57                   	push   %edi
  8000cb:	56                   	push   %esi
  8000cc:	53                   	push   %ebx
  8000cd:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000d5:	b8 03 00 00 00       	mov    $0x3,%eax
  8000da:	8b 55 08             	mov    0x8(%ebp),%edx
  8000dd:	89 cb                	mov    %ecx,%ebx
  8000df:	89 cf                	mov    %ecx,%edi
  8000e1:	89 ce                	mov    %ecx,%esi
  8000e3:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000e5:	85 c0                	test   %eax,%eax
  8000e7:	7e 17                	jle    800100 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000e9:	83 ec 0c             	sub    $0xc,%esp
  8000ec:	50                   	push   %eax
  8000ed:	6a 03                	push   $0x3
  8000ef:	68 de 0d 80 00       	push   $0x800dde
  8000f4:	6a 23                	push   $0x23
  8000f6:	68 fb 0d 80 00       	push   $0x800dfb
  8000fb:	e8 27 00 00 00       	call   800127 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800100:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800103:	5b                   	pop    %ebx
  800104:	5e                   	pop    %esi
  800105:	5f                   	pop    %edi
  800106:	5d                   	pop    %ebp
  800107:	c3                   	ret    

00800108 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800108:	55                   	push   %ebp
  800109:	89 e5                	mov    %esp,%ebp
  80010b:	57                   	push   %edi
  80010c:	56                   	push   %esi
  80010d:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80010e:	ba 00 00 00 00       	mov    $0x0,%edx
  800113:	b8 02 00 00 00       	mov    $0x2,%eax
  800118:	89 d1                	mov    %edx,%ecx
  80011a:	89 d3                	mov    %edx,%ebx
  80011c:	89 d7                	mov    %edx,%edi
  80011e:	89 d6                	mov    %edx,%esi
  800120:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800122:	5b                   	pop    %ebx
  800123:	5e                   	pop    %esi
  800124:	5f                   	pop    %edi
  800125:	5d                   	pop    %ebp
  800126:	c3                   	ret    

00800127 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800127:	55                   	push   %ebp
  800128:	89 e5                	mov    %esp,%ebp
  80012a:	56                   	push   %esi
  80012b:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80012c:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80012f:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800135:	e8 ce ff ff ff       	call   800108 <sys_getenvid>
  80013a:	83 ec 0c             	sub    $0xc,%esp
  80013d:	ff 75 0c             	pushl  0xc(%ebp)
  800140:	ff 75 08             	pushl  0x8(%ebp)
  800143:	56                   	push   %esi
  800144:	50                   	push   %eax
  800145:	68 0c 0e 80 00       	push   $0x800e0c
  80014a:	e8 b1 00 00 00       	call   800200 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80014f:	83 c4 18             	add    $0x18,%esp
  800152:	53                   	push   %ebx
  800153:	ff 75 10             	pushl  0x10(%ebp)
  800156:	e8 54 00 00 00       	call   8001af <vcprintf>
	cprintf("\n");
  80015b:	c7 04 24 30 0e 80 00 	movl   $0x800e30,(%esp)
  800162:	e8 99 00 00 00       	call   800200 <cprintf>
  800167:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80016a:	cc                   	int3   
  80016b:	eb fd                	jmp    80016a <_panic+0x43>

0080016d <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80016d:	55                   	push   %ebp
  80016e:	89 e5                	mov    %esp,%ebp
  800170:	53                   	push   %ebx
  800171:	83 ec 04             	sub    $0x4,%esp
  800174:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800177:	8b 13                	mov    (%ebx),%edx
  800179:	8d 42 01             	lea    0x1(%edx),%eax
  80017c:	89 03                	mov    %eax,(%ebx)
  80017e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800181:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800185:	3d ff 00 00 00       	cmp    $0xff,%eax
  80018a:	75 1a                	jne    8001a6 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  80018c:	83 ec 08             	sub    $0x8,%esp
  80018f:	68 ff 00 00 00       	push   $0xff
  800194:	8d 43 08             	lea    0x8(%ebx),%eax
  800197:	50                   	push   %eax
  800198:	e8 ed fe ff ff       	call   80008a <sys_cputs>
		b->idx = 0;
  80019d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001a3:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001a6:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001aa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001ad:	c9                   	leave  
  8001ae:	c3                   	ret    

008001af <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001af:	55                   	push   %ebp
  8001b0:	89 e5                	mov    %esp,%ebp
  8001b2:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001b8:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001bf:	00 00 00 
	b.cnt = 0;
  8001c2:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001c9:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001cc:	ff 75 0c             	pushl  0xc(%ebp)
  8001cf:	ff 75 08             	pushl  0x8(%ebp)
  8001d2:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001d8:	50                   	push   %eax
  8001d9:	68 6d 01 80 00       	push   $0x80016d
  8001de:	e8 1a 01 00 00       	call   8002fd <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001e3:	83 c4 08             	add    $0x8,%esp
  8001e6:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001ec:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001f2:	50                   	push   %eax
  8001f3:	e8 92 fe ff ff       	call   80008a <sys_cputs>

	return b.cnt;
}
  8001f8:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001fe:	c9                   	leave  
  8001ff:	c3                   	ret    

00800200 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800200:	55                   	push   %ebp
  800201:	89 e5                	mov    %esp,%ebp
  800203:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800206:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800209:	50                   	push   %eax
  80020a:	ff 75 08             	pushl  0x8(%ebp)
  80020d:	e8 9d ff ff ff       	call   8001af <vcprintf>
	va_end(ap);

	return cnt;
}
  800212:	c9                   	leave  
  800213:	c3                   	ret    

00800214 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800214:	55                   	push   %ebp
  800215:	89 e5                	mov    %esp,%ebp
  800217:	57                   	push   %edi
  800218:	56                   	push   %esi
  800219:	53                   	push   %ebx
  80021a:	83 ec 1c             	sub    $0x1c,%esp
  80021d:	89 c7                	mov    %eax,%edi
  80021f:	89 d6                	mov    %edx,%esi
  800221:	8b 45 08             	mov    0x8(%ebp),%eax
  800224:	8b 55 0c             	mov    0xc(%ebp),%edx
  800227:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80022a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80022d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800230:	bb 00 00 00 00       	mov    $0x0,%ebx
  800235:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800238:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80023b:	39 d3                	cmp    %edx,%ebx
  80023d:	72 05                	jb     800244 <printnum+0x30>
  80023f:	39 45 10             	cmp    %eax,0x10(%ebp)
  800242:	77 45                	ja     800289 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800244:	83 ec 0c             	sub    $0xc,%esp
  800247:	ff 75 18             	pushl  0x18(%ebp)
  80024a:	8b 45 14             	mov    0x14(%ebp),%eax
  80024d:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800250:	53                   	push   %ebx
  800251:	ff 75 10             	pushl  0x10(%ebp)
  800254:	83 ec 08             	sub    $0x8,%esp
  800257:	ff 75 e4             	pushl  -0x1c(%ebp)
  80025a:	ff 75 e0             	pushl  -0x20(%ebp)
  80025d:	ff 75 dc             	pushl  -0x24(%ebp)
  800260:	ff 75 d8             	pushl  -0x28(%ebp)
  800263:	e8 e8 08 00 00       	call   800b50 <__udivdi3>
  800268:	83 c4 18             	add    $0x18,%esp
  80026b:	52                   	push   %edx
  80026c:	50                   	push   %eax
  80026d:	89 f2                	mov    %esi,%edx
  80026f:	89 f8                	mov    %edi,%eax
  800271:	e8 9e ff ff ff       	call   800214 <printnum>
  800276:	83 c4 20             	add    $0x20,%esp
  800279:	eb 18                	jmp    800293 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80027b:	83 ec 08             	sub    $0x8,%esp
  80027e:	56                   	push   %esi
  80027f:	ff 75 18             	pushl  0x18(%ebp)
  800282:	ff d7                	call   *%edi
  800284:	83 c4 10             	add    $0x10,%esp
  800287:	eb 03                	jmp    80028c <printnum+0x78>
  800289:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80028c:	83 eb 01             	sub    $0x1,%ebx
  80028f:	85 db                	test   %ebx,%ebx
  800291:	7f e8                	jg     80027b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800293:	83 ec 08             	sub    $0x8,%esp
  800296:	56                   	push   %esi
  800297:	83 ec 04             	sub    $0x4,%esp
  80029a:	ff 75 e4             	pushl  -0x1c(%ebp)
  80029d:	ff 75 e0             	pushl  -0x20(%ebp)
  8002a0:	ff 75 dc             	pushl  -0x24(%ebp)
  8002a3:	ff 75 d8             	pushl  -0x28(%ebp)
  8002a6:	e8 d5 09 00 00       	call   800c80 <__umoddi3>
  8002ab:	83 c4 14             	add    $0x14,%esp
  8002ae:	0f be 80 32 0e 80 00 	movsbl 0x800e32(%eax),%eax
  8002b5:	50                   	push   %eax
  8002b6:	ff d7                	call   *%edi
}
  8002b8:	83 c4 10             	add    $0x10,%esp
  8002bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002be:	5b                   	pop    %ebx
  8002bf:	5e                   	pop    %esi
  8002c0:	5f                   	pop    %edi
  8002c1:	5d                   	pop    %ebp
  8002c2:	c3                   	ret    

008002c3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002c3:	55                   	push   %ebp
  8002c4:	89 e5                	mov    %esp,%ebp
  8002c6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002c9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002cd:	8b 10                	mov    (%eax),%edx
  8002cf:	3b 50 04             	cmp    0x4(%eax),%edx
  8002d2:	73 0a                	jae    8002de <sprintputch+0x1b>
		*b->buf++ = ch;
  8002d4:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002d7:	89 08                	mov    %ecx,(%eax)
  8002d9:	8b 45 08             	mov    0x8(%ebp),%eax
  8002dc:	88 02                	mov    %al,(%edx)
}
  8002de:	5d                   	pop    %ebp
  8002df:	c3                   	ret    

008002e0 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002e0:	55                   	push   %ebp
  8002e1:	89 e5                	mov    %esp,%ebp
  8002e3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002e6:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002e9:	50                   	push   %eax
  8002ea:	ff 75 10             	pushl  0x10(%ebp)
  8002ed:	ff 75 0c             	pushl  0xc(%ebp)
  8002f0:	ff 75 08             	pushl  0x8(%ebp)
  8002f3:	e8 05 00 00 00       	call   8002fd <vprintfmt>
	va_end(ap);
}
  8002f8:	83 c4 10             	add    $0x10,%esp
  8002fb:	c9                   	leave  
  8002fc:	c3                   	ret    

008002fd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002fd:	55                   	push   %ebp
  8002fe:	89 e5                	mov    %esp,%ebp
  800300:	57                   	push   %edi
  800301:	56                   	push   %esi
  800302:	53                   	push   %ebx
  800303:	83 ec 2c             	sub    $0x2c,%esp
  800306:	8b 75 08             	mov    0x8(%ebp),%esi
  800309:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80030c:	8b 7d 10             	mov    0x10(%ebp),%edi
  80030f:	eb 12                	jmp    800323 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800311:	85 c0                	test   %eax,%eax
  800313:	0f 84 42 04 00 00    	je     80075b <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800319:	83 ec 08             	sub    $0x8,%esp
  80031c:	53                   	push   %ebx
  80031d:	50                   	push   %eax
  80031e:	ff d6                	call   *%esi
  800320:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800323:	83 c7 01             	add    $0x1,%edi
  800326:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80032a:	83 f8 25             	cmp    $0x25,%eax
  80032d:	75 e2                	jne    800311 <vprintfmt+0x14>
  80032f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800333:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80033a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800341:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800348:	b9 00 00 00 00       	mov    $0x0,%ecx
  80034d:	eb 07                	jmp    800356 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800352:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800356:	8d 47 01             	lea    0x1(%edi),%eax
  800359:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80035c:	0f b6 07             	movzbl (%edi),%eax
  80035f:	0f b6 d0             	movzbl %al,%edx
  800362:	83 e8 23             	sub    $0x23,%eax
  800365:	3c 55                	cmp    $0x55,%al
  800367:	0f 87 d3 03 00 00    	ja     800740 <vprintfmt+0x443>
  80036d:	0f b6 c0             	movzbl %al,%eax
  800370:	ff 24 85 c0 0e 80 00 	jmp    *0x800ec0(,%eax,4)
  800377:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80037a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80037e:	eb d6                	jmp    800356 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800380:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800383:	b8 00 00 00 00       	mov    $0x0,%eax
  800388:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80038b:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80038e:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800392:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800395:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800398:	83 f9 09             	cmp    $0x9,%ecx
  80039b:	77 3f                	ja     8003dc <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80039d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003a0:	eb e9                	jmp    80038b <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003a2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a5:	8b 00                	mov    (%eax),%eax
  8003a7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003aa:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ad:	8d 40 04             	lea    0x4(%eax),%eax
  8003b0:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003b6:	eb 2a                	jmp    8003e2 <vprintfmt+0xe5>
  8003b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003bb:	85 c0                	test   %eax,%eax
  8003bd:	ba 00 00 00 00       	mov    $0x0,%edx
  8003c2:	0f 49 d0             	cmovns %eax,%edx
  8003c5:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003cb:	eb 89                	jmp    800356 <vprintfmt+0x59>
  8003cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003d0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003d7:	e9 7a ff ff ff       	jmp    800356 <vprintfmt+0x59>
  8003dc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003df:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8003e2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003e6:	0f 89 6a ff ff ff    	jns    800356 <vprintfmt+0x59>
				width = precision, precision = -1;
  8003ec:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003ef:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003f2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003f9:	e9 58 ff ff ff       	jmp    800356 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003fe:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800401:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800404:	e9 4d ff ff ff       	jmp    800356 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800409:	8b 45 14             	mov    0x14(%ebp),%eax
  80040c:	8d 78 04             	lea    0x4(%eax),%edi
  80040f:	83 ec 08             	sub    $0x8,%esp
  800412:	53                   	push   %ebx
  800413:	ff 30                	pushl  (%eax)
  800415:	ff d6                	call   *%esi
			break;
  800417:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80041a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80041d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800420:	e9 fe fe ff ff       	jmp    800323 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800425:	8b 45 14             	mov    0x14(%ebp),%eax
  800428:	8d 78 04             	lea    0x4(%eax),%edi
  80042b:	8b 00                	mov    (%eax),%eax
  80042d:	99                   	cltd   
  80042e:	31 d0                	xor    %edx,%eax
  800430:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800432:	83 f8 06             	cmp    $0x6,%eax
  800435:	7f 0b                	jg     800442 <vprintfmt+0x145>
  800437:	8b 14 85 18 10 80 00 	mov    0x801018(,%eax,4),%edx
  80043e:	85 d2                	test   %edx,%edx
  800440:	75 1b                	jne    80045d <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800442:	50                   	push   %eax
  800443:	68 4a 0e 80 00       	push   $0x800e4a
  800448:	53                   	push   %ebx
  800449:	56                   	push   %esi
  80044a:	e8 91 fe ff ff       	call   8002e0 <printfmt>
  80044f:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800452:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800455:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800458:	e9 c6 fe ff ff       	jmp    800323 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80045d:	52                   	push   %edx
  80045e:	68 53 0e 80 00       	push   $0x800e53
  800463:	53                   	push   %ebx
  800464:	56                   	push   %esi
  800465:	e8 76 fe ff ff       	call   8002e0 <printfmt>
  80046a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80046d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800470:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800473:	e9 ab fe ff ff       	jmp    800323 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800478:	8b 45 14             	mov    0x14(%ebp),%eax
  80047b:	83 c0 04             	add    $0x4,%eax
  80047e:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800481:	8b 45 14             	mov    0x14(%ebp),%eax
  800484:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800486:	85 ff                	test   %edi,%edi
  800488:	b8 43 0e 80 00       	mov    $0x800e43,%eax
  80048d:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800490:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800494:	0f 8e 94 00 00 00    	jle    80052e <vprintfmt+0x231>
  80049a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80049e:	0f 84 98 00 00 00    	je     80053c <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004a4:	83 ec 08             	sub    $0x8,%esp
  8004a7:	ff 75 d0             	pushl  -0x30(%ebp)
  8004aa:	57                   	push   %edi
  8004ab:	e8 33 03 00 00       	call   8007e3 <strnlen>
  8004b0:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004b3:	29 c1                	sub    %eax,%ecx
  8004b5:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004b8:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004bb:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004bf:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004c2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004c5:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c7:	eb 0f                	jmp    8004d8 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004c9:	83 ec 08             	sub    $0x8,%esp
  8004cc:	53                   	push   %ebx
  8004cd:	ff 75 e0             	pushl  -0x20(%ebp)
  8004d0:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d2:	83 ef 01             	sub    $0x1,%edi
  8004d5:	83 c4 10             	add    $0x10,%esp
  8004d8:	85 ff                	test   %edi,%edi
  8004da:	7f ed                	jg     8004c9 <vprintfmt+0x1cc>
  8004dc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004df:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004e2:	85 c9                	test   %ecx,%ecx
  8004e4:	b8 00 00 00 00       	mov    $0x0,%eax
  8004e9:	0f 49 c1             	cmovns %ecx,%eax
  8004ec:	29 c1                	sub    %eax,%ecx
  8004ee:	89 75 08             	mov    %esi,0x8(%ebp)
  8004f1:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004f4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004f7:	89 cb                	mov    %ecx,%ebx
  8004f9:	eb 4d                	jmp    800548 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004fb:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004ff:	74 1b                	je     80051c <vprintfmt+0x21f>
  800501:	0f be c0             	movsbl %al,%eax
  800504:	83 e8 20             	sub    $0x20,%eax
  800507:	83 f8 5e             	cmp    $0x5e,%eax
  80050a:	76 10                	jbe    80051c <vprintfmt+0x21f>
					putch('?', putdat);
  80050c:	83 ec 08             	sub    $0x8,%esp
  80050f:	ff 75 0c             	pushl  0xc(%ebp)
  800512:	6a 3f                	push   $0x3f
  800514:	ff 55 08             	call   *0x8(%ebp)
  800517:	83 c4 10             	add    $0x10,%esp
  80051a:	eb 0d                	jmp    800529 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  80051c:	83 ec 08             	sub    $0x8,%esp
  80051f:	ff 75 0c             	pushl  0xc(%ebp)
  800522:	52                   	push   %edx
  800523:	ff 55 08             	call   *0x8(%ebp)
  800526:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800529:	83 eb 01             	sub    $0x1,%ebx
  80052c:	eb 1a                	jmp    800548 <vprintfmt+0x24b>
  80052e:	89 75 08             	mov    %esi,0x8(%ebp)
  800531:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800534:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800537:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80053a:	eb 0c                	jmp    800548 <vprintfmt+0x24b>
  80053c:	89 75 08             	mov    %esi,0x8(%ebp)
  80053f:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800542:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800545:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800548:	83 c7 01             	add    $0x1,%edi
  80054b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80054f:	0f be d0             	movsbl %al,%edx
  800552:	85 d2                	test   %edx,%edx
  800554:	74 23                	je     800579 <vprintfmt+0x27c>
  800556:	85 f6                	test   %esi,%esi
  800558:	78 a1                	js     8004fb <vprintfmt+0x1fe>
  80055a:	83 ee 01             	sub    $0x1,%esi
  80055d:	79 9c                	jns    8004fb <vprintfmt+0x1fe>
  80055f:	89 df                	mov    %ebx,%edi
  800561:	8b 75 08             	mov    0x8(%ebp),%esi
  800564:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800567:	eb 18                	jmp    800581 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800569:	83 ec 08             	sub    $0x8,%esp
  80056c:	53                   	push   %ebx
  80056d:	6a 20                	push   $0x20
  80056f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800571:	83 ef 01             	sub    $0x1,%edi
  800574:	83 c4 10             	add    $0x10,%esp
  800577:	eb 08                	jmp    800581 <vprintfmt+0x284>
  800579:	89 df                	mov    %ebx,%edi
  80057b:	8b 75 08             	mov    0x8(%ebp),%esi
  80057e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800581:	85 ff                	test   %edi,%edi
  800583:	7f e4                	jg     800569 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800585:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800588:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80058b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80058e:	e9 90 fd ff ff       	jmp    800323 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800593:	83 f9 01             	cmp    $0x1,%ecx
  800596:	7e 19                	jle    8005b1 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800598:	8b 45 14             	mov    0x14(%ebp),%eax
  80059b:	8b 50 04             	mov    0x4(%eax),%edx
  80059e:	8b 00                	mov    (%eax),%eax
  8005a0:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005a3:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005a6:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a9:	8d 40 08             	lea    0x8(%eax),%eax
  8005ac:	89 45 14             	mov    %eax,0x14(%ebp)
  8005af:	eb 38                	jmp    8005e9 <vprintfmt+0x2ec>
	else if (lflag)
  8005b1:	85 c9                	test   %ecx,%ecx
  8005b3:	74 1b                	je     8005d0 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005b5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b8:	8b 00                	mov    (%eax),%eax
  8005ba:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005bd:	89 c1                	mov    %eax,%ecx
  8005bf:	c1 f9 1f             	sar    $0x1f,%ecx
  8005c2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c8:	8d 40 04             	lea    0x4(%eax),%eax
  8005cb:	89 45 14             	mov    %eax,0x14(%ebp)
  8005ce:	eb 19                	jmp    8005e9 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005d0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d3:	8b 00                	mov    (%eax),%eax
  8005d5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005d8:	89 c1                	mov    %eax,%ecx
  8005da:	c1 f9 1f             	sar    $0x1f,%ecx
  8005dd:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005e0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e3:	8d 40 04             	lea    0x4(%eax),%eax
  8005e6:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005e9:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005ec:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005ef:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005f4:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005f8:	0f 89 0e 01 00 00    	jns    80070c <vprintfmt+0x40f>
				putch('-', putdat);
  8005fe:	83 ec 08             	sub    $0x8,%esp
  800601:	53                   	push   %ebx
  800602:	6a 2d                	push   $0x2d
  800604:	ff d6                	call   *%esi
				num = -(long long) num;
  800606:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800609:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80060c:	f7 da                	neg    %edx
  80060e:	83 d1 00             	adc    $0x0,%ecx
  800611:	f7 d9                	neg    %ecx
  800613:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800616:	b8 0a 00 00 00       	mov    $0xa,%eax
  80061b:	e9 ec 00 00 00       	jmp    80070c <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800620:	83 f9 01             	cmp    $0x1,%ecx
  800623:	7e 18                	jle    80063d <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800625:	8b 45 14             	mov    0x14(%ebp),%eax
  800628:	8b 10                	mov    (%eax),%edx
  80062a:	8b 48 04             	mov    0x4(%eax),%ecx
  80062d:	8d 40 08             	lea    0x8(%eax),%eax
  800630:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800633:	b8 0a 00 00 00       	mov    $0xa,%eax
  800638:	e9 cf 00 00 00       	jmp    80070c <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80063d:	85 c9                	test   %ecx,%ecx
  80063f:	74 1a                	je     80065b <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800641:	8b 45 14             	mov    0x14(%ebp),%eax
  800644:	8b 10                	mov    (%eax),%edx
  800646:	b9 00 00 00 00       	mov    $0x0,%ecx
  80064b:	8d 40 04             	lea    0x4(%eax),%eax
  80064e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800651:	b8 0a 00 00 00       	mov    $0xa,%eax
  800656:	e9 b1 00 00 00       	jmp    80070c <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80065b:	8b 45 14             	mov    0x14(%ebp),%eax
  80065e:	8b 10                	mov    (%eax),%edx
  800660:	b9 00 00 00 00       	mov    $0x0,%ecx
  800665:	8d 40 04             	lea    0x4(%eax),%eax
  800668:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80066b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800670:	e9 97 00 00 00       	jmp    80070c <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800675:	83 ec 08             	sub    $0x8,%esp
  800678:	53                   	push   %ebx
  800679:	6a 58                	push   $0x58
  80067b:	ff d6                	call   *%esi
			putch('X', putdat);
  80067d:	83 c4 08             	add    $0x8,%esp
  800680:	53                   	push   %ebx
  800681:	6a 58                	push   $0x58
  800683:	ff d6                	call   *%esi
			putch('X', putdat);
  800685:	83 c4 08             	add    $0x8,%esp
  800688:	53                   	push   %ebx
  800689:	6a 58                	push   $0x58
  80068b:	ff d6                	call   *%esi
			break;
  80068d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800690:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  800693:	e9 8b fc ff ff       	jmp    800323 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800698:	83 ec 08             	sub    $0x8,%esp
  80069b:	53                   	push   %ebx
  80069c:	6a 30                	push   $0x30
  80069e:	ff d6                	call   *%esi
			putch('x', putdat);
  8006a0:	83 c4 08             	add    $0x8,%esp
  8006a3:	53                   	push   %ebx
  8006a4:	6a 78                	push   $0x78
  8006a6:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006a8:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ab:	8b 10                	mov    (%eax),%edx
  8006ad:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006b2:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006b5:	8d 40 04             	lea    0x4(%eax),%eax
  8006b8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006bb:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006c0:	eb 4a                	jmp    80070c <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006c2:	83 f9 01             	cmp    $0x1,%ecx
  8006c5:	7e 15                	jle    8006dc <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006c7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ca:	8b 10                	mov    (%eax),%edx
  8006cc:	8b 48 04             	mov    0x4(%eax),%ecx
  8006cf:	8d 40 08             	lea    0x8(%eax),%eax
  8006d2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006d5:	b8 10 00 00 00       	mov    $0x10,%eax
  8006da:	eb 30                	jmp    80070c <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006dc:	85 c9                	test   %ecx,%ecx
  8006de:	74 17                	je     8006f7 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8006e0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e3:	8b 10                	mov    (%eax),%edx
  8006e5:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006ea:	8d 40 04             	lea    0x4(%eax),%eax
  8006ed:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006f0:	b8 10 00 00 00       	mov    $0x10,%eax
  8006f5:	eb 15                	jmp    80070c <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8006f7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006fa:	8b 10                	mov    (%eax),%edx
  8006fc:	b9 00 00 00 00       	mov    $0x0,%ecx
  800701:	8d 40 04             	lea    0x4(%eax),%eax
  800704:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800707:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80070c:	83 ec 0c             	sub    $0xc,%esp
  80070f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800713:	57                   	push   %edi
  800714:	ff 75 e0             	pushl  -0x20(%ebp)
  800717:	50                   	push   %eax
  800718:	51                   	push   %ecx
  800719:	52                   	push   %edx
  80071a:	89 da                	mov    %ebx,%edx
  80071c:	89 f0                	mov    %esi,%eax
  80071e:	e8 f1 fa ff ff       	call   800214 <printnum>
			break;
  800723:	83 c4 20             	add    $0x20,%esp
  800726:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800729:	e9 f5 fb ff ff       	jmp    800323 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80072e:	83 ec 08             	sub    $0x8,%esp
  800731:	53                   	push   %ebx
  800732:	52                   	push   %edx
  800733:	ff d6                	call   *%esi
			break;
  800735:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800738:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80073b:	e9 e3 fb ff ff       	jmp    800323 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800740:	83 ec 08             	sub    $0x8,%esp
  800743:	53                   	push   %ebx
  800744:	6a 25                	push   $0x25
  800746:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800748:	83 c4 10             	add    $0x10,%esp
  80074b:	eb 03                	jmp    800750 <vprintfmt+0x453>
  80074d:	83 ef 01             	sub    $0x1,%edi
  800750:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800754:	75 f7                	jne    80074d <vprintfmt+0x450>
  800756:	e9 c8 fb ff ff       	jmp    800323 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80075b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80075e:	5b                   	pop    %ebx
  80075f:	5e                   	pop    %esi
  800760:	5f                   	pop    %edi
  800761:	5d                   	pop    %ebp
  800762:	c3                   	ret    

00800763 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800763:	55                   	push   %ebp
  800764:	89 e5                	mov    %esp,%ebp
  800766:	83 ec 18             	sub    $0x18,%esp
  800769:	8b 45 08             	mov    0x8(%ebp),%eax
  80076c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80076f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800772:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800776:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800779:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800780:	85 c0                	test   %eax,%eax
  800782:	74 26                	je     8007aa <vsnprintf+0x47>
  800784:	85 d2                	test   %edx,%edx
  800786:	7e 22                	jle    8007aa <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800788:	ff 75 14             	pushl  0x14(%ebp)
  80078b:	ff 75 10             	pushl  0x10(%ebp)
  80078e:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800791:	50                   	push   %eax
  800792:	68 c3 02 80 00       	push   $0x8002c3
  800797:	e8 61 fb ff ff       	call   8002fd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80079c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80079f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007a5:	83 c4 10             	add    $0x10,%esp
  8007a8:	eb 05                	jmp    8007af <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007aa:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007af:	c9                   	leave  
  8007b0:	c3                   	ret    

008007b1 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007b1:	55                   	push   %ebp
  8007b2:	89 e5                	mov    %esp,%ebp
  8007b4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007b7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007ba:	50                   	push   %eax
  8007bb:	ff 75 10             	pushl  0x10(%ebp)
  8007be:	ff 75 0c             	pushl  0xc(%ebp)
  8007c1:	ff 75 08             	pushl  0x8(%ebp)
  8007c4:	e8 9a ff ff ff       	call   800763 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007c9:	c9                   	leave  
  8007ca:	c3                   	ret    

008007cb <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007cb:	55                   	push   %ebp
  8007cc:	89 e5                	mov    %esp,%ebp
  8007ce:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007d1:	b8 00 00 00 00       	mov    $0x0,%eax
  8007d6:	eb 03                	jmp    8007db <strlen+0x10>
		n++;
  8007d8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007db:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007df:	75 f7                	jne    8007d8 <strlen+0xd>
		n++;
	return n;
}
  8007e1:	5d                   	pop    %ebp
  8007e2:	c3                   	ret    

008007e3 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007e3:	55                   	push   %ebp
  8007e4:	89 e5                	mov    %esp,%ebp
  8007e6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007e9:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007ec:	ba 00 00 00 00       	mov    $0x0,%edx
  8007f1:	eb 03                	jmp    8007f6 <strnlen+0x13>
		n++;
  8007f3:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007f6:	39 c2                	cmp    %eax,%edx
  8007f8:	74 08                	je     800802 <strnlen+0x1f>
  8007fa:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007fe:	75 f3                	jne    8007f3 <strnlen+0x10>
  800800:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800802:	5d                   	pop    %ebp
  800803:	c3                   	ret    

00800804 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800804:	55                   	push   %ebp
  800805:	89 e5                	mov    %esp,%ebp
  800807:	53                   	push   %ebx
  800808:	8b 45 08             	mov    0x8(%ebp),%eax
  80080b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80080e:	89 c2                	mov    %eax,%edx
  800810:	83 c2 01             	add    $0x1,%edx
  800813:	83 c1 01             	add    $0x1,%ecx
  800816:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80081a:	88 5a ff             	mov    %bl,-0x1(%edx)
  80081d:	84 db                	test   %bl,%bl
  80081f:	75 ef                	jne    800810 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800821:	5b                   	pop    %ebx
  800822:	5d                   	pop    %ebp
  800823:	c3                   	ret    

00800824 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800824:	55                   	push   %ebp
  800825:	89 e5                	mov    %esp,%ebp
  800827:	53                   	push   %ebx
  800828:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80082b:	53                   	push   %ebx
  80082c:	e8 9a ff ff ff       	call   8007cb <strlen>
  800831:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800834:	ff 75 0c             	pushl  0xc(%ebp)
  800837:	01 d8                	add    %ebx,%eax
  800839:	50                   	push   %eax
  80083a:	e8 c5 ff ff ff       	call   800804 <strcpy>
	return dst;
}
  80083f:	89 d8                	mov    %ebx,%eax
  800841:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800844:	c9                   	leave  
  800845:	c3                   	ret    

00800846 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800846:	55                   	push   %ebp
  800847:	89 e5                	mov    %esp,%ebp
  800849:	56                   	push   %esi
  80084a:	53                   	push   %ebx
  80084b:	8b 75 08             	mov    0x8(%ebp),%esi
  80084e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800851:	89 f3                	mov    %esi,%ebx
  800853:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800856:	89 f2                	mov    %esi,%edx
  800858:	eb 0f                	jmp    800869 <strncpy+0x23>
		*dst++ = *src;
  80085a:	83 c2 01             	add    $0x1,%edx
  80085d:	0f b6 01             	movzbl (%ecx),%eax
  800860:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800863:	80 39 01             	cmpb   $0x1,(%ecx)
  800866:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800869:	39 da                	cmp    %ebx,%edx
  80086b:	75 ed                	jne    80085a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80086d:	89 f0                	mov    %esi,%eax
  80086f:	5b                   	pop    %ebx
  800870:	5e                   	pop    %esi
  800871:	5d                   	pop    %ebp
  800872:	c3                   	ret    

00800873 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800873:	55                   	push   %ebp
  800874:	89 e5                	mov    %esp,%ebp
  800876:	56                   	push   %esi
  800877:	53                   	push   %ebx
  800878:	8b 75 08             	mov    0x8(%ebp),%esi
  80087b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80087e:	8b 55 10             	mov    0x10(%ebp),%edx
  800881:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800883:	85 d2                	test   %edx,%edx
  800885:	74 21                	je     8008a8 <strlcpy+0x35>
  800887:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80088b:	89 f2                	mov    %esi,%edx
  80088d:	eb 09                	jmp    800898 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80088f:	83 c2 01             	add    $0x1,%edx
  800892:	83 c1 01             	add    $0x1,%ecx
  800895:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800898:	39 c2                	cmp    %eax,%edx
  80089a:	74 09                	je     8008a5 <strlcpy+0x32>
  80089c:	0f b6 19             	movzbl (%ecx),%ebx
  80089f:	84 db                	test   %bl,%bl
  8008a1:	75 ec                	jne    80088f <strlcpy+0x1c>
  8008a3:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008a5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008a8:	29 f0                	sub    %esi,%eax
}
  8008aa:	5b                   	pop    %ebx
  8008ab:	5e                   	pop    %esi
  8008ac:	5d                   	pop    %ebp
  8008ad:	c3                   	ret    

008008ae <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008ae:	55                   	push   %ebp
  8008af:	89 e5                	mov    %esp,%ebp
  8008b1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008b4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008b7:	eb 06                	jmp    8008bf <strcmp+0x11>
		p++, q++;
  8008b9:	83 c1 01             	add    $0x1,%ecx
  8008bc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008bf:	0f b6 01             	movzbl (%ecx),%eax
  8008c2:	84 c0                	test   %al,%al
  8008c4:	74 04                	je     8008ca <strcmp+0x1c>
  8008c6:	3a 02                	cmp    (%edx),%al
  8008c8:	74 ef                	je     8008b9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ca:	0f b6 c0             	movzbl %al,%eax
  8008cd:	0f b6 12             	movzbl (%edx),%edx
  8008d0:	29 d0                	sub    %edx,%eax
}
  8008d2:	5d                   	pop    %ebp
  8008d3:	c3                   	ret    

008008d4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008d4:	55                   	push   %ebp
  8008d5:	89 e5                	mov    %esp,%ebp
  8008d7:	53                   	push   %ebx
  8008d8:	8b 45 08             	mov    0x8(%ebp),%eax
  8008db:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008de:	89 c3                	mov    %eax,%ebx
  8008e0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008e3:	eb 06                	jmp    8008eb <strncmp+0x17>
		n--, p++, q++;
  8008e5:	83 c0 01             	add    $0x1,%eax
  8008e8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008eb:	39 d8                	cmp    %ebx,%eax
  8008ed:	74 15                	je     800904 <strncmp+0x30>
  8008ef:	0f b6 08             	movzbl (%eax),%ecx
  8008f2:	84 c9                	test   %cl,%cl
  8008f4:	74 04                	je     8008fa <strncmp+0x26>
  8008f6:	3a 0a                	cmp    (%edx),%cl
  8008f8:	74 eb                	je     8008e5 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008fa:	0f b6 00             	movzbl (%eax),%eax
  8008fd:	0f b6 12             	movzbl (%edx),%edx
  800900:	29 d0                	sub    %edx,%eax
  800902:	eb 05                	jmp    800909 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800904:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800909:	5b                   	pop    %ebx
  80090a:	5d                   	pop    %ebp
  80090b:	c3                   	ret    

0080090c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80090c:	55                   	push   %ebp
  80090d:	89 e5                	mov    %esp,%ebp
  80090f:	8b 45 08             	mov    0x8(%ebp),%eax
  800912:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800916:	eb 07                	jmp    80091f <strchr+0x13>
		if (*s == c)
  800918:	38 ca                	cmp    %cl,%dl
  80091a:	74 0f                	je     80092b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80091c:	83 c0 01             	add    $0x1,%eax
  80091f:	0f b6 10             	movzbl (%eax),%edx
  800922:	84 d2                	test   %dl,%dl
  800924:	75 f2                	jne    800918 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800926:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80092b:	5d                   	pop    %ebp
  80092c:	c3                   	ret    

0080092d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80092d:	55                   	push   %ebp
  80092e:	89 e5                	mov    %esp,%ebp
  800930:	8b 45 08             	mov    0x8(%ebp),%eax
  800933:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800937:	eb 03                	jmp    80093c <strfind+0xf>
  800939:	83 c0 01             	add    $0x1,%eax
  80093c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80093f:	38 ca                	cmp    %cl,%dl
  800941:	74 04                	je     800947 <strfind+0x1a>
  800943:	84 d2                	test   %dl,%dl
  800945:	75 f2                	jne    800939 <strfind+0xc>
			break;
	return (char *) s;
}
  800947:	5d                   	pop    %ebp
  800948:	c3                   	ret    

00800949 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800949:	55                   	push   %ebp
  80094a:	89 e5                	mov    %esp,%ebp
  80094c:	57                   	push   %edi
  80094d:	56                   	push   %esi
  80094e:	53                   	push   %ebx
  80094f:	8b 7d 08             	mov    0x8(%ebp),%edi
  800952:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800955:	85 c9                	test   %ecx,%ecx
  800957:	74 36                	je     80098f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800959:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80095f:	75 28                	jne    800989 <memset+0x40>
  800961:	f6 c1 03             	test   $0x3,%cl
  800964:	75 23                	jne    800989 <memset+0x40>
		c &= 0xFF;
  800966:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80096a:	89 d3                	mov    %edx,%ebx
  80096c:	c1 e3 08             	shl    $0x8,%ebx
  80096f:	89 d6                	mov    %edx,%esi
  800971:	c1 e6 18             	shl    $0x18,%esi
  800974:	89 d0                	mov    %edx,%eax
  800976:	c1 e0 10             	shl    $0x10,%eax
  800979:	09 f0                	or     %esi,%eax
  80097b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80097d:	89 d8                	mov    %ebx,%eax
  80097f:	09 d0                	or     %edx,%eax
  800981:	c1 e9 02             	shr    $0x2,%ecx
  800984:	fc                   	cld    
  800985:	f3 ab                	rep stos %eax,%es:(%edi)
  800987:	eb 06                	jmp    80098f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800989:	8b 45 0c             	mov    0xc(%ebp),%eax
  80098c:	fc                   	cld    
  80098d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80098f:	89 f8                	mov    %edi,%eax
  800991:	5b                   	pop    %ebx
  800992:	5e                   	pop    %esi
  800993:	5f                   	pop    %edi
  800994:	5d                   	pop    %ebp
  800995:	c3                   	ret    

00800996 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800996:	55                   	push   %ebp
  800997:	89 e5                	mov    %esp,%ebp
  800999:	57                   	push   %edi
  80099a:	56                   	push   %esi
  80099b:	8b 45 08             	mov    0x8(%ebp),%eax
  80099e:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009a1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009a4:	39 c6                	cmp    %eax,%esi
  8009a6:	73 35                	jae    8009dd <memmove+0x47>
  8009a8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009ab:	39 d0                	cmp    %edx,%eax
  8009ad:	73 2e                	jae    8009dd <memmove+0x47>
		s += n;
		d += n;
  8009af:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009b2:	89 d6                	mov    %edx,%esi
  8009b4:	09 fe                	or     %edi,%esi
  8009b6:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009bc:	75 13                	jne    8009d1 <memmove+0x3b>
  8009be:	f6 c1 03             	test   $0x3,%cl
  8009c1:	75 0e                	jne    8009d1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009c3:	83 ef 04             	sub    $0x4,%edi
  8009c6:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009c9:	c1 e9 02             	shr    $0x2,%ecx
  8009cc:	fd                   	std    
  8009cd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009cf:	eb 09                	jmp    8009da <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009d1:	83 ef 01             	sub    $0x1,%edi
  8009d4:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009d7:	fd                   	std    
  8009d8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009da:	fc                   	cld    
  8009db:	eb 1d                	jmp    8009fa <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009dd:	89 f2                	mov    %esi,%edx
  8009df:	09 c2                	or     %eax,%edx
  8009e1:	f6 c2 03             	test   $0x3,%dl
  8009e4:	75 0f                	jne    8009f5 <memmove+0x5f>
  8009e6:	f6 c1 03             	test   $0x3,%cl
  8009e9:	75 0a                	jne    8009f5 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8009eb:	c1 e9 02             	shr    $0x2,%ecx
  8009ee:	89 c7                	mov    %eax,%edi
  8009f0:	fc                   	cld    
  8009f1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009f3:	eb 05                	jmp    8009fa <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009f5:	89 c7                	mov    %eax,%edi
  8009f7:	fc                   	cld    
  8009f8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009fa:	5e                   	pop    %esi
  8009fb:	5f                   	pop    %edi
  8009fc:	5d                   	pop    %ebp
  8009fd:	c3                   	ret    

008009fe <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009fe:	55                   	push   %ebp
  8009ff:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a01:	ff 75 10             	pushl  0x10(%ebp)
  800a04:	ff 75 0c             	pushl  0xc(%ebp)
  800a07:	ff 75 08             	pushl  0x8(%ebp)
  800a0a:	e8 87 ff ff ff       	call   800996 <memmove>
}
  800a0f:	c9                   	leave  
  800a10:	c3                   	ret    

00800a11 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a11:	55                   	push   %ebp
  800a12:	89 e5                	mov    %esp,%ebp
  800a14:	56                   	push   %esi
  800a15:	53                   	push   %ebx
  800a16:	8b 45 08             	mov    0x8(%ebp),%eax
  800a19:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a1c:	89 c6                	mov    %eax,%esi
  800a1e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a21:	eb 1a                	jmp    800a3d <memcmp+0x2c>
		if (*s1 != *s2)
  800a23:	0f b6 08             	movzbl (%eax),%ecx
  800a26:	0f b6 1a             	movzbl (%edx),%ebx
  800a29:	38 d9                	cmp    %bl,%cl
  800a2b:	74 0a                	je     800a37 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a2d:	0f b6 c1             	movzbl %cl,%eax
  800a30:	0f b6 db             	movzbl %bl,%ebx
  800a33:	29 d8                	sub    %ebx,%eax
  800a35:	eb 0f                	jmp    800a46 <memcmp+0x35>
		s1++, s2++;
  800a37:	83 c0 01             	add    $0x1,%eax
  800a3a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a3d:	39 f0                	cmp    %esi,%eax
  800a3f:	75 e2                	jne    800a23 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a41:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a46:	5b                   	pop    %ebx
  800a47:	5e                   	pop    %esi
  800a48:	5d                   	pop    %ebp
  800a49:	c3                   	ret    

00800a4a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a4a:	55                   	push   %ebp
  800a4b:	89 e5                	mov    %esp,%ebp
  800a4d:	53                   	push   %ebx
  800a4e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a51:	89 c1                	mov    %eax,%ecx
  800a53:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a56:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a5a:	eb 0a                	jmp    800a66 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a5c:	0f b6 10             	movzbl (%eax),%edx
  800a5f:	39 da                	cmp    %ebx,%edx
  800a61:	74 07                	je     800a6a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a63:	83 c0 01             	add    $0x1,%eax
  800a66:	39 c8                	cmp    %ecx,%eax
  800a68:	72 f2                	jb     800a5c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a6a:	5b                   	pop    %ebx
  800a6b:	5d                   	pop    %ebp
  800a6c:	c3                   	ret    

00800a6d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a6d:	55                   	push   %ebp
  800a6e:	89 e5                	mov    %esp,%ebp
  800a70:	57                   	push   %edi
  800a71:	56                   	push   %esi
  800a72:	53                   	push   %ebx
  800a73:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a76:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a79:	eb 03                	jmp    800a7e <strtol+0x11>
		s++;
  800a7b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a7e:	0f b6 01             	movzbl (%ecx),%eax
  800a81:	3c 20                	cmp    $0x20,%al
  800a83:	74 f6                	je     800a7b <strtol+0xe>
  800a85:	3c 09                	cmp    $0x9,%al
  800a87:	74 f2                	je     800a7b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a89:	3c 2b                	cmp    $0x2b,%al
  800a8b:	75 0a                	jne    800a97 <strtol+0x2a>
		s++;
  800a8d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a90:	bf 00 00 00 00       	mov    $0x0,%edi
  800a95:	eb 11                	jmp    800aa8 <strtol+0x3b>
  800a97:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a9c:	3c 2d                	cmp    $0x2d,%al
  800a9e:	75 08                	jne    800aa8 <strtol+0x3b>
		s++, neg = 1;
  800aa0:	83 c1 01             	add    $0x1,%ecx
  800aa3:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800aa8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800aae:	75 15                	jne    800ac5 <strtol+0x58>
  800ab0:	80 39 30             	cmpb   $0x30,(%ecx)
  800ab3:	75 10                	jne    800ac5 <strtol+0x58>
  800ab5:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ab9:	75 7c                	jne    800b37 <strtol+0xca>
		s += 2, base = 16;
  800abb:	83 c1 02             	add    $0x2,%ecx
  800abe:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ac3:	eb 16                	jmp    800adb <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800ac5:	85 db                	test   %ebx,%ebx
  800ac7:	75 12                	jne    800adb <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ac9:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ace:	80 39 30             	cmpb   $0x30,(%ecx)
  800ad1:	75 08                	jne    800adb <strtol+0x6e>
		s++, base = 8;
  800ad3:	83 c1 01             	add    $0x1,%ecx
  800ad6:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800adb:	b8 00 00 00 00       	mov    $0x0,%eax
  800ae0:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800ae3:	0f b6 11             	movzbl (%ecx),%edx
  800ae6:	8d 72 d0             	lea    -0x30(%edx),%esi
  800ae9:	89 f3                	mov    %esi,%ebx
  800aeb:	80 fb 09             	cmp    $0x9,%bl
  800aee:	77 08                	ja     800af8 <strtol+0x8b>
			dig = *s - '0';
  800af0:	0f be d2             	movsbl %dl,%edx
  800af3:	83 ea 30             	sub    $0x30,%edx
  800af6:	eb 22                	jmp    800b1a <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800af8:	8d 72 9f             	lea    -0x61(%edx),%esi
  800afb:	89 f3                	mov    %esi,%ebx
  800afd:	80 fb 19             	cmp    $0x19,%bl
  800b00:	77 08                	ja     800b0a <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b02:	0f be d2             	movsbl %dl,%edx
  800b05:	83 ea 57             	sub    $0x57,%edx
  800b08:	eb 10                	jmp    800b1a <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b0a:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b0d:	89 f3                	mov    %esi,%ebx
  800b0f:	80 fb 19             	cmp    $0x19,%bl
  800b12:	77 16                	ja     800b2a <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b14:	0f be d2             	movsbl %dl,%edx
  800b17:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b1a:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b1d:	7d 0b                	jge    800b2a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b1f:	83 c1 01             	add    $0x1,%ecx
  800b22:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b26:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b28:	eb b9                	jmp    800ae3 <strtol+0x76>

	if (endptr)
  800b2a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b2e:	74 0d                	je     800b3d <strtol+0xd0>
		*endptr = (char *) s;
  800b30:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b33:	89 0e                	mov    %ecx,(%esi)
  800b35:	eb 06                	jmp    800b3d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b37:	85 db                	test   %ebx,%ebx
  800b39:	74 98                	je     800ad3 <strtol+0x66>
  800b3b:	eb 9e                	jmp    800adb <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b3d:	89 c2                	mov    %eax,%edx
  800b3f:	f7 da                	neg    %edx
  800b41:	85 ff                	test   %edi,%edi
  800b43:	0f 45 c2             	cmovne %edx,%eax
}
  800b46:	5b                   	pop    %ebx
  800b47:	5e                   	pop    %esi
  800b48:	5f                   	pop    %edi
  800b49:	5d                   	pop    %ebp
  800b4a:	c3                   	ret    
  800b4b:	66 90                	xchg   %ax,%ax
  800b4d:	66 90                	xchg   %ax,%ax
  800b4f:	90                   	nop

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
