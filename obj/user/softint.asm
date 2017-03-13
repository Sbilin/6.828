
obj/user/softint:     file format elf32-i386


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
  80002c:	e8 09 00 00 00       	call   80003a <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $14");	// page fault
  800036:	cd 0e                	int    $0xe
}
  800038:	5d                   	pop    %ebp
  800039:	c3                   	ret    

0080003a <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003a:	55                   	push   %ebp
  80003b:	89 e5                	mov    %esp,%ebp
  80003d:	83 ec 08             	sub    $0x8,%esp
  800040:	8b 45 08             	mov    0x8(%ebp),%eax
  800043:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800046:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80004d:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800050:	85 c0                	test   %eax,%eax
  800052:	7e 08                	jle    80005c <libmain+0x22>
		binaryname = argv[0];
  800054:	8b 0a                	mov    (%edx),%ecx
  800056:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  80005c:	83 ec 08             	sub    $0x8,%esp
  80005f:	52                   	push   %edx
  800060:	50                   	push   %eax
  800061:	e8 cd ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800066:	e8 05 00 00 00       	call   800070 <exit>
}
  80006b:	83 c4 10             	add    $0x10,%esp
  80006e:	c9                   	leave  
  80006f:	c3                   	ret    

00800070 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800070:	55                   	push   %ebp
  800071:	89 e5                	mov    %esp,%ebp
  800073:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800076:	6a 00                	push   $0x0
  800078:	e8 42 00 00 00       	call   8000bf <sys_env_destroy>
}
  80007d:	83 c4 10             	add    $0x10,%esp
  800080:	c9                   	leave  
  800081:	c3                   	ret    

00800082 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800082:	55                   	push   %ebp
  800083:	89 e5                	mov    %esp,%ebp
  800085:	57                   	push   %edi
  800086:	56                   	push   %esi
  800087:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800088:	b8 00 00 00 00       	mov    $0x0,%eax
  80008d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800090:	8b 55 08             	mov    0x8(%ebp),%edx
  800093:	89 c3                	mov    %eax,%ebx
  800095:	89 c7                	mov    %eax,%edi
  800097:	89 c6                	mov    %eax,%esi
  800099:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  80009b:	5b                   	pop    %ebx
  80009c:	5e                   	pop    %esi
  80009d:	5f                   	pop    %edi
  80009e:	5d                   	pop    %ebp
  80009f:	c3                   	ret    

008000a0 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000a0:	55                   	push   %ebp
  8000a1:	89 e5                	mov    %esp,%ebp
  8000a3:	57                   	push   %edi
  8000a4:	56                   	push   %esi
  8000a5:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a6:	ba 00 00 00 00       	mov    $0x0,%edx
  8000ab:	b8 01 00 00 00       	mov    $0x1,%eax
  8000b0:	89 d1                	mov    %edx,%ecx
  8000b2:	89 d3                	mov    %edx,%ebx
  8000b4:	89 d7                	mov    %edx,%edi
  8000b6:	89 d6                	mov    %edx,%esi
  8000b8:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000ba:	5b                   	pop    %ebx
  8000bb:	5e                   	pop    %esi
  8000bc:	5f                   	pop    %edi
  8000bd:	5d                   	pop    %ebp
  8000be:	c3                   	ret    

008000bf <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000bf:	55                   	push   %ebp
  8000c0:	89 e5                	mov    %esp,%ebp
  8000c2:	57                   	push   %edi
  8000c3:	56                   	push   %esi
  8000c4:	53                   	push   %ebx
  8000c5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000c8:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000cd:	b8 03 00 00 00       	mov    $0x3,%eax
  8000d2:	8b 55 08             	mov    0x8(%ebp),%edx
  8000d5:	89 cb                	mov    %ecx,%ebx
  8000d7:	89 cf                	mov    %ecx,%edi
  8000d9:	89 ce                	mov    %ecx,%esi
  8000db:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000dd:	85 c0                	test   %eax,%eax
  8000df:	7e 17                	jle    8000f8 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000e1:	83 ec 0c             	sub    $0xc,%esp
  8000e4:	50                   	push   %eax
  8000e5:	6a 03                	push   $0x3
  8000e7:	68 de 0d 80 00       	push   $0x800dde
  8000ec:	6a 23                	push   $0x23
  8000ee:	68 fb 0d 80 00       	push   $0x800dfb
  8000f3:	e8 27 00 00 00       	call   80011f <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  8000f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000fb:	5b                   	pop    %ebx
  8000fc:	5e                   	pop    %esi
  8000fd:	5f                   	pop    %edi
  8000fe:	5d                   	pop    %ebp
  8000ff:	c3                   	ret    

00800100 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800100:	55                   	push   %ebp
  800101:	89 e5                	mov    %esp,%ebp
  800103:	57                   	push   %edi
  800104:	56                   	push   %esi
  800105:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800106:	ba 00 00 00 00       	mov    $0x0,%edx
  80010b:	b8 02 00 00 00       	mov    $0x2,%eax
  800110:	89 d1                	mov    %edx,%ecx
  800112:	89 d3                	mov    %edx,%ebx
  800114:	89 d7                	mov    %edx,%edi
  800116:	89 d6                	mov    %edx,%esi
  800118:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80011a:	5b                   	pop    %ebx
  80011b:	5e                   	pop    %esi
  80011c:	5f                   	pop    %edi
  80011d:	5d                   	pop    %ebp
  80011e:	c3                   	ret    

0080011f <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80011f:	55                   	push   %ebp
  800120:	89 e5                	mov    %esp,%ebp
  800122:	56                   	push   %esi
  800123:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800124:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800127:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80012d:	e8 ce ff ff ff       	call   800100 <sys_getenvid>
  800132:	83 ec 0c             	sub    $0xc,%esp
  800135:	ff 75 0c             	pushl  0xc(%ebp)
  800138:	ff 75 08             	pushl  0x8(%ebp)
  80013b:	56                   	push   %esi
  80013c:	50                   	push   %eax
  80013d:	68 0c 0e 80 00       	push   $0x800e0c
  800142:	e8 b1 00 00 00       	call   8001f8 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800147:	83 c4 18             	add    $0x18,%esp
  80014a:	53                   	push   %ebx
  80014b:	ff 75 10             	pushl  0x10(%ebp)
  80014e:	e8 54 00 00 00       	call   8001a7 <vcprintf>
	cprintf("\n");
  800153:	c7 04 24 30 0e 80 00 	movl   $0x800e30,(%esp)
  80015a:	e8 99 00 00 00       	call   8001f8 <cprintf>
  80015f:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800162:	cc                   	int3   
  800163:	eb fd                	jmp    800162 <_panic+0x43>

00800165 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800165:	55                   	push   %ebp
  800166:	89 e5                	mov    %esp,%ebp
  800168:	53                   	push   %ebx
  800169:	83 ec 04             	sub    $0x4,%esp
  80016c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80016f:	8b 13                	mov    (%ebx),%edx
  800171:	8d 42 01             	lea    0x1(%edx),%eax
  800174:	89 03                	mov    %eax,(%ebx)
  800176:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800179:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80017d:	3d ff 00 00 00       	cmp    $0xff,%eax
  800182:	75 1a                	jne    80019e <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800184:	83 ec 08             	sub    $0x8,%esp
  800187:	68 ff 00 00 00       	push   $0xff
  80018c:	8d 43 08             	lea    0x8(%ebx),%eax
  80018f:	50                   	push   %eax
  800190:	e8 ed fe ff ff       	call   800082 <sys_cputs>
		b->idx = 0;
  800195:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80019b:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80019e:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001a2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001a5:	c9                   	leave  
  8001a6:	c3                   	ret    

008001a7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001a7:	55                   	push   %ebp
  8001a8:	89 e5                	mov    %esp,%ebp
  8001aa:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001b0:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001b7:	00 00 00 
	b.cnt = 0;
  8001ba:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001c1:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001c4:	ff 75 0c             	pushl  0xc(%ebp)
  8001c7:	ff 75 08             	pushl  0x8(%ebp)
  8001ca:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001d0:	50                   	push   %eax
  8001d1:	68 65 01 80 00       	push   $0x800165
  8001d6:	e8 1a 01 00 00       	call   8002f5 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001db:	83 c4 08             	add    $0x8,%esp
  8001de:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001e4:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001ea:	50                   	push   %eax
  8001eb:	e8 92 fe ff ff       	call   800082 <sys_cputs>

	return b.cnt;
}
  8001f0:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001f6:	c9                   	leave  
  8001f7:	c3                   	ret    

008001f8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001f8:	55                   	push   %ebp
  8001f9:	89 e5                	mov    %esp,%ebp
  8001fb:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001fe:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800201:	50                   	push   %eax
  800202:	ff 75 08             	pushl  0x8(%ebp)
  800205:	e8 9d ff ff ff       	call   8001a7 <vcprintf>
	va_end(ap);

	return cnt;
}
  80020a:	c9                   	leave  
  80020b:	c3                   	ret    

0080020c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80020c:	55                   	push   %ebp
  80020d:	89 e5                	mov    %esp,%ebp
  80020f:	57                   	push   %edi
  800210:	56                   	push   %esi
  800211:	53                   	push   %ebx
  800212:	83 ec 1c             	sub    $0x1c,%esp
  800215:	89 c7                	mov    %eax,%edi
  800217:	89 d6                	mov    %edx,%esi
  800219:	8b 45 08             	mov    0x8(%ebp),%eax
  80021c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80021f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800222:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800225:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800228:	bb 00 00 00 00       	mov    $0x0,%ebx
  80022d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800230:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800233:	39 d3                	cmp    %edx,%ebx
  800235:	72 05                	jb     80023c <printnum+0x30>
  800237:	39 45 10             	cmp    %eax,0x10(%ebp)
  80023a:	77 45                	ja     800281 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80023c:	83 ec 0c             	sub    $0xc,%esp
  80023f:	ff 75 18             	pushl  0x18(%ebp)
  800242:	8b 45 14             	mov    0x14(%ebp),%eax
  800245:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800248:	53                   	push   %ebx
  800249:	ff 75 10             	pushl  0x10(%ebp)
  80024c:	83 ec 08             	sub    $0x8,%esp
  80024f:	ff 75 e4             	pushl  -0x1c(%ebp)
  800252:	ff 75 e0             	pushl  -0x20(%ebp)
  800255:	ff 75 dc             	pushl  -0x24(%ebp)
  800258:	ff 75 d8             	pushl  -0x28(%ebp)
  80025b:	e8 f0 08 00 00       	call   800b50 <__udivdi3>
  800260:	83 c4 18             	add    $0x18,%esp
  800263:	52                   	push   %edx
  800264:	50                   	push   %eax
  800265:	89 f2                	mov    %esi,%edx
  800267:	89 f8                	mov    %edi,%eax
  800269:	e8 9e ff ff ff       	call   80020c <printnum>
  80026e:	83 c4 20             	add    $0x20,%esp
  800271:	eb 18                	jmp    80028b <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800273:	83 ec 08             	sub    $0x8,%esp
  800276:	56                   	push   %esi
  800277:	ff 75 18             	pushl  0x18(%ebp)
  80027a:	ff d7                	call   *%edi
  80027c:	83 c4 10             	add    $0x10,%esp
  80027f:	eb 03                	jmp    800284 <printnum+0x78>
  800281:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800284:	83 eb 01             	sub    $0x1,%ebx
  800287:	85 db                	test   %ebx,%ebx
  800289:	7f e8                	jg     800273 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80028b:	83 ec 08             	sub    $0x8,%esp
  80028e:	56                   	push   %esi
  80028f:	83 ec 04             	sub    $0x4,%esp
  800292:	ff 75 e4             	pushl  -0x1c(%ebp)
  800295:	ff 75 e0             	pushl  -0x20(%ebp)
  800298:	ff 75 dc             	pushl  -0x24(%ebp)
  80029b:	ff 75 d8             	pushl  -0x28(%ebp)
  80029e:	e8 dd 09 00 00       	call   800c80 <__umoddi3>
  8002a3:	83 c4 14             	add    $0x14,%esp
  8002a6:	0f be 80 32 0e 80 00 	movsbl 0x800e32(%eax),%eax
  8002ad:	50                   	push   %eax
  8002ae:	ff d7                	call   *%edi
}
  8002b0:	83 c4 10             	add    $0x10,%esp
  8002b3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002b6:	5b                   	pop    %ebx
  8002b7:	5e                   	pop    %esi
  8002b8:	5f                   	pop    %edi
  8002b9:	5d                   	pop    %ebp
  8002ba:	c3                   	ret    

008002bb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002bb:	55                   	push   %ebp
  8002bc:	89 e5                	mov    %esp,%ebp
  8002be:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002c1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002c5:	8b 10                	mov    (%eax),%edx
  8002c7:	3b 50 04             	cmp    0x4(%eax),%edx
  8002ca:	73 0a                	jae    8002d6 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002cc:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002cf:	89 08                	mov    %ecx,(%eax)
  8002d1:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d4:	88 02                	mov    %al,(%edx)
}
  8002d6:	5d                   	pop    %ebp
  8002d7:	c3                   	ret    

008002d8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002d8:	55                   	push   %ebp
  8002d9:	89 e5                	mov    %esp,%ebp
  8002db:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002de:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002e1:	50                   	push   %eax
  8002e2:	ff 75 10             	pushl  0x10(%ebp)
  8002e5:	ff 75 0c             	pushl  0xc(%ebp)
  8002e8:	ff 75 08             	pushl  0x8(%ebp)
  8002eb:	e8 05 00 00 00       	call   8002f5 <vprintfmt>
	va_end(ap);
}
  8002f0:	83 c4 10             	add    $0x10,%esp
  8002f3:	c9                   	leave  
  8002f4:	c3                   	ret    

008002f5 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002f5:	55                   	push   %ebp
  8002f6:	89 e5                	mov    %esp,%ebp
  8002f8:	57                   	push   %edi
  8002f9:	56                   	push   %esi
  8002fa:	53                   	push   %ebx
  8002fb:	83 ec 2c             	sub    $0x2c,%esp
  8002fe:	8b 75 08             	mov    0x8(%ebp),%esi
  800301:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800304:	8b 7d 10             	mov    0x10(%ebp),%edi
  800307:	eb 12                	jmp    80031b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800309:	85 c0                	test   %eax,%eax
  80030b:	0f 84 42 04 00 00    	je     800753 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800311:	83 ec 08             	sub    $0x8,%esp
  800314:	53                   	push   %ebx
  800315:	50                   	push   %eax
  800316:	ff d6                	call   *%esi
  800318:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80031b:	83 c7 01             	add    $0x1,%edi
  80031e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800322:	83 f8 25             	cmp    $0x25,%eax
  800325:	75 e2                	jne    800309 <vprintfmt+0x14>
  800327:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80032b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800332:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800339:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800340:	b9 00 00 00 00       	mov    $0x0,%ecx
  800345:	eb 07                	jmp    80034e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800347:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80034a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034e:	8d 47 01             	lea    0x1(%edi),%eax
  800351:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800354:	0f b6 07             	movzbl (%edi),%eax
  800357:	0f b6 d0             	movzbl %al,%edx
  80035a:	83 e8 23             	sub    $0x23,%eax
  80035d:	3c 55                	cmp    $0x55,%al
  80035f:	0f 87 d3 03 00 00    	ja     800738 <vprintfmt+0x443>
  800365:	0f b6 c0             	movzbl %al,%eax
  800368:	ff 24 85 c0 0e 80 00 	jmp    *0x800ec0(,%eax,4)
  80036f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800372:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800376:	eb d6                	jmp    80034e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800378:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80037b:	b8 00 00 00 00       	mov    $0x0,%eax
  800380:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800383:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800386:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80038a:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  80038d:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800390:	83 f9 09             	cmp    $0x9,%ecx
  800393:	77 3f                	ja     8003d4 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800395:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800398:	eb e9                	jmp    800383 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80039a:	8b 45 14             	mov    0x14(%ebp),%eax
  80039d:	8b 00                	mov    (%eax),%eax
  80039f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003a2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a5:	8d 40 04             	lea    0x4(%eax),%eax
  8003a8:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003ae:	eb 2a                	jmp    8003da <vprintfmt+0xe5>
  8003b0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003b3:	85 c0                	test   %eax,%eax
  8003b5:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ba:	0f 49 d0             	cmovns %eax,%edx
  8003bd:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003c3:	eb 89                	jmp    80034e <vprintfmt+0x59>
  8003c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003c8:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003cf:	e9 7a ff ff ff       	jmp    80034e <vprintfmt+0x59>
  8003d4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003d7:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8003da:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003de:	0f 89 6a ff ff ff    	jns    80034e <vprintfmt+0x59>
				width = precision, precision = -1;
  8003e4:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003e7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003ea:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003f1:	e9 58 ff ff ff       	jmp    80034e <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003f6:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003fc:	e9 4d ff ff ff       	jmp    80034e <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800401:	8b 45 14             	mov    0x14(%ebp),%eax
  800404:	8d 78 04             	lea    0x4(%eax),%edi
  800407:	83 ec 08             	sub    $0x8,%esp
  80040a:	53                   	push   %ebx
  80040b:	ff 30                	pushl  (%eax)
  80040d:	ff d6                	call   *%esi
			break;
  80040f:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800412:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800415:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800418:	e9 fe fe ff ff       	jmp    80031b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80041d:	8b 45 14             	mov    0x14(%ebp),%eax
  800420:	8d 78 04             	lea    0x4(%eax),%edi
  800423:	8b 00                	mov    (%eax),%eax
  800425:	99                   	cltd   
  800426:	31 d0                	xor    %edx,%eax
  800428:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80042a:	83 f8 06             	cmp    $0x6,%eax
  80042d:	7f 0b                	jg     80043a <vprintfmt+0x145>
  80042f:	8b 14 85 18 10 80 00 	mov    0x801018(,%eax,4),%edx
  800436:	85 d2                	test   %edx,%edx
  800438:	75 1b                	jne    800455 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80043a:	50                   	push   %eax
  80043b:	68 4a 0e 80 00       	push   $0x800e4a
  800440:	53                   	push   %ebx
  800441:	56                   	push   %esi
  800442:	e8 91 fe ff ff       	call   8002d8 <printfmt>
  800447:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80044a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800450:	e9 c6 fe ff ff       	jmp    80031b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800455:	52                   	push   %edx
  800456:	68 53 0e 80 00       	push   $0x800e53
  80045b:	53                   	push   %ebx
  80045c:	56                   	push   %esi
  80045d:	e8 76 fe ff ff       	call   8002d8 <printfmt>
  800462:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800465:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800468:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80046b:	e9 ab fe ff ff       	jmp    80031b <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800470:	8b 45 14             	mov    0x14(%ebp),%eax
  800473:	83 c0 04             	add    $0x4,%eax
  800476:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800479:	8b 45 14             	mov    0x14(%ebp),%eax
  80047c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80047e:	85 ff                	test   %edi,%edi
  800480:	b8 43 0e 80 00       	mov    $0x800e43,%eax
  800485:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800488:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80048c:	0f 8e 94 00 00 00    	jle    800526 <vprintfmt+0x231>
  800492:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800496:	0f 84 98 00 00 00    	je     800534 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  80049c:	83 ec 08             	sub    $0x8,%esp
  80049f:	ff 75 d0             	pushl  -0x30(%ebp)
  8004a2:	57                   	push   %edi
  8004a3:	e8 33 03 00 00       	call   8007db <strnlen>
  8004a8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004ab:	29 c1                	sub    %eax,%ecx
  8004ad:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004b0:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004b3:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004ba:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004bd:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004bf:	eb 0f                	jmp    8004d0 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004c1:	83 ec 08             	sub    $0x8,%esp
  8004c4:	53                   	push   %ebx
  8004c5:	ff 75 e0             	pushl  -0x20(%ebp)
  8004c8:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ca:	83 ef 01             	sub    $0x1,%edi
  8004cd:	83 c4 10             	add    $0x10,%esp
  8004d0:	85 ff                	test   %edi,%edi
  8004d2:	7f ed                	jg     8004c1 <vprintfmt+0x1cc>
  8004d4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004d7:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004da:	85 c9                	test   %ecx,%ecx
  8004dc:	b8 00 00 00 00       	mov    $0x0,%eax
  8004e1:	0f 49 c1             	cmovns %ecx,%eax
  8004e4:	29 c1                	sub    %eax,%ecx
  8004e6:	89 75 08             	mov    %esi,0x8(%ebp)
  8004e9:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004ec:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004ef:	89 cb                	mov    %ecx,%ebx
  8004f1:	eb 4d                	jmp    800540 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004f3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004f7:	74 1b                	je     800514 <vprintfmt+0x21f>
  8004f9:	0f be c0             	movsbl %al,%eax
  8004fc:	83 e8 20             	sub    $0x20,%eax
  8004ff:	83 f8 5e             	cmp    $0x5e,%eax
  800502:	76 10                	jbe    800514 <vprintfmt+0x21f>
					putch('?', putdat);
  800504:	83 ec 08             	sub    $0x8,%esp
  800507:	ff 75 0c             	pushl  0xc(%ebp)
  80050a:	6a 3f                	push   $0x3f
  80050c:	ff 55 08             	call   *0x8(%ebp)
  80050f:	83 c4 10             	add    $0x10,%esp
  800512:	eb 0d                	jmp    800521 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800514:	83 ec 08             	sub    $0x8,%esp
  800517:	ff 75 0c             	pushl  0xc(%ebp)
  80051a:	52                   	push   %edx
  80051b:	ff 55 08             	call   *0x8(%ebp)
  80051e:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800521:	83 eb 01             	sub    $0x1,%ebx
  800524:	eb 1a                	jmp    800540 <vprintfmt+0x24b>
  800526:	89 75 08             	mov    %esi,0x8(%ebp)
  800529:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80052c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80052f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800532:	eb 0c                	jmp    800540 <vprintfmt+0x24b>
  800534:	89 75 08             	mov    %esi,0x8(%ebp)
  800537:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80053a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80053d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800540:	83 c7 01             	add    $0x1,%edi
  800543:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800547:	0f be d0             	movsbl %al,%edx
  80054a:	85 d2                	test   %edx,%edx
  80054c:	74 23                	je     800571 <vprintfmt+0x27c>
  80054e:	85 f6                	test   %esi,%esi
  800550:	78 a1                	js     8004f3 <vprintfmt+0x1fe>
  800552:	83 ee 01             	sub    $0x1,%esi
  800555:	79 9c                	jns    8004f3 <vprintfmt+0x1fe>
  800557:	89 df                	mov    %ebx,%edi
  800559:	8b 75 08             	mov    0x8(%ebp),%esi
  80055c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80055f:	eb 18                	jmp    800579 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800561:	83 ec 08             	sub    $0x8,%esp
  800564:	53                   	push   %ebx
  800565:	6a 20                	push   $0x20
  800567:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800569:	83 ef 01             	sub    $0x1,%edi
  80056c:	83 c4 10             	add    $0x10,%esp
  80056f:	eb 08                	jmp    800579 <vprintfmt+0x284>
  800571:	89 df                	mov    %ebx,%edi
  800573:	8b 75 08             	mov    0x8(%ebp),%esi
  800576:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800579:	85 ff                	test   %edi,%edi
  80057b:	7f e4                	jg     800561 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80057d:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800580:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800583:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800586:	e9 90 fd ff ff       	jmp    80031b <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80058b:	83 f9 01             	cmp    $0x1,%ecx
  80058e:	7e 19                	jle    8005a9 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800590:	8b 45 14             	mov    0x14(%ebp),%eax
  800593:	8b 50 04             	mov    0x4(%eax),%edx
  800596:	8b 00                	mov    (%eax),%eax
  800598:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80059b:	89 55 dc             	mov    %edx,-0x24(%ebp)
  80059e:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a1:	8d 40 08             	lea    0x8(%eax),%eax
  8005a4:	89 45 14             	mov    %eax,0x14(%ebp)
  8005a7:	eb 38                	jmp    8005e1 <vprintfmt+0x2ec>
	else if (lflag)
  8005a9:	85 c9                	test   %ecx,%ecx
  8005ab:	74 1b                	je     8005c8 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005ad:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b0:	8b 00                	mov    (%eax),%eax
  8005b2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005b5:	89 c1                	mov    %eax,%ecx
  8005b7:	c1 f9 1f             	sar    $0x1f,%ecx
  8005ba:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005bd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c0:	8d 40 04             	lea    0x4(%eax),%eax
  8005c3:	89 45 14             	mov    %eax,0x14(%ebp)
  8005c6:	eb 19                	jmp    8005e1 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005c8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cb:	8b 00                	mov    (%eax),%eax
  8005cd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005d0:	89 c1                	mov    %eax,%ecx
  8005d2:	c1 f9 1f             	sar    $0x1f,%ecx
  8005d5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005db:	8d 40 04             	lea    0x4(%eax),%eax
  8005de:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005e1:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005e4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005e7:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005ec:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005f0:	0f 89 0e 01 00 00    	jns    800704 <vprintfmt+0x40f>
				putch('-', putdat);
  8005f6:	83 ec 08             	sub    $0x8,%esp
  8005f9:	53                   	push   %ebx
  8005fa:	6a 2d                	push   $0x2d
  8005fc:	ff d6                	call   *%esi
				num = -(long long) num;
  8005fe:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800601:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800604:	f7 da                	neg    %edx
  800606:	83 d1 00             	adc    $0x0,%ecx
  800609:	f7 d9                	neg    %ecx
  80060b:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80060e:	b8 0a 00 00 00       	mov    $0xa,%eax
  800613:	e9 ec 00 00 00       	jmp    800704 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800618:	83 f9 01             	cmp    $0x1,%ecx
  80061b:	7e 18                	jle    800635 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80061d:	8b 45 14             	mov    0x14(%ebp),%eax
  800620:	8b 10                	mov    (%eax),%edx
  800622:	8b 48 04             	mov    0x4(%eax),%ecx
  800625:	8d 40 08             	lea    0x8(%eax),%eax
  800628:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80062b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800630:	e9 cf 00 00 00       	jmp    800704 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800635:	85 c9                	test   %ecx,%ecx
  800637:	74 1a                	je     800653 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800639:	8b 45 14             	mov    0x14(%ebp),%eax
  80063c:	8b 10                	mov    (%eax),%edx
  80063e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800643:	8d 40 04             	lea    0x4(%eax),%eax
  800646:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800649:	b8 0a 00 00 00       	mov    $0xa,%eax
  80064e:	e9 b1 00 00 00       	jmp    800704 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800653:	8b 45 14             	mov    0x14(%ebp),%eax
  800656:	8b 10                	mov    (%eax),%edx
  800658:	b9 00 00 00 00       	mov    $0x0,%ecx
  80065d:	8d 40 04             	lea    0x4(%eax),%eax
  800660:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800663:	b8 0a 00 00 00       	mov    $0xa,%eax
  800668:	e9 97 00 00 00       	jmp    800704 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  80066d:	83 ec 08             	sub    $0x8,%esp
  800670:	53                   	push   %ebx
  800671:	6a 58                	push   $0x58
  800673:	ff d6                	call   *%esi
			putch('X', putdat);
  800675:	83 c4 08             	add    $0x8,%esp
  800678:	53                   	push   %ebx
  800679:	6a 58                	push   $0x58
  80067b:	ff d6                	call   *%esi
			putch('X', putdat);
  80067d:	83 c4 08             	add    $0x8,%esp
  800680:	53                   	push   %ebx
  800681:	6a 58                	push   $0x58
  800683:	ff d6                	call   *%esi
			break;
  800685:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800688:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  80068b:	e9 8b fc ff ff       	jmp    80031b <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800690:	83 ec 08             	sub    $0x8,%esp
  800693:	53                   	push   %ebx
  800694:	6a 30                	push   $0x30
  800696:	ff d6                	call   *%esi
			putch('x', putdat);
  800698:	83 c4 08             	add    $0x8,%esp
  80069b:	53                   	push   %ebx
  80069c:	6a 78                	push   $0x78
  80069e:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006a0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a3:	8b 10                	mov    (%eax),%edx
  8006a5:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006aa:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006ad:	8d 40 04             	lea    0x4(%eax),%eax
  8006b0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006b3:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006b8:	eb 4a                	jmp    800704 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006ba:	83 f9 01             	cmp    $0x1,%ecx
  8006bd:	7e 15                	jle    8006d4 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006bf:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c2:	8b 10                	mov    (%eax),%edx
  8006c4:	8b 48 04             	mov    0x4(%eax),%ecx
  8006c7:	8d 40 08             	lea    0x8(%eax),%eax
  8006ca:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006cd:	b8 10 00 00 00       	mov    $0x10,%eax
  8006d2:	eb 30                	jmp    800704 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006d4:	85 c9                	test   %ecx,%ecx
  8006d6:	74 17                	je     8006ef <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8006d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8006db:	8b 10                	mov    (%eax),%edx
  8006dd:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006e2:	8d 40 04             	lea    0x4(%eax),%eax
  8006e5:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006e8:	b8 10 00 00 00       	mov    $0x10,%eax
  8006ed:	eb 15                	jmp    800704 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8006ef:	8b 45 14             	mov    0x14(%ebp),%eax
  8006f2:	8b 10                	mov    (%eax),%edx
  8006f4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006f9:	8d 40 04             	lea    0x4(%eax),%eax
  8006fc:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006ff:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800704:	83 ec 0c             	sub    $0xc,%esp
  800707:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80070b:	57                   	push   %edi
  80070c:	ff 75 e0             	pushl  -0x20(%ebp)
  80070f:	50                   	push   %eax
  800710:	51                   	push   %ecx
  800711:	52                   	push   %edx
  800712:	89 da                	mov    %ebx,%edx
  800714:	89 f0                	mov    %esi,%eax
  800716:	e8 f1 fa ff ff       	call   80020c <printnum>
			break;
  80071b:	83 c4 20             	add    $0x20,%esp
  80071e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800721:	e9 f5 fb ff ff       	jmp    80031b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800726:	83 ec 08             	sub    $0x8,%esp
  800729:	53                   	push   %ebx
  80072a:	52                   	push   %edx
  80072b:	ff d6                	call   *%esi
			break;
  80072d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800730:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800733:	e9 e3 fb ff ff       	jmp    80031b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800738:	83 ec 08             	sub    $0x8,%esp
  80073b:	53                   	push   %ebx
  80073c:	6a 25                	push   $0x25
  80073e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800740:	83 c4 10             	add    $0x10,%esp
  800743:	eb 03                	jmp    800748 <vprintfmt+0x453>
  800745:	83 ef 01             	sub    $0x1,%edi
  800748:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80074c:	75 f7                	jne    800745 <vprintfmt+0x450>
  80074e:	e9 c8 fb ff ff       	jmp    80031b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800753:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800756:	5b                   	pop    %ebx
  800757:	5e                   	pop    %esi
  800758:	5f                   	pop    %edi
  800759:	5d                   	pop    %ebp
  80075a:	c3                   	ret    

0080075b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80075b:	55                   	push   %ebp
  80075c:	89 e5                	mov    %esp,%ebp
  80075e:	83 ec 18             	sub    $0x18,%esp
  800761:	8b 45 08             	mov    0x8(%ebp),%eax
  800764:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800767:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80076a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80076e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800771:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800778:	85 c0                	test   %eax,%eax
  80077a:	74 26                	je     8007a2 <vsnprintf+0x47>
  80077c:	85 d2                	test   %edx,%edx
  80077e:	7e 22                	jle    8007a2 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800780:	ff 75 14             	pushl  0x14(%ebp)
  800783:	ff 75 10             	pushl  0x10(%ebp)
  800786:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800789:	50                   	push   %eax
  80078a:	68 bb 02 80 00       	push   $0x8002bb
  80078f:	e8 61 fb ff ff       	call   8002f5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800794:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800797:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80079a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80079d:	83 c4 10             	add    $0x10,%esp
  8007a0:	eb 05                	jmp    8007a7 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007a2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007a7:	c9                   	leave  
  8007a8:	c3                   	ret    

008007a9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007a9:	55                   	push   %ebp
  8007aa:	89 e5                	mov    %esp,%ebp
  8007ac:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007af:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007b2:	50                   	push   %eax
  8007b3:	ff 75 10             	pushl  0x10(%ebp)
  8007b6:	ff 75 0c             	pushl  0xc(%ebp)
  8007b9:	ff 75 08             	pushl  0x8(%ebp)
  8007bc:	e8 9a ff ff ff       	call   80075b <vsnprintf>
	va_end(ap);

	return rc;
}
  8007c1:	c9                   	leave  
  8007c2:	c3                   	ret    

008007c3 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007c3:	55                   	push   %ebp
  8007c4:	89 e5                	mov    %esp,%ebp
  8007c6:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007c9:	b8 00 00 00 00       	mov    $0x0,%eax
  8007ce:	eb 03                	jmp    8007d3 <strlen+0x10>
		n++;
  8007d0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007d3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007d7:	75 f7                	jne    8007d0 <strlen+0xd>
		n++;
	return n;
}
  8007d9:	5d                   	pop    %ebp
  8007da:	c3                   	ret    

008007db <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007db:	55                   	push   %ebp
  8007dc:	89 e5                	mov    %esp,%ebp
  8007de:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007e1:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007e4:	ba 00 00 00 00       	mov    $0x0,%edx
  8007e9:	eb 03                	jmp    8007ee <strnlen+0x13>
		n++;
  8007eb:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007ee:	39 c2                	cmp    %eax,%edx
  8007f0:	74 08                	je     8007fa <strnlen+0x1f>
  8007f2:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007f6:	75 f3                	jne    8007eb <strnlen+0x10>
  8007f8:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007fa:	5d                   	pop    %ebp
  8007fb:	c3                   	ret    

008007fc <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007fc:	55                   	push   %ebp
  8007fd:	89 e5                	mov    %esp,%ebp
  8007ff:	53                   	push   %ebx
  800800:	8b 45 08             	mov    0x8(%ebp),%eax
  800803:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800806:	89 c2                	mov    %eax,%edx
  800808:	83 c2 01             	add    $0x1,%edx
  80080b:	83 c1 01             	add    $0x1,%ecx
  80080e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800812:	88 5a ff             	mov    %bl,-0x1(%edx)
  800815:	84 db                	test   %bl,%bl
  800817:	75 ef                	jne    800808 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800819:	5b                   	pop    %ebx
  80081a:	5d                   	pop    %ebp
  80081b:	c3                   	ret    

0080081c <strcat>:

char *
strcat(char *dst, const char *src)
{
  80081c:	55                   	push   %ebp
  80081d:	89 e5                	mov    %esp,%ebp
  80081f:	53                   	push   %ebx
  800820:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800823:	53                   	push   %ebx
  800824:	e8 9a ff ff ff       	call   8007c3 <strlen>
  800829:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80082c:	ff 75 0c             	pushl  0xc(%ebp)
  80082f:	01 d8                	add    %ebx,%eax
  800831:	50                   	push   %eax
  800832:	e8 c5 ff ff ff       	call   8007fc <strcpy>
	return dst;
}
  800837:	89 d8                	mov    %ebx,%eax
  800839:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80083c:	c9                   	leave  
  80083d:	c3                   	ret    

0080083e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80083e:	55                   	push   %ebp
  80083f:	89 e5                	mov    %esp,%ebp
  800841:	56                   	push   %esi
  800842:	53                   	push   %ebx
  800843:	8b 75 08             	mov    0x8(%ebp),%esi
  800846:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800849:	89 f3                	mov    %esi,%ebx
  80084b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80084e:	89 f2                	mov    %esi,%edx
  800850:	eb 0f                	jmp    800861 <strncpy+0x23>
		*dst++ = *src;
  800852:	83 c2 01             	add    $0x1,%edx
  800855:	0f b6 01             	movzbl (%ecx),%eax
  800858:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80085b:	80 39 01             	cmpb   $0x1,(%ecx)
  80085e:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800861:	39 da                	cmp    %ebx,%edx
  800863:	75 ed                	jne    800852 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800865:	89 f0                	mov    %esi,%eax
  800867:	5b                   	pop    %ebx
  800868:	5e                   	pop    %esi
  800869:	5d                   	pop    %ebp
  80086a:	c3                   	ret    

0080086b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80086b:	55                   	push   %ebp
  80086c:	89 e5                	mov    %esp,%ebp
  80086e:	56                   	push   %esi
  80086f:	53                   	push   %ebx
  800870:	8b 75 08             	mov    0x8(%ebp),%esi
  800873:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800876:	8b 55 10             	mov    0x10(%ebp),%edx
  800879:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80087b:	85 d2                	test   %edx,%edx
  80087d:	74 21                	je     8008a0 <strlcpy+0x35>
  80087f:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800883:	89 f2                	mov    %esi,%edx
  800885:	eb 09                	jmp    800890 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800887:	83 c2 01             	add    $0x1,%edx
  80088a:	83 c1 01             	add    $0x1,%ecx
  80088d:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800890:	39 c2                	cmp    %eax,%edx
  800892:	74 09                	je     80089d <strlcpy+0x32>
  800894:	0f b6 19             	movzbl (%ecx),%ebx
  800897:	84 db                	test   %bl,%bl
  800899:	75 ec                	jne    800887 <strlcpy+0x1c>
  80089b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80089d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008a0:	29 f0                	sub    %esi,%eax
}
  8008a2:	5b                   	pop    %ebx
  8008a3:	5e                   	pop    %esi
  8008a4:	5d                   	pop    %ebp
  8008a5:	c3                   	ret    

008008a6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008a6:	55                   	push   %ebp
  8008a7:	89 e5                	mov    %esp,%ebp
  8008a9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008ac:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008af:	eb 06                	jmp    8008b7 <strcmp+0x11>
		p++, q++;
  8008b1:	83 c1 01             	add    $0x1,%ecx
  8008b4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008b7:	0f b6 01             	movzbl (%ecx),%eax
  8008ba:	84 c0                	test   %al,%al
  8008bc:	74 04                	je     8008c2 <strcmp+0x1c>
  8008be:	3a 02                	cmp    (%edx),%al
  8008c0:	74 ef                	je     8008b1 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008c2:	0f b6 c0             	movzbl %al,%eax
  8008c5:	0f b6 12             	movzbl (%edx),%edx
  8008c8:	29 d0                	sub    %edx,%eax
}
  8008ca:	5d                   	pop    %ebp
  8008cb:	c3                   	ret    

008008cc <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008cc:	55                   	push   %ebp
  8008cd:	89 e5                	mov    %esp,%ebp
  8008cf:	53                   	push   %ebx
  8008d0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008d6:	89 c3                	mov    %eax,%ebx
  8008d8:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008db:	eb 06                	jmp    8008e3 <strncmp+0x17>
		n--, p++, q++;
  8008dd:	83 c0 01             	add    $0x1,%eax
  8008e0:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008e3:	39 d8                	cmp    %ebx,%eax
  8008e5:	74 15                	je     8008fc <strncmp+0x30>
  8008e7:	0f b6 08             	movzbl (%eax),%ecx
  8008ea:	84 c9                	test   %cl,%cl
  8008ec:	74 04                	je     8008f2 <strncmp+0x26>
  8008ee:	3a 0a                	cmp    (%edx),%cl
  8008f0:	74 eb                	je     8008dd <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008f2:	0f b6 00             	movzbl (%eax),%eax
  8008f5:	0f b6 12             	movzbl (%edx),%edx
  8008f8:	29 d0                	sub    %edx,%eax
  8008fa:	eb 05                	jmp    800901 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008fc:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800901:	5b                   	pop    %ebx
  800902:	5d                   	pop    %ebp
  800903:	c3                   	ret    

00800904 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800904:	55                   	push   %ebp
  800905:	89 e5                	mov    %esp,%ebp
  800907:	8b 45 08             	mov    0x8(%ebp),%eax
  80090a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80090e:	eb 07                	jmp    800917 <strchr+0x13>
		if (*s == c)
  800910:	38 ca                	cmp    %cl,%dl
  800912:	74 0f                	je     800923 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800914:	83 c0 01             	add    $0x1,%eax
  800917:	0f b6 10             	movzbl (%eax),%edx
  80091a:	84 d2                	test   %dl,%dl
  80091c:	75 f2                	jne    800910 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80091e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800923:	5d                   	pop    %ebp
  800924:	c3                   	ret    

00800925 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800925:	55                   	push   %ebp
  800926:	89 e5                	mov    %esp,%ebp
  800928:	8b 45 08             	mov    0x8(%ebp),%eax
  80092b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80092f:	eb 03                	jmp    800934 <strfind+0xf>
  800931:	83 c0 01             	add    $0x1,%eax
  800934:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800937:	38 ca                	cmp    %cl,%dl
  800939:	74 04                	je     80093f <strfind+0x1a>
  80093b:	84 d2                	test   %dl,%dl
  80093d:	75 f2                	jne    800931 <strfind+0xc>
			break;
	return (char *) s;
}
  80093f:	5d                   	pop    %ebp
  800940:	c3                   	ret    

00800941 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800941:	55                   	push   %ebp
  800942:	89 e5                	mov    %esp,%ebp
  800944:	57                   	push   %edi
  800945:	56                   	push   %esi
  800946:	53                   	push   %ebx
  800947:	8b 7d 08             	mov    0x8(%ebp),%edi
  80094a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80094d:	85 c9                	test   %ecx,%ecx
  80094f:	74 36                	je     800987 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800951:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800957:	75 28                	jne    800981 <memset+0x40>
  800959:	f6 c1 03             	test   $0x3,%cl
  80095c:	75 23                	jne    800981 <memset+0x40>
		c &= 0xFF;
  80095e:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800962:	89 d3                	mov    %edx,%ebx
  800964:	c1 e3 08             	shl    $0x8,%ebx
  800967:	89 d6                	mov    %edx,%esi
  800969:	c1 e6 18             	shl    $0x18,%esi
  80096c:	89 d0                	mov    %edx,%eax
  80096e:	c1 e0 10             	shl    $0x10,%eax
  800971:	09 f0                	or     %esi,%eax
  800973:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800975:	89 d8                	mov    %ebx,%eax
  800977:	09 d0                	or     %edx,%eax
  800979:	c1 e9 02             	shr    $0x2,%ecx
  80097c:	fc                   	cld    
  80097d:	f3 ab                	rep stos %eax,%es:(%edi)
  80097f:	eb 06                	jmp    800987 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800981:	8b 45 0c             	mov    0xc(%ebp),%eax
  800984:	fc                   	cld    
  800985:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800987:	89 f8                	mov    %edi,%eax
  800989:	5b                   	pop    %ebx
  80098a:	5e                   	pop    %esi
  80098b:	5f                   	pop    %edi
  80098c:	5d                   	pop    %ebp
  80098d:	c3                   	ret    

0080098e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80098e:	55                   	push   %ebp
  80098f:	89 e5                	mov    %esp,%ebp
  800991:	57                   	push   %edi
  800992:	56                   	push   %esi
  800993:	8b 45 08             	mov    0x8(%ebp),%eax
  800996:	8b 75 0c             	mov    0xc(%ebp),%esi
  800999:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80099c:	39 c6                	cmp    %eax,%esi
  80099e:	73 35                	jae    8009d5 <memmove+0x47>
  8009a0:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009a3:	39 d0                	cmp    %edx,%eax
  8009a5:	73 2e                	jae    8009d5 <memmove+0x47>
		s += n;
		d += n;
  8009a7:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009aa:	89 d6                	mov    %edx,%esi
  8009ac:	09 fe                	or     %edi,%esi
  8009ae:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009b4:	75 13                	jne    8009c9 <memmove+0x3b>
  8009b6:	f6 c1 03             	test   $0x3,%cl
  8009b9:	75 0e                	jne    8009c9 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009bb:	83 ef 04             	sub    $0x4,%edi
  8009be:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009c1:	c1 e9 02             	shr    $0x2,%ecx
  8009c4:	fd                   	std    
  8009c5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009c7:	eb 09                	jmp    8009d2 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009c9:	83 ef 01             	sub    $0x1,%edi
  8009cc:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009cf:	fd                   	std    
  8009d0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009d2:	fc                   	cld    
  8009d3:	eb 1d                	jmp    8009f2 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009d5:	89 f2                	mov    %esi,%edx
  8009d7:	09 c2                	or     %eax,%edx
  8009d9:	f6 c2 03             	test   $0x3,%dl
  8009dc:	75 0f                	jne    8009ed <memmove+0x5f>
  8009de:	f6 c1 03             	test   $0x3,%cl
  8009e1:	75 0a                	jne    8009ed <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8009e3:	c1 e9 02             	shr    $0x2,%ecx
  8009e6:	89 c7                	mov    %eax,%edi
  8009e8:	fc                   	cld    
  8009e9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009eb:	eb 05                	jmp    8009f2 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009ed:	89 c7                	mov    %eax,%edi
  8009ef:	fc                   	cld    
  8009f0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009f2:	5e                   	pop    %esi
  8009f3:	5f                   	pop    %edi
  8009f4:	5d                   	pop    %ebp
  8009f5:	c3                   	ret    

008009f6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009f6:	55                   	push   %ebp
  8009f7:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009f9:	ff 75 10             	pushl  0x10(%ebp)
  8009fc:	ff 75 0c             	pushl  0xc(%ebp)
  8009ff:	ff 75 08             	pushl  0x8(%ebp)
  800a02:	e8 87 ff ff ff       	call   80098e <memmove>
}
  800a07:	c9                   	leave  
  800a08:	c3                   	ret    

00800a09 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a09:	55                   	push   %ebp
  800a0a:	89 e5                	mov    %esp,%ebp
  800a0c:	56                   	push   %esi
  800a0d:	53                   	push   %ebx
  800a0e:	8b 45 08             	mov    0x8(%ebp),%eax
  800a11:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a14:	89 c6                	mov    %eax,%esi
  800a16:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a19:	eb 1a                	jmp    800a35 <memcmp+0x2c>
		if (*s1 != *s2)
  800a1b:	0f b6 08             	movzbl (%eax),%ecx
  800a1e:	0f b6 1a             	movzbl (%edx),%ebx
  800a21:	38 d9                	cmp    %bl,%cl
  800a23:	74 0a                	je     800a2f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a25:	0f b6 c1             	movzbl %cl,%eax
  800a28:	0f b6 db             	movzbl %bl,%ebx
  800a2b:	29 d8                	sub    %ebx,%eax
  800a2d:	eb 0f                	jmp    800a3e <memcmp+0x35>
		s1++, s2++;
  800a2f:	83 c0 01             	add    $0x1,%eax
  800a32:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a35:	39 f0                	cmp    %esi,%eax
  800a37:	75 e2                	jne    800a1b <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a39:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a3e:	5b                   	pop    %ebx
  800a3f:	5e                   	pop    %esi
  800a40:	5d                   	pop    %ebp
  800a41:	c3                   	ret    

00800a42 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a42:	55                   	push   %ebp
  800a43:	89 e5                	mov    %esp,%ebp
  800a45:	53                   	push   %ebx
  800a46:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a49:	89 c1                	mov    %eax,%ecx
  800a4b:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a4e:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a52:	eb 0a                	jmp    800a5e <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a54:	0f b6 10             	movzbl (%eax),%edx
  800a57:	39 da                	cmp    %ebx,%edx
  800a59:	74 07                	je     800a62 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a5b:	83 c0 01             	add    $0x1,%eax
  800a5e:	39 c8                	cmp    %ecx,%eax
  800a60:	72 f2                	jb     800a54 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a62:	5b                   	pop    %ebx
  800a63:	5d                   	pop    %ebp
  800a64:	c3                   	ret    

00800a65 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a65:	55                   	push   %ebp
  800a66:	89 e5                	mov    %esp,%ebp
  800a68:	57                   	push   %edi
  800a69:	56                   	push   %esi
  800a6a:	53                   	push   %ebx
  800a6b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a6e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a71:	eb 03                	jmp    800a76 <strtol+0x11>
		s++;
  800a73:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a76:	0f b6 01             	movzbl (%ecx),%eax
  800a79:	3c 20                	cmp    $0x20,%al
  800a7b:	74 f6                	je     800a73 <strtol+0xe>
  800a7d:	3c 09                	cmp    $0x9,%al
  800a7f:	74 f2                	je     800a73 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a81:	3c 2b                	cmp    $0x2b,%al
  800a83:	75 0a                	jne    800a8f <strtol+0x2a>
		s++;
  800a85:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a88:	bf 00 00 00 00       	mov    $0x0,%edi
  800a8d:	eb 11                	jmp    800aa0 <strtol+0x3b>
  800a8f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a94:	3c 2d                	cmp    $0x2d,%al
  800a96:	75 08                	jne    800aa0 <strtol+0x3b>
		s++, neg = 1;
  800a98:	83 c1 01             	add    $0x1,%ecx
  800a9b:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800aa0:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800aa6:	75 15                	jne    800abd <strtol+0x58>
  800aa8:	80 39 30             	cmpb   $0x30,(%ecx)
  800aab:	75 10                	jne    800abd <strtol+0x58>
  800aad:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ab1:	75 7c                	jne    800b2f <strtol+0xca>
		s += 2, base = 16;
  800ab3:	83 c1 02             	add    $0x2,%ecx
  800ab6:	bb 10 00 00 00       	mov    $0x10,%ebx
  800abb:	eb 16                	jmp    800ad3 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800abd:	85 db                	test   %ebx,%ebx
  800abf:	75 12                	jne    800ad3 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ac1:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ac6:	80 39 30             	cmpb   $0x30,(%ecx)
  800ac9:	75 08                	jne    800ad3 <strtol+0x6e>
		s++, base = 8;
  800acb:	83 c1 01             	add    $0x1,%ecx
  800ace:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800ad3:	b8 00 00 00 00       	mov    $0x0,%eax
  800ad8:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800adb:	0f b6 11             	movzbl (%ecx),%edx
  800ade:	8d 72 d0             	lea    -0x30(%edx),%esi
  800ae1:	89 f3                	mov    %esi,%ebx
  800ae3:	80 fb 09             	cmp    $0x9,%bl
  800ae6:	77 08                	ja     800af0 <strtol+0x8b>
			dig = *s - '0';
  800ae8:	0f be d2             	movsbl %dl,%edx
  800aeb:	83 ea 30             	sub    $0x30,%edx
  800aee:	eb 22                	jmp    800b12 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800af0:	8d 72 9f             	lea    -0x61(%edx),%esi
  800af3:	89 f3                	mov    %esi,%ebx
  800af5:	80 fb 19             	cmp    $0x19,%bl
  800af8:	77 08                	ja     800b02 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800afa:	0f be d2             	movsbl %dl,%edx
  800afd:	83 ea 57             	sub    $0x57,%edx
  800b00:	eb 10                	jmp    800b12 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b02:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b05:	89 f3                	mov    %esi,%ebx
  800b07:	80 fb 19             	cmp    $0x19,%bl
  800b0a:	77 16                	ja     800b22 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b0c:	0f be d2             	movsbl %dl,%edx
  800b0f:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b12:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b15:	7d 0b                	jge    800b22 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b17:	83 c1 01             	add    $0x1,%ecx
  800b1a:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b1e:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b20:	eb b9                	jmp    800adb <strtol+0x76>

	if (endptr)
  800b22:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b26:	74 0d                	je     800b35 <strtol+0xd0>
		*endptr = (char *) s;
  800b28:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b2b:	89 0e                	mov    %ecx,(%esi)
  800b2d:	eb 06                	jmp    800b35 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b2f:	85 db                	test   %ebx,%ebx
  800b31:	74 98                	je     800acb <strtol+0x66>
  800b33:	eb 9e                	jmp    800ad3 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b35:	89 c2                	mov    %eax,%edx
  800b37:	f7 da                	neg    %edx
  800b39:	85 ff                	test   %edi,%edi
  800b3b:	0f 45 c2             	cmovne %edx,%eax
}
  800b3e:	5b                   	pop    %ebx
  800b3f:	5e                   	pop    %esi
  800b40:	5f                   	pop    %edi
  800b41:	5d                   	pop    %ebp
  800b42:	c3                   	ret    
  800b43:	66 90                	xchg   %ax,%ax
  800b45:	66 90                	xchg   %ax,%ax
  800b47:	66 90                	xchg   %ax,%ax
  800b49:	66 90                	xchg   %ax,%ax
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
