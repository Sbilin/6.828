
obj/user/dumbfork:     file format elf32-i386


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
  80002c:	e8 aa 01 00 00       	call   8001db <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <duppage>:
	}
}

void
duppage(envid_t dstenv, void *addr)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	56                   	push   %esi
  800037:	53                   	push   %ebx
  800038:	8b 75 08             	mov    0x8(%ebp),%esi
  80003b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int r;

	// This is NOT what you should do in your fork.
	if ((r = sys_page_alloc(dstenv, addr, PTE_P|PTE_U|PTE_W)) < 0)
  80003e:	83 ec 04             	sub    $0x4,%esp
  800041:	6a 07                	push   $0x7
  800043:	53                   	push   %ebx
  800044:	56                   	push   %esi
  800045:	e8 c9 0c 00 00       	call   800d13 <sys_page_alloc>
  80004a:	83 c4 10             	add    $0x10,%esp
  80004d:	85 c0                	test   %eax,%eax
  80004f:	79 12                	jns    800063 <duppage+0x30>
		panic("sys_page_alloc: %e", r);
  800051:	50                   	push   %eax
  800052:	68 60 11 80 00       	push   $0x801160
  800057:	6a 20                	push   $0x20
  800059:	68 73 11 80 00       	push   $0x801173
  80005e:	e8 d0 01 00 00       	call   800233 <_panic>
	if ((r = sys_page_map(dstenv, addr, 0, UTEMP, PTE_P|PTE_U|PTE_W)) < 0)
  800063:	83 ec 0c             	sub    $0xc,%esp
  800066:	6a 07                	push   $0x7
  800068:	68 00 00 40 00       	push   $0x400000
  80006d:	6a 00                	push   $0x0
  80006f:	53                   	push   %ebx
  800070:	56                   	push   %esi
  800071:	e8 e0 0c 00 00       	call   800d56 <sys_page_map>
  800076:	83 c4 20             	add    $0x20,%esp
  800079:	85 c0                	test   %eax,%eax
  80007b:	79 12                	jns    80008f <duppage+0x5c>
		panic("sys_page_map: %e", r);
  80007d:	50                   	push   %eax
  80007e:	68 83 11 80 00       	push   $0x801183
  800083:	6a 22                	push   $0x22
  800085:	68 73 11 80 00       	push   $0x801173
  80008a:	e8 a4 01 00 00       	call   800233 <_panic>
	memmove(UTEMP, addr, PGSIZE);
  80008f:	83 ec 04             	sub    $0x4,%esp
  800092:	68 00 10 00 00       	push   $0x1000
  800097:	53                   	push   %ebx
  800098:	68 00 00 40 00       	push   $0x400000
  80009d:	e8 00 0a 00 00       	call   800aa2 <memmove>
	if ((r = sys_page_unmap(0, UTEMP)) < 0)
  8000a2:	83 c4 08             	add    $0x8,%esp
  8000a5:	68 00 00 40 00       	push   $0x400000
  8000aa:	6a 00                	push   $0x0
  8000ac:	e8 e7 0c 00 00       	call   800d98 <sys_page_unmap>
  8000b1:	83 c4 10             	add    $0x10,%esp
  8000b4:	85 c0                	test   %eax,%eax
  8000b6:	79 12                	jns    8000ca <duppage+0x97>
		panic("sys_page_unmap: %e", r);
  8000b8:	50                   	push   %eax
  8000b9:	68 94 11 80 00       	push   $0x801194
  8000be:	6a 25                	push   $0x25
  8000c0:	68 73 11 80 00       	push   $0x801173
  8000c5:	e8 69 01 00 00       	call   800233 <_panic>
}
  8000ca:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000cd:	5b                   	pop    %ebx
  8000ce:	5e                   	pop    %esi
  8000cf:	5d                   	pop    %ebp
  8000d0:	c3                   	ret    

008000d1 <dumbfork>:

envid_t
dumbfork(void)
{
  8000d1:	55                   	push   %ebp
  8000d2:	89 e5                	mov    %esp,%ebp
  8000d4:	56                   	push   %esi
  8000d5:	53                   	push   %ebx
  8000d6:	83 ec 10             	sub    $0x10,%esp
// This must be inlined.  Exercise for reader: why?
static inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	asm volatile("int %2"
  8000d9:	b8 07 00 00 00       	mov    $0x7,%eax
  8000de:	cd 30                	int    $0x30
  8000e0:	89 c3                	mov    %eax,%ebx
	// The kernel will initialize it with a copy of our register state,
	// so that the child will appear to have called sys_exofork() too -
	// except that in the child, this "fake" call to sys_exofork()
	// will return 0 instead of the envid of the child.
	envid = sys_exofork();
	if (envid < 0)
  8000e2:	85 c0                	test   %eax,%eax
  8000e4:	79 12                	jns    8000f8 <dumbfork+0x27>
		panic("sys_exofork: %e", envid);
  8000e6:	50                   	push   %eax
  8000e7:	68 a7 11 80 00       	push   $0x8011a7
  8000ec:	6a 37                	push   $0x37
  8000ee:	68 73 11 80 00       	push   $0x801173
  8000f3:	e8 3b 01 00 00       	call   800233 <_panic>
  8000f8:	89 c6                	mov    %eax,%esi
	if (envid == 0) {
  8000fa:	85 c0                	test   %eax,%eax
  8000fc:	75 1e                	jne    80011c <dumbfork+0x4b>
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
  8000fe:	e8 d2 0b 00 00       	call   800cd5 <sys_getenvid>
  800103:	25 ff 03 00 00       	and    $0x3ff,%eax
  800108:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80010b:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800110:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  800115:	b8 00 00 00 00       	mov    $0x0,%eax
  80011a:	eb 60                	jmp    80017c <dumbfork+0xab>
	}

	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.
	for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE)
  80011c:	c7 45 f4 00 00 80 00 	movl   $0x800000,-0xc(%ebp)
  800123:	eb 14                	jmp    800139 <dumbfork+0x68>
		duppage(envid, addr);
  800125:	83 ec 08             	sub    $0x8,%esp
  800128:	52                   	push   %edx
  800129:	56                   	push   %esi
  80012a:	e8 04 ff ff ff       	call   800033 <duppage>
	}

	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.
	for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE)
  80012f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
  800136:	83 c4 10             	add    $0x10,%esp
  800139:	8b 55 f4             	mov    -0xc(%ebp),%edx
  80013c:	81 fa 08 20 80 00    	cmp    $0x802008,%edx
  800142:	72 e1                	jb     800125 <dumbfork+0x54>
		duppage(envid, addr);

	// Also copy the stack we are currently running on.
	duppage(envid, ROUNDDOWN(&addr, PGSIZE));
  800144:	83 ec 08             	sub    $0x8,%esp
  800147:	8d 45 f4             	lea    -0xc(%ebp),%eax
  80014a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  80014f:	50                   	push   %eax
  800150:	53                   	push   %ebx
  800151:	e8 dd fe ff ff       	call   800033 <duppage>

	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
  800156:	83 c4 08             	add    $0x8,%esp
  800159:	6a 02                	push   $0x2
  80015b:	53                   	push   %ebx
  80015c:	e8 79 0c 00 00       	call   800dda <sys_env_set_status>
  800161:	83 c4 10             	add    $0x10,%esp
  800164:	85 c0                	test   %eax,%eax
  800166:	79 12                	jns    80017a <dumbfork+0xa9>
		panic("sys_env_set_status: %e", r);
  800168:	50                   	push   %eax
  800169:	68 b7 11 80 00       	push   $0x8011b7
  80016e:	6a 4c                	push   $0x4c
  800170:	68 73 11 80 00       	push   $0x801173
  800175:	e8 b9 00 00 00       	call   800233 <_panic>

	return envid;
  80017a:	89 d8                	mov    %ebx,%eax
}
  80017c:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80017f:	5b                   	pop    %ebx
  800180:	5e                   	pop    %esi
  800181:	5d                   	pop    %ebp
  800182:	c3                   	ret    

00800183 <umain>:

envid_t dumbfork(void);

void
umain(int argc, char **argv)
{
  800183:	55                   	push   %ebp
  800184:	89 e5                	mov    %esp,%ebp
  800186:	57                   	push   %edi
  800187:	56                   	push   %esi
  800188:	53                   	push   %ebx
  800189:	83 ec 0c             	sub    $0xc,%esp
	envid_t who;
	int i;

	// fork a child process
	who = dumbfork();
  80018c:	e8 40 ff ff ff       	call   8000d1 <dumbfork>
  800191:	89 c7                	mov    %eax,%edi
  800193:	85 c0                	test   %eax,%eax
  800195:	be d5 11 80 00       	mov    $0x8011d5,%esi
  80019a:	b8 ce 11 80 00       	mov    $0x8011ce,%eax
  80019f:	0f 45 f0             	cmovne %eax,%esi

	// print a message and yield to the other a few times
	for (i = 0; i < (who ? 10 : 20); i++) {
  8001a2:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001a7:	eb 1a                	jmp    8001c3 <umain+0x40>
		cprintf("%d: I am the %s!\n", i, who ? "parent" : "child");
  8001a9:	83 ec 04             	sub    $0x4,%esp
  8001ac:	56                   	push   %esi
  8001ad:	53                   	push   %ebx
  8001ae:	68 db 11 80 00       	push   $0x8011db
  8001b3:	e8 54 01 00 00       	call   80030c <cprintf>
		sys_yield();
  8001b8:	e8 37 0b 00 00       	call   800cf4 <sys_yield>

	// fork a child process
	who = dumbfork();

	// print a message and yield to the other a few times
	for (i = 0; i < (who ? 10 : 20); i++) {
  8001bd:	83 c3 01             	add    $0x1,%ebx
  8001c0:	83 c4 10             	add    $0x10,%esp
  8001c3:	85 ff                	test   %edi,%edi
  8001c5:	74 07                	je     8001ce <umain+0x4b>
  8001c7:	83 fb 09             	cmp    $0x9,%ebx
  8001ca:	7e dd                	jle    8001a9 <umain+0x26>
  8001cc:	eb 05                	jmp    8001d3 <umain+0x50>
  8001ce:	83 fb 13             	cmp    $0x13,%ebx
  8001d1:	7e d6                	jle    8001a9 <umain+0x26>
		cprintf("%d: I am the %s!\n", i, who ? "parent" : "child");
		sys_yield();
	}
}
  8001d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001d6:	5b                   	pop    %ebx
  8001d7:	5e                   	pop    %esi
  8001d8:	5f                   	pop    %edi
  8001d9:	5d                   	pop    %ebp
  8001da:	c3                   	ret    

008001db <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8001db:	55                   	push   %ebp
  8001dc:	89 e5                	mov    %esp,%ebp
  8001de:	56                   	push   %esi
  8001df:	53                   	push   %ebx
  8001e0:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8001e3:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = envs+ENVX(sys_getenvid());
  8001e6:	e8 ea 0a 00 00       	call   800cd5 <sys_getenvid>
  8001eb:	25 ff 03 00 00       	and    $0x3ff,%eax
  8001f0:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8001f3:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8001f8:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  8001fd:	85 db                	test   %ebx,%ebx
  8001ff:	7e 07                	jle    800208 <libmain+0x2d>
		binaryname = argv[0];
  800201:	8b 06                	mov    (%esi),%eax
  800203:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800208:	83 ec 08             	sub    $0x8,%esp
  80020b:	56                   	push   %esi
  80020c:	53                   	push   %ebx
  80020d:	e8 71 ff ff ff       	call   800183 <umain>

	// exit gracefully
	exit();
  800212:	e8 0a 00 00 00       	call   800221 <exit>
}
  800217:	83 c4 10             	add    $0x10,%esp
  80021a:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80021d:	5b                   	pop    %ebx
  80021e:	5e                   	pop    %esi
  80021f:	5d                   	pop    %ebp
  800220:	c3                   	ret    

00800221 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800221:	55                   	push   %ebp
  800222:	89 e5                	mov    %esp,%ebp
  800224:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800227:	6a 00                	push   $0x0
  800229:	e8 66 0a 00 00       	call   800c94 <sys_env_destroy>
}
  80022e:	83 c4 10             	add    $0x10,%esp
  800231:	c9                   	leave  
  800232:	c3                   	ret    

00800233 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800233:	55                   	push   %ebp
  800234:	89 e5                	mov    %esp,%ebp
  800236:	56                   	push   %esi
  800237:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800238:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80023b:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800241:	e8 8f 0a 00 00       	call   800cd5 <sys_getenvid>
  800246:	83 ec 0c             	sub    $0xc,%esp
  800249:	ff 75 0c             	pushl  0xc(%ebp)
  80024c:	ff 75 08             	pushl  0x8(%ebp)
  80024f:	56                   	push   %esi
  800250:	50                   	push   %eax
  800251:	68 f8 11 80 00       	push   $0x8011f8
  800256:	e8 b1 00 00 00       	call   80030c <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80025b:	83 c4 18             	add    $0x18,%esp
  80025e:	53                   	push   %ebx
  80025f:	ff 75 10             	pushl  0x10(%ebp)
  800262:	e8 54 00 00 00       	call   8002bb <vcprintf>
	cprintf("\n");
  800267:	c7 04 24 eb 11 80 00 	movl   $0x8011eb,(%esp)
  80026e:	e8 99 00 00 00       	call   80030c <cprintf>
  800273:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800276:	cc                   	int3   
  800277:	eb fd                	jmp    800276 <_panic+0x43>

00800279 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800279:	55                   	push   %ebp
  80027a:	89 e5                	mov    %esp,%ebp
  80027c:	53                   	push   %ebx
  80027d:	83 ec 04             	sub    $0x4,%esp
  800280:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800283:	8b 13                	mov    (%ebx),%edx
  800285:	8d 42 01             	lea    0x1(%edx),%eax
  800288:	89 03                	mov    %eax,(%ebx)
  80028a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80028d:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800291:	3d ff 00 00 00       	cmp    $0xff,%eax
  800296:	75 1a                	jne    8002b2 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800298:	83 ec 08             	sub    $0x8,%esp
  80029b:	68 ff 00 00 00       	push   $0xff
  8002a0:	8d 43 08             	lea    0x8(%ebx),%eax
  8002a3:	50                   	push   %eax
  8002a4:	e8 ae 09 00 00       	call   800c57 <sys_cputs>
		b->idx = 0;
  8002a9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8002af:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8002b2:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8002b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8002b9:	c9                   	leave  
  8002ba:	c3                   	ret    

008002bb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8002bb:	55                   	push   %ebp
  8002bc:	89 e5                	mov    %esp,%ebp
  8002be:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8002c4:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8002cb:	00 00 00 
	b.cnt = 0;
  8002ce:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8002d5:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8002d8:	ff 75 0c             	pushl  0xc(%ebp)
  8002db:	ff 75 08             	pushl  0x8(%ebp)
  8002de:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8002e4:	50                   	push   %eax
  8002e5:	68 79 02 80 00       	push   $0x800279
  8002ea:	e8 1a 01 00 00       	call   800409 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8002ef:	83 c4 08             	add    $0x8,%esp
  8002f2:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8002f8:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8002fe:	50                   	push   %eax
  8002ff:	e8 53 09 00 00       	call   800c57 <sys_cputs>

	return b.cnt;
}
  800304:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80030a:	c9                   	leave  
  80030b:	c3                   	ret    

0080030c <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80030c:	55                   	push   %ebp
  80030d:	89 e5                	mov    %esp,%ebp
  80030f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800312:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800315:	50                   	push   %eax
  800316:	ff 75 08             	pushl  0x8(%ebp)
  800319:	e8 9d ff ff ff       	call   8002bb <vcprintf>
	va_end(ap);

	return cnt;
}
  80031e:	c9                   	leave  
  80031f:	c3                   	ret    

00800320 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800320:	55                   	push   %ebp
  800321:	89 e5                	mov    %esp,%ebp
  800323:	57                   	push   %edi
  800324:	56                   	push   %esi
  800325:	53                   	push   %ebx
  800326:	83 ec 1c             	sub    $0x1c,%esp
  800329:	89 c7                	mov    %eax,%edi
  80032b:	89 d6                	mov    %edx,%esi
  80032d:	8b 45 08             	mov    0x8(%ebp),%eax
  800330:	8b 55 0c             	mov    0xc(%ebp),%edx
  800333:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800336:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800339:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80033c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800341:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800344:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800347:	39 d3                	cmp    %edx,%ebx
  800349:	72 05                	jb     800350 <printnum+0x30>
  80034b:	39 45 10             	cmp    %eax,0x10(%ebp)
  80034e:	77 45                	ja     800395 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800350:	83 ec 0c             	sub    $0xc,%esp
  800353:	ff 75 18             	pushl  0x18(%ebp)
  800356:	8b 45 14             	mov    0x14(%ebp),%eax
  800359:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80035c:	53                   	push   %ebx
  80035d:	ff 75 10             	pushl  0x10(%ebp)
  800360:	83 ec 08             	sub    $0x8,%esp
  800363:	ff 75 e4             	pushl  -0x1c(%ebp)
  800366:	ff 75 e0             	pushl  -0x20(%ebp)
  800369:	ff 75 dc             	pushl  -0x24(%ebp)
  80036c:	ff 75 d8             	pushl  -0x28(%ebp)
  80036f:	e8 5c 0b 00 00       	call   800ed0 <__udivdi3>
  800374:	83 c4 18             	add    $0x18,%esp
  800377:	52                   	push   %edx
  800378:	50                   	push   %eax
  800379:	89 f2                	mov    %esi,%edx
  80037b:	89 f8                	mov    %edi,%eax
  80037d:	e8 9e ff ff ff       	call   800320 <printnum>
  800382:	83 c4 20             	add    $0x20,%esp
  800385:	eb 18                	jmp    80039f <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800387:	83 ec 08             	sub    $0x8,%esp
  80038a:	56                   	push   %esi
  80038b:	ff 75 18             	pushl  0x18(%ebp)
  80038e:	ff d7                	call   *%edi
  800390:	83 c4 10             	add    $0x10,%esp
  800393:	eb 03                	jmp    800398 <printnum+0x78>
  800395:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800398:	83 eb 01             	sub    $0x1,%ebx
  80039b:	85 db                	test   %ebx,%ebx
  80039d:	7f e8                	jg     800387 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80039f:	83 ec 08             	sub    $0x8,%esp
  8003a2:	56                   	push   %esi
  8003a3:	83 ec 04             	sub    $0x4,%esp
  8003a6:	ff 75 e4             	pushl  -0x1c(%ebp)
  8003a9:	ff 75 e0             	pushl  -0x20(%ebp)
  8003ac:	ff 75 dc             	pushl  -0x24(%ebp)
  8003af:	ff 75 d8             	pushl  -0x28(%ebp)
  8003b2:	e8 49 0c 00 00       	call   801000 <__umoddi3>
  8003b7:	83 c4 14             	add    $0x14,%esp
  8003ba:	0f be 80 1c 12 80 00 	movsbl 0x80121c(%eax),%eax
  8003c1:	50                   	push   %eax
  8003c2:	ff d7                	call   *%edi
}
  8003c4:	83 c4 10             	add    $0x10,%esp
  8003c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8003ca:	5b                   	pop    %ebx
  8003cb:	5e                   	pop    %esi
  8003cc:	5f                   	pop    %edi
  8003cd:	5d                   	pop    %ebp
  8003ce:	c3                   	ret    

008003cf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003cf:	55                   	push   %ebp
  8003d0:	89 e5                	mov    %esp,%ebp
  8003d2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003d5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003d9:	8b 10                	mov    (%eax),%edx
  8003db:	3b 50 04             	cmp    0x4(%eax),%edx
  8003de:	73 0a                	jae    8003ea <sprintputch+0x1b>
		*b->buf++ = ch;
  8003e0:	8d 4a 01             	lea    0x1(%edx),%ecx
  8003e3:	89 08                	mov    %ecx,(%eax)
  8003e5:	8b 45 08             	mov    0x8(%ebp),%eax
  8003e8:	88 02                	mov    %al,(%edx)
}
  8003ea:	5d                   	pop    %ebp
  8003eb:	c3                   	ret    

008003ec <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003ec:	55                   	push   %ebp
  8003ed:	89 e5                	mov    %esp,%ebp
  8003ef:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8003f2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003f5:	50                   	push   %eax
  8003f6:	ff 75 10             	pushl  0x10(%ebp)
  8003f9:	ff 75 0c             	pushl  0xc(%ebp)
  8003fc:	ff 75 08             	pushl  0x8(%ebp)
  8003ff:	e8 05 00 00 00       	call   800409 <vprintfmt>
	va_end(ap);
}
  800404:	83 c4 10             	add    $0x10,%esp
  800407:	c9                   	leave  
  800408:	c3                   	ret    

00800409 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800409:	55                   	push   %ebp
  80040a:	89 e5                	mov    %esp,%ebp
  80040c:	57                   	push   %edi
  80040d:	56                   	push   %esi
  80040e:	53                   	push   %ebx
  80040f:	83 ec 2c             	sub    $0x2c,%esp
  800412:	8b 75 08             	mov    0x8(%ebp),%esi
  800415:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800418:	8b 7d 10             	mov    0x10(%ebp),%edi
  80041b:	eb 12                	jmp    80042f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80041d:	85 c0                	test   %eax,%eax
  80041f:	0f 84 42 04 00 00    	je     800867 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800425:	83 ec 08             	sub    $0x8,%esp
  800428:	53                   	push   %ebx
  800429:	50                   	push   %eax
  80042a:	ff d6                	call   *%esi
  80042c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80042f:	83 c7 01             	add    $0x1,%edi
  800432:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800436:	83 f8 25             	cmp    $0x25,%eax
  800439:	75 e2                	jne    80041d <vprintfmt+0x14>
  80043b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80043f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800446:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80044d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800454:	b9 00 00 00 00       	mov    $0x0,%ecx
  800459:	eb 07                	jmp    800462 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80045e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800462:	8d 47 01             	lea    0x1(%edi),%eax
  800465:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800468:	0f b6 07             	movzbl (%edi),%eax
  80046b:	0f b6 d0             	movzbl %al,%edx
  80046e:	83 e8 23             	sub    $0x23,%eax
  800471:	3c 55                	cmp    $0x55,%al
  800473:	0f 87 d3 03 00 00    	ja     80084c <vprintfmt+0x443>
  800479:	0f b6 c0             	movzbl %al,%eax
  80047c:	ff 24 85 e0 12 80 00 	jmp    *0x8012e0(,%eax,4)
  800483:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800486:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80048a:	eb d6                	jmp    800462 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80048c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80048f:	b8 00 00 00 00       	mov    $0x0,%eax
  800494:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800497:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80049a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80049e:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8004a1:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8004a4:	83 f9 09             	cmp    $0x9,%ecx
  8004a7:	77 3f                	ja     8004e8 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8004a9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8004ac:	eb e9                	jmp    800497 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8004ae:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b1:	8b 00                	mov    (%eax),%eax
  8004b3:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8004b6:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b9:	8d 40 04             	lea    0x4(%eax),%eax
  8004bc:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004c2:	eb 2a                	jmp    8004ee <vprintfmt+0xe5>
  8004c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8004c7:	85 c0                	test   %eax,%eax
  8004c9:	ba 00 00 00 00       	mov    $0x0,%edx
  8004ce:	0f 49 d0             	cmovns %eax,%edx
  8004d1:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004d7:	eb 89                	jmp    800462 <vprintfmt+0x59>
  8004d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8004dc:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8004e3:	e9 7a ff ff ff       	jmp    800462 <vprintfmt+0x59>
  8004e8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8004eb:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8004ee:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004f2:	0f 89 6a ff ff ff    	jns    800462 <vprintfmt+0x59>
				width = precision, precision = -1;
  8004f8:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8004fb:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004fe:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800505:	e9 58 ff ff ff       	jmp    800462 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80050a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80050d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800510:	e9 4d ff ff ff       	jmp    800462 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800515:	8b 45 14             	mov    0x14(%ebp),%eax
  800518:	8d 78 04             	lea    0x4(%eax),%edi
  80051b:	83 ec 08             	sub    $0x8,%esp
  80051e:	53                   	push   %ebx
  80051f:	ff 30                	pushl  (%eax)
  800521:	ff d6                	call   *%esi
			break;
  800523:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800526:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800529:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80052c:	e9 fe fe ff ff       	jmp    80042f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800531:	8b 45 14             	mov    0x14(%ebp),%eax
  800534:	8d 78 04             	lea    0x4(%eax),%edi
  800537:	8b 00                	mov    (%eax),%eax
  800539:	99                   	cltd   
  80053a:	31 d0                	xor    %edx,%eax
  80053c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80053e:	83 f8 08             	cmp    $0x8,%eax
  800541:	7f 0b                	jg     80054e <vprintfmt+0x145>
  800543:	8b 14 85 40 14 80 00 	mov    0x801440(,%eax,4),%edx
  80054a:	85 d2                	test   %edx,%edx
  80054c:	75 1b                	jne    800569 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80054e:	50                   	push   %eax
  80054f:	68 34 12 80 00       	push   $0x801234
  800554:	53                   	push   %ebx
  800555:	56                   	push   %esi
  800556:	e8 91 fe ff ff       	call   8003ec <printfmt>
  80055b:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80055e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800561:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800564:	e9 c6 fe ff ff       	jmp    80042f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800569:	52                   	push   %edx
  80056a:	68 3d 12 80 00       	push   $0x80123d
  80056f:	53                   	push   %ebx
  800570:	56                   	push   %esi
  800571:	e8 76 fe ff ff       	call   8003ec <printfmt>
  800576:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800579:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80057c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80057f:	e9 ab fe ff ff       	jmp    80042f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800584:	8b 45 14             	mov    0x14(%ebp),%eax
  800587:	83 c0 04             	add    $0x4,%eax
  80058a:	89 45 cc             	mov    %eax,-0x34(%ebp)
  80058d:	8b 45 14             	mov    0x14(%ebp),%eax
  800590:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800592:	85 ff                	test   %edi,%edi
  800594:	b8 2d 12 80 00       	mov    $0x80122d,%eax
  800599:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80059c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005a0:	0f 8e 94 00 00 00    	jle    80063a <vprintfmt+0x231>
  8005a6:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8005aa:	0f 84 98 00 00 00    	je     800648 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8005b0:	83 ec 08             	sub    $0x8,%esp
  8005b3:	ff 75 d0             	pushl  -0x30(%ebp)
  8005b6:	57                   	push   %edi
  8005b7:	e8 33 03 00 00       	call   8008ef <strnlen>
  8005bc:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8005bf:	29 c1                	sub    %eax,%ecx
  8005c1:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8005c4:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8005c7:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8005cb:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005ce:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8005d1:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005d3:	eb 0f                	jmp    8005e4 <vprintfmt+0x1db>
					putch(padc, putdat);
  8005d5:	83 ec 08             	sub    $0x8,%esp
  8005d8:	53                   	push   %ebx
  8005d9:	ff 75 e0             	pushl  -0x20(%ebp)
  8005dc:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005de:	83 ef 01             	sub    $0x1,%edi
  8005e1:	83 c4 10             	add    $0x10,%esp
  8005e4:	85 ff                	test   %edi,%edi
  8005e6:	7f ed                	jg     8005d5 <vprintfmt+0x1cc>
  8005e8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8005eb:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8005ee:	85 c9                	test   %ecx,%ecx
  8005f0:	b8 00 00 00 00       	mov    $0x0,%eax
  8005f5:	0f 49 c1             	cmovns %ecx,%eax
  8005f8:	29 c1                	sub    %eax,%ecx
  8005fa:	89 75 08             	mov    %esi,0x8(%ebp)
  8005fd:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800600:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800603:	89 cb                	mov    %ecx,%ebx
  800605:	eb 4d                	jmp    800654 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800607:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80060b:	74 1b                	je     800628 <vprintfmt+0x21f>
  80060d:	0f be c0             	movsbl %al,%eax
  800610:	83 e8 20             	sub    $0x20,%eax
  800613:	83 f8 5e             	cmp    $0x5e,%eax
  800616:	76 10                	jbe    800628 <vprintfmt+0x21f>
					putch('?', putdat);
  800618:	83 ec 08             	sub    $0x8,%esp
  80061b:	ff 75 0c             	pushl  0xc(%ebp)
  80061e:	6a 3f                	push   $0x3f
  800620:	ff 55 08             	call   *0x8(%ebp)
  800623:	83 c4 10             	add    $0x10,%esp
  800626:	eb 0d                	jmp    800635 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800628:	83 ec 08             	sub    $0x8,%esp
  80062b:	ff 75 0c             	pushl  0xc(%ebp)
  80062e:	52                   	push   %edx
  80062f:	ff 55 08             	call   *0x8(%ebp)
  800632:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800635:	83 eb 01             	sub    $0x1,%ebx
  800638:	eb 1a                	jmp    800654 <vprintfmt+0x24b>
  80063a:	89 75 08             	mov    %esi,0x8(%ebp)
  80063d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800640:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800643:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800646:	eb 0c                	jmp    800654 <vprintfmt+0x24b>
  800648:	89 75 08             	mov    %esi,0x8(%ebp)
  80064b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80064e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800651:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800654:	83 c7 01             	add    $0x1,%edi
  800657:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80065b:	0f be d0             	movsbl %al,%edx
  80065e:	85 d2                	test   %edx,%edx
  800660:	74 23                	je     800685 <vprintfmt+0x27c>
  800662:	85 f6                	test   %esi,%esi
  800664:	78 a1                	js     800607 <vprintfmt+0x1fe>
  800666:	83 ee 01             	sub    $0x1,%esi
  800669:	79 9c                	jns    800607 <vprintfmt+0x1fe>
  80066b:	89 df                	mov    %ebx,%edi
  80066d:	8b 75 08             	mov    0x8(%ebp),%esi
  800670:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800673:	eb 18                	jmp    80068d <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800675:	83 ec 08             	sub    $0x8,%esp
  800678:	53                   	push   %ebx
  800679:	6a 20                	push   $0x20
  80067b:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80067d:	83 ef 01             	sub    $0x1,%edi
  800680:	83 c4 10             	add    $0x10,%esp
  800683:	eb 08                	jmp    80068d <vprintfmt+0x284>
  800685:	89 df                	mov    %ebx,%edi
  800687:	8b 75 08             	mov    0x8(%ebp),%esi
  80068a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80068d:	85 ff                	test   %edi,%edi
  80068f:	7f e4                	jg     800675 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800691:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800694:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800697:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80069a:	e9 90 fd ff ff       	jmp    80042f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80069f:	83 f9 01             	cmp    $0x1,%ecx
  8006a2:	7e 19                	jle    8006bd <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8006a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a7:	8b 50 04             	mov    0x4(%eax),%edx
  8006aa:	8b 00                	mov    (%eax),%eax
  8006ac:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8006af:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8006b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b5:	8d 40 08             	lea    0x8(%eax),%eax
  8006b8:	89 45 14             	mov    %eax,0x14(%ebp)
  8006bb:	eb 38                	jmp    8006f5 <vprintfmt+0x2ec>
	else if (lflag)
  8006bd:	85 c9                	test   %ecx,%ecx
  8006bf:	74 1b                	je     8006dc <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8006c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c4:	8b 00                	mov    (%eax),%eax
  8006c6:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8006c9:	89 c1                	mov    %eax,%ecx
  8006cb:	c1 f9 1f             	sar    $0x1f,%ecx
  8006ce:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8006d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d4:	8d 40 04             	lea    0x4(%eax),%eax
  8006d7:	89 45 14             	mov    %eax,0x14(%ebp)
  8006da:	eb 19                	jmp    8006f5 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8006dc:	8b 45 14             	mov    0x14(%ebp),%eax
  8006df:	8b 00                	mov    (%eax),%eax
  8006e1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8006e4:	89 c1                	mov    %eax,%ecx
  8006e6:	c1 f9 1f             	sar    $0x1f,%ecx
  8006e9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8006ec:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ef:	8d 40 04             	lea    0x4(%eax),%eax
  8006f2:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8006f5:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8006f8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006fb:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800700:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800704:	0f 89 0e 01 00 00    	jns    800818 <vprintfmt+0x40f>
				putch('-', putdat);
  80070a:	83 ec 08             	sub    $0x8,%esp
  80070d:	53                   	push   %ebx
  80070e:	6a 2d                	push   $0x2d
  800710:	ff d6                	call   *%esi
				num = -(long long) num;
  800712:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800715:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800718:	f7 da                	neg    %edx
  80071a:	83 d1 00             	adc    $0x0,%ecx
  80071d:	f7 d9                	neg    %ecx
  80071f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800722:	b8 0a 00 00 00       	mov    $0xa,%eax
  800727:	e9 ec 00 00 00       	jmp    800818 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80072c:	83 f9 01             	cmp    $0x1,%ecx
  80072f:	7e 18                	jle    800749 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800731:	8b 45 14             	mov    0x14(%ebp),%eax
  800734:	8b 10                	mov    (%eax),%edx
  800736:	8b 48 04             	mov    0x4(%eax),%ecx
  800739:	8d 40 08             	lea    0x8(%eax),%eax
  80073c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80073f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800744:	e9 cf 00 00 00       	jmp    800818 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800749:	85 c9                	test   %ecx,%ecx
  80074b:	74 1a                	je     800767 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80074d:	8b 45 14             	mov    0x14(%ebp),%eax
  800750:	8b 10                	mov    (%eax),%edx
  800752:	b9 00 00 00 00       	mov    $0x0,%ecx
  800757:	8d 40 04             	lea    0x4(%eax),%eax
  80075a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80075d:	b8 0a 00 00 00       	mov    $0xa,%eax
  800762:	e9 b1 00 00 00       	jmp    800818 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800767:	8b 45 14             	mov    0x14(%ebp),%eax
  80076a:	8b 10                	mov    (%eax),%edx
  80076c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800771:	8d 40 04             	lea    0x4(%eax),%eax
  800774:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800777:	b8 0a 00 00 00       	mov    $0xa,%eax
  80077c:	e9 97 00 00 00       	jmp    800818 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800781:	83 ec 08             	sub    $0x8,%esp
  800784:	53                   	push   %ebx
  800785:	6a 58                	push   $0x58
  800787:	ff d6                	call   *%esi
			putch('X', putdat);
  800789:	83 c4 08             	add    $0x8,%esp
  80078c:	53                   	push   %ebx
  80078d:	6a 58                	push   $0x58
  80078f:	ff d6                	call   *%esi
			putch('X', putdat);
  800791:	83 c4 08             	add    $0x8,%esp
  800794:	53                   	push   %ebx
  800795:	6a 58                	push   $0x58
  800797:	ff d6                	call   *%esi
			break;
  800799:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80079c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  80079f:	e9 8b fc ff ff       	jmp    80042f <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8007a4:	83 ec 08             	sub    $0x8,%esp
  8007a7:	53                   	push   %ebx
  8007a8:	6a 30                	push   $0x30
  8007aa:	ff d6                	call   *%esi
			putch('x', putdat);
  8007ac:	83 c4 08             	add    $0x8,%esp
  8007af:	53                   	push   %ebx
  8007b0:	6a 78                	push   $0x78
  8007b2:	ff d6                	call   *%esi
			num = (unsigned long long)
  8007b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007b7:	8b 10                	mov    (%eax),%edx
  8007b9:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8007be:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007c1:	8d 40 04             	lea    0x4(%eax),%eax
  8007c4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8007c7:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8007cc:	eb 4a                	jmp    800818 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8007ce:	83 f9 01             	cmp    $0x1,%ecx
  8007d1:	7e 15                	jle    8007e8 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8007d3:	8b 45 14             	mov    0x14(%ebp),%eax
  8007d6:	8b 10                	mov    (%eax),%edx
  8007d8:	8b 48 04             	mov    0x4(%eax),%ecx
  8007db:	8d 40 08             	lea    0x8(%eax),%eax
  8007de:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8007e1:	b8 10 00 00 00       	mov    $0x10,%eax
  8007e6:	eb 30                	jmp    800818 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8007e8:	85 c9                	test   %ecx,%ecx
  8007ea:	74 17                	je     800803 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8007ec:	8b 45 14             	mov    0x14(%ebp),%eax
  8007ef:	8b 10                	mov    (%eax),%edx
  8007f1:	b9 00 00 00 00       	mov    $0x0,%ecx
  8007f6:	8d 40 04             	lea    0x4(%eax),%eax
  8007f9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8007fc:	b8 10 00 00 00       	mov    $0x10,%eax
  800801:	eb 15                	jmp    800818 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800803:	8b 45 14             	mov    0x14(%ebp),%eax
  800806:	8b 10                	mov    (%eax),%edx
  800808:	b9 00 00 00 00       	mov    $0x0,%ecx
  80080d:	8d 40 04             	lea    0x4(%eax),%eax
  800810:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800813:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800818:	83 ec 0c             	sub    $0xc,%esp
  80081b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80081f:	57                   	push   %edi
  800820:	ff 75 e0             	pushl  -0x20(%ebp)
  800823:	50                   	push   %eax
  800824:	51                   	push   %ecx
  800825:	52                   	push   %edx
  800826:	89 da                	mov    %ebx,%edx
  800828:	89 f0                	mov    %esi,%eax
  80082a:	e8 f1 fa ff ff       	call   800320 <printnum>
			break;
  80082f:	83 c4 20             	add    $0x20,%esp
  800832:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800835:	e9 f5 fb ff ff       	jmp    80042f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80083a:	83 ec 08             	sub    $0x8,%esp
  80083d:	53                   	push   %ebx
  80083e:	52                   	push   %edx
  80083f:	ff d6                	call   *%esi
			break;
  800841:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800844:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800847:	e9 e3 fb ff ff       	jmp    80042f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80084c:	83 ec 08             	sub    $0x8,%esp
  80084f:	53                   	push   %ebx
  800850:	6a 25                	push   $0x25
  800852:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800854:	83 c4 10             	add    $0x10,%esp
  800857:	eb 03                	jmp    80085c <vprintfmt+0x453>
  800859:	83 ef 01             	sub    $0x1,%edi
  80085c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800860:	75 f7                	jne    800859 <vprintfmt+0x450>
  800862:	e9 c8 fb ff ff       	jmp    80042f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800867:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80086a:	5b                   	pop    %ebx
  80086b:	5e                   	pop    %esi
  80086c:	5f                   	pop    %edi
  80086d:	5d                   	pop    %ebp
  80086e:	c3                   	ret    

0080086f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80086f:	55                   	push   %ebp
  800870:	89 e5                	mov    %esp,%ebp
  800872:	83 ec 18             	sub    $0x18,%esp
  800875:	8b 45 08             	mov    0x8(%ebp),%eax
  800878:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80087b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80087e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800882:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800885:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80088c:	85 c0                	test   %eax,%eax
  80088e:	74 26                	je     8008b6 <vsnprintf+0x47>
  800890:	85 d2                	test   %edx,%edx
  800892:	7e 22                	jle    8008b6 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800894:	ff 75 14             	pushl  0x14(%ebp)
  800897:	ff 75 10             	pushl  0x10(%ebp)
  80089a:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80089d:	50                   	push   %eax
  80089e:	68 cf 03 80 00       	push   $0x8003cf
  8008a3:	e8 61 fb ff ff       	call   800409 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8008a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8008ab:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8008ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8008b1:	83 c4 10             	add    $0x10,%esp
  8008b4:	eb 05                	jmp    8008bb <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8008b6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8008bb:	c9                   	leave  
  8008bc:	c3                   	ret    

008008bd <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8008bd:	55                   	push   %ebp
  8008be:	89 e5                	mov    %esp,%ebp
  8008c0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8008c3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8008c6:	50                   	push   %eax
  8008c7:	ff 75 10             	pushl  0x10(%ebp)
  8008ca:	ff 75 0c             	pushl  0xc(%ebp)
  8008cd:	ff 75 08             	pushl  0x8(%ebp)
  8008d0:	e8 9a ff ff ff       	call   80086f <vsnprintf>
	va_end(ap);

	return rc;
}
  8008d5:	c9                   	leave  
  8008d6:	c3                   	ret    

008008d7 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008d7:	55                   	push   %ebp
  8008d8:	89 e5                	mov    %esp,%ebp
  8008da:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008dd:	b8 00 00 00 00       	mov    $0x0,%eax
  8008e2:	eb 03                	jmp    8008e7 <strlen+0x10>
		n++;
  8008e4:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008e7:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008eb:	75 f7                	jne    8008e4 <strlen+0xd>
		n++;
	return n;
}
  8008ed:	5d                   	pop    %ebp
  8008ee:	c3                   	ret    

008008ef <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008ef:	55                   	push   %ebp
  8008f0:	89 e5                	mov    %esp,%ebp
  8008f2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008f5:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008f8:	ba 00 00 00 00       	mov    $0x0,%edx
  8008fd:	eb 03                	jmp    800902 <strnlen+0x13>
		n++;
  8008ff:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800902:	39 c2                	cmp    %eax,%edx
  800904:	74 08                	je     80090e <strnlen+0x1f>
  800906:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80090a:	75 f3                	jne    8008ff <strnlen+0x10>
  80090c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80090e:	5d                   	pop    %ebp
  80090f:	c3                   	ret    

00800910 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800910:	55                   	push   %ebp
  800911:	89 e5                	mov    %esp,%ebp
  800913:	53                   	push   %ebx
  800914:	8b 45 08             	mov    0x8(%ebp),%eax
  800917:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80091a:	89 c2                	mov    %eax,%edx
  80091c:	83 c2 01             	add    $0x1,%edx
  80091f:	83 c1 01             	add    $0x1,%ecx
  800922:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800926:	88 5a ff             	mov    %bl,-0x1(%edx)
  800929:	84 db                	test   %bl,%bl
  80092b:	75 ef                	jne    80091c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80092d:	5b                   	pop    %ebx
  80092e:	5d                   	pop    %ebp
  80092f:	c3                   	ret    

00800930 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800930:	55                   	push   %ebp
  800931:	89 e5                	mov    %esp,%ebp
  800933:	53                   	push   %ebx
  800934:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800937:	53                   	push   %ebx
  800938:	e8 9a ff ff ff       	call   8008d7 <strlen>
  80093d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800940:	ff 75 0c             	pushl  0xc(%ebp)
  800943:	01 d8                	add    %ebx,%eax
  800945:	50                   	push   %eax
  800946:	e8 c5 ff ff ff       	call   800910 <strcpy>
	return dst;
}
  80094b:	89 d8                	mov    %ebx,%eax
  80094d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800950:	c9                   	leave  
  800951:	c3                   	ret    

00800952 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800952:	55                   	push   %ebp
  800953:	89 e5                	mov    %esp,%ebp
  800955:	56                   	push   %esi
  800956:	53                   	push   %ebx
  800957:	8b 75 08             	mov    0x8(%ebp),%esi
  80095a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80095d:	89 f3                	mov    %esi,%ebx
  80095f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800962:	89 f2                	mov    %esi,%edx
  800964:	eb 0f                	jmp    800975 <strncpy+0x23>
		*dst++ = *src;
  800966:	83 c2 01             	add    $0x1,%edx
  800969:	0f b6 01             	movzbl (%ecx),%eax
  80096c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80096f:	80 39 01             	cmpb   $0x1,(%ecx)
  800972:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800975:	39 da                	cmp    %ebx,%edx
  800977:	75 ed                	jne    800966 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800979:	89 f0                	mov    %esi,%eax
  80097b:	5b                   	pop    %ebx
  80097c:	5e                   	pop    %esi
  80097d:	5d                   	pop    %ebp
  80097e:	c3                   	ret    

0080097f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80097f:	55                   	push   %ebp
  800980:	89 e5                	mov    %esp,%ebp
  800982:	56                   	push   %esi
  800983:	53                   	push   %ebx
  800984:	8b 75 08             	mov    0x8(%ebp),%esi
  800987:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80098a:	8b 55 10             	mov    0x10(%ebp),%edx
  80098d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80098f:	85 d2                	test   %edx,%edx
  800991:	74 21                	je     8009b4 <strlcpy+0x35>
  800993:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800997:	89 f2                	mov    %esi,%edx
  800999:	eb 09                	jmp    8009a4 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80099b:	83 c2 01             	add    $0x1,%edx
  80099e:	83 c1 01             	add    $0x1,%ecx
  8009a1:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8009a4:	39 c2                	cmp    %eax,%edx
  8009a6:	74 09                	je     8009b1 <strlcpy+0x32>
  8009a8:	0f b6 19             	movzbl (%ecx),%ebx
  8009ab:	84 db                	test   %bl,%bl
  8009ad:	75 ec                	jne    80099b <strlcpy+0x1c>
  8009af:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8009b1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8009b4:	29 f0                	sub    %esi,%eax
}
  8009b6:	5b                   	pop    %ebx
  8009b7:	5e                   	pop    %esi
  8009b8:	5d                   	pop    %ebp
  8009b9:	c3                   	ret    

008009ba <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8009ba:	55                   	push   %ebp
  8009bb:	89 e5                	mov    %esp,%ebp
  8009bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009c0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8009c3:	eb 06                	jmp    8009cb <strcmp+0x11>
		p++, q++;
  8009c5:	83 c1 01             	add    $0x1,%ecx
  8009c8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8009cb:	0f b6 01             	movzbl (%ecx),%eax
  8009ce:	84 c0                	test   %al,%al
  8009d0:	74 04                	je     8009d6 <strcmp+0x1c>
  8009d2:	3a 02                	cmp    (%edx),%al
  8009d4:	74 ef                	je     8009c5 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009d6:	0f b6 c0             	movzbl %al,%eax
  8009d9:	0f b6 12             	movzbl (%edx),%edx
  8009dc:	29 d0                	sub    %edx,%eax
}
  8009de:	5d                   	pop    %ebp
  8009df:	c3                   	ret    

008009e0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009e0:	55                   	push   %ebp
  8009e1:	89 e5                	mov    %esp,%ebp
  8009e3:	53                   	push   %ebx
  8009e4:	8b 45 08             	mov    0x8(%ebp),%eax
  8009e7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009ea:	89 c3                	mov    %eax,%ebx
  8009ec:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009ef:	eb 06                	jmp    8009f7 <strncmp+0x17>
		n--, p++, q++;
  8009f1:	83 c0 01             	add    $0x1,%eax
  8009f4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009f7:	39 d8                	cmp    %ebx,%eax
  8009f9:	74 15                	je     800a10 <strncmp+0x30>
  8009fb:	0f b6 08             	movzbl (%eax),%ecx
  8009fe:	84 c9                	test   %cl,%cl
  800a00:	74 04                	je     800a06 <strncmp+0x26>
  800a02:	3a 0a                	cmp    (%edx),%cl
  800a04:	74 eb                	je     8009f1 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800a06:	0f b6 00             	movzbl (%eax),%eax
  800a09:	0f b6 12             	movzbl (%edx),%edx
  800a0c:	29 d0                	sub    %edx,%eax
  800a0e:	eb 05                	jmp    800a15 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800a10:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800a15:	5b                   	pop    %ebx
  800a16:	5d                   	pop    %ebp
  800a17:	c3                   	ret    

00800a18 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800a18:	55                   	push   %ebp
  800a19:	89 e5                	mov    %esp,%ebp
  800a1b:	8b 45 08             	mov    0x8(%ebp),%eax
  800a1e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a22:	eb 07                	jmp    800a2b <strchr+0x13>
		if (*s == c)
  800a24:	38 ca                	cmp    %cl,%dl
  800a26:	74 0f                	je     800a37 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a28:	83 c0 01             	add    $0x1,%eax
  800a2b:	0f b6 10             	movzbl (%eax),%edx
  800a2e:	84 d2                	test   %dl,%dl
  800a30:	75 f2                	jne    800a24 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800a32:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a37:	5d                   	pop    %ebp
  800a38:	c3                   	ret    

00800a39 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a39:	55                   	push   %ebp
  800a3a:	89 e5                	mov    %esp,%ebp
  800a3c:	8b 45 08             	mov    0x8(%ebp),%eax
  800a3f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a43:	eb 03                	jmp    800a48 <strfind+0xf>
  800a45:	83 c0 01             	add    $0x1,%eax
  800a48:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800a4b:	38 ca                	cmp    %cl,%dl
  800a4d:	74 04                	je     800a53 <strfind+0x1a>
  800a4f:	84 d2                	test   %dl,%dl
  800a51:	75 f2                	jne    800a45 <strfind+0xc>
			break;
	return (char *) s;
}
  800a53:	5d                   	pop    %ebp
  800a54:	c3                   	ret    

00800a55 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a55:	55                   	push   %ebp
  800a56:	89 e5                	mov    %esp,%ebp
  800a58:	57                   	push   %edi
  800a59:	56                   	push   %esi
  800a5a:	53                   	push   %ebx
  800a5b:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a5e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a61:	85 c9                	test   %ecx,%ecx
  800a63:	74 36                	je     800a9b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a65:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a6b:	75 28                	jne    800a95 <memset+0x40>
  800a6d:	f6 c1 03             	test   $0x3,%cl
  800a70:	75 23                	jne    800a95 <memset+0x40>
		c &= 0xFF;
  800a72:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a76:	89 d3                	mov    %edx,%ebx
  800a78:	c1 e3 08             	shl    $0x8,%ebx
  800a7b:	89 d6                	mov    %edx,%esi
  800a7d:	c1 e6 18             	shl    $0x18,%esi
  800a80:	89 d0                	mov    %edx,%eax
  800a82:	c1 e0 10             	shl    $0x10,%eax
  800a85:	09 f0                	or     %esi,%eax
  800a87:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800a89:	89 d8                	mov    %ebx,%eax
  800a8b:	09 d0                	or     %edx,%eax
  800a8d:	c1 e9 02             	shr    $0x2,%ecx
  800a90:	fc                   	cld    
  800a91:	f3 ab                	rep stos %eax,%es:(%edi)
  800a93:	eb 06                	jmp    800a9b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a95:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a98:	fc                   	cld    
  800a99:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a9b:	89 f8                	mov    %edi,%eax
  800a9d:	5b                   	pop    %ebx
  800a9e:	5e                   	pop    %esi
  800a9f:	5f                   	pop    %edi
  800aa0:	5d                   	pop    %ebp
  800aa1:	c3                   	ret    

00800aa2 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800aa2:	55                   	push   %ebp
  800aa3:	89 e5                	mov    %esp,%ebp
  800aa5:	57                   	push   %edi
  800aa6:	56                   	push   %esi
  800aa7:	8b 45 08             	mov    0x8(%ebp),%eax
  800aaa:	8b 75 0c             	mov    0xc(%ebp),%esi
  800aad:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800ab0:	39 c6                	cmp    %eax,%esi
  800ab2:	73 35                	jae    800ae9 <memmove+0x47>
  800ab4:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800ab7:	39 d0                	cmp    %edx,%eax
  800ab9:	73 2e                	jae    800ae9 <memmove+0x47>
		s += n;
		d += n;
  800abb:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800abe:	89 d6                	mov    %edx,%esi
  800ac0:	09 fe                	or     %edi,%esi
  800ac2:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800ac8:	75 13                	jne    800add <memmove+0x3b>
  800aca:	f6 c1 03             	test   $0x3,%cl
  800acd:	75 0e                	jne    800add <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800acf:	83 ef 04             	sub    $0x4,%edi
  800ad2:	8d 72 fc             	lea    -0x4(%edx),%esi
  800ad5:	c1 e9 02             	shr    $0x2,%ecx
  800ad8:	fd                   	std    
  800ad9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800adb:	eb 09                	jmp    800ae6 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800add:	83 ef 01             	sub    $0x1,%edi
  800ae0:	8d 72 ff             	lea    -0x1(%edx),%esi
  800ae3:	fd                   	std    
  800ae4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ae6:	fc                   	cld    
  800ae7:	eb 1d                	jmp    800b06 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ae9:	89 f2                	mov    %esi,%edx
  800aeb:	09 c2                	or     %eax,%edx
  800aed:	f6 c2 03             	test   $0x3,%dl
  800af0:	75 0f                	jne    800b01 <memmove+0x5f>
  800af2:	f6 c1 03             	test   $0x3,%cl
  800af5:	75 0a                	jne    800b01 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800af7:	c1 e9 02             	shr    $0x2,%ecx
  800afa:	89 c7                	mov    %eax,%edi
  800afc:	fc                   	cld    
  800afd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aff:	eb 05                	jmp    800b06 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800b01:	89 c7                	mov    %eax,%edi
  800b03:	fc                   	cld    
  800b04:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800b06:	5e                   	pop    %esi
  800b07:	5f                   	pop    %edi
  800b08:	5d                   	pop    %ebp
  800b09:	c3                   	ret    

00800b0a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800b0a:	55                   	push   %ebp
  800b0b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800b0d:	ff 75 10             	pushl  0x10(%ebp)
  800b10:	ff 75 0c             	pushl  0xc(%ebp)
  800b13:	ff 75 08             	pushl  0x8(%ebp)
  800b16:	e8 87 ff ff ff       	call   800aa2 <memmove>
}
  800b1b:	c9                   	leave  
  800b1c:	c3                   	ret    

00800b1d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b1d:	55                   	push   %ebp
  800b1e:	89 e5                	mov    %esp,%ebp
  800b20:	56                   	push   %esi
  800b21:	53                   	push   %ebx
  800b22:	8b 45 08             	mov    0x8(%ebp),%eax
  800b25:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b28:	89 c6                	mov    %eax,%esi
  800b2a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b2d:	eb 1a                	jmp    800b49 <memcmp+0x2c>
		if (*s1 != *s2)
  800b2f:	0f b6 08             	movzbl (%eax),%ecx
  800b32:	0f b6 1a             	movzbl (%edx),%ebx
  800b35:	38 d9                	cmp    %bl,%cl
  800b37:	74 0a                	je     800b43 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b39:	0f b6 c1             	movzbl %cl,%eax
  800b3c:	0f b6 db             	movzbl %bl,%ebx
  800b3f:	29 d8                	sub    %ebx,%eax
  800b41:	eb 0f                	jmp    800b52 <memcmp+0x35>
		s1++, s2++;
  800b43:	83 c0 01             	add    $0x1,%eax
  800b46:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b49:	39 f0                	cmp    %esi,%eax
  800b4b:	75 e2                	jne    800b2f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b4d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b52:	5b                   	pop    %ebx
  800b53:	5e                   	pop    %esi
  800b54:	5d                   	pop    %ebp
  800b55:	c3                   	ret    

00800b56 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b56:	55                   	push   %ebp
  800b57:	89 e5                	mov    %esp,%ebp
  800b59:	53                   	push   %ebx
  800b5a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800b5d:	89 c1                	mov    %eax,%ecx
  800b5f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800b62:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b66:	eb 0a                	jmp    800b72 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b68:	0f b6 10             	movzbl (%eax),%edx
  800b6b:	39 da                	cmp    %ebx,%edx
  800b6d:	74 07                	je     800b76 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b6f:	83 c0 01             	add    $0x1,%eax
  800b72:	39 c8                	cmp    %ecx,%eax
  800b74:	72 f2                	jb     800b68 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b76:	5b                   	pop    %ebx
  800b77:	5d                   	pop    %ebp
  800b78:	c3                   	ret    

00800b79 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b79:	55                   	push   %ebp
  800b7a:	89 e5                	mov    %esp,%ebp
  800b7c:	57                   	push   %edi
  800b7d:	56                   	push   %esi
  800b7e:	53                   	push   %ebx
  800b7f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b82:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b85:	eb 03                	jmp    800b8a <strtol+0x11>
		s++;
  800b87:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b8a:	0f b6 01             	movzbl (%ecx),%eax
  800b8d:	3c 20                	cmp    $0x20,%al
  800b8f:	74 f6                	je     800b87 <strtol+0xe>
  800b91:	3c 09                	cmp    $0x9,%al
  800b93:	74 f2                	je     800b87 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b95:	3c 2b                	cmp    $0x2b,%al
  800b97:	75 0a                	jne    800ba3 <strtol+0x2a>
		s++;
  800b99:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b9c:	bf 00 00 00 00       	mov    $0x0,%edi
  800ba1:	eb 11                	jmp    800bb4 <strtol+0x3b>
  800ba3:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ba8:	3c 2d                	cmp    $0x2d,%al
  800baa:	75 08                	jne    800bb4 <strtol+0x3b>
		s++, neg = 1;
  800bac:	83 c1 01             	add    $0x1,%ecx
  800baf:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800bb4:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800bba:	75 15                	jne    800bd1 <strtol+0x58>
  800bbc:	80 39 30             	cmpb   $0x30,(%ecx)
  800bbf:	75 10                	jne    800bd1 <strtol+0x58>
  800bc1:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800bc5:	75 7c                	jne    800c43 <strtol+0xca>
		s += 2, base = 16;
  800bc7:	83 c1 02             	add    $0x2,%ecx
  800bca:	bb 10 00 00 00       	mov    $0x10,%ebx
  800bcf:	eb 16                	jmp    800be7 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800bd1:	85 db                	test   %ebx,%ebx
  800bd3:	75 12                	jne    800be7 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800bd5:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800bda:	80 39 30             	cmpb   $0x30,(%ecx)
  800bdd:	75 08                	jne    800be7 <strtol+0x6e>
		s++, base = 8;
  800bdf:	83 c1 01             	add    $0x1,%ecx
  800be2:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800be7:	b8 00 00 00 00       	mov    $0x0,%eax
  800bec:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bef:	0f b6 11             	movzbl (%ecx),%edx
  800bf2:	8d 72 d0             	lea    -0x30(%edx),%esi
  800bf5:	89 f3                	mov    %esi,%ebx
  800bf7:	80 fb 09             	cmp    $0x9,%bl
  800bfa:	77 08                	ja     800c04 <strtol+0x8b>
			dig = *s - '0';
  800bfc:	0f be d2             	movsbl %dl,%edx
  800bff:	83 ea 30             	sub    $0x30,%edx
  800c02:	eb 22                	jmp    800c26 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800c04:	8d 72 9f             	lea    -0x61(%edx),%esi
  800c07:	89 f3                	mov    %esi,%ebx
  800c09:	80 fb 19             	cmp    $0x19,%bl
  800c0c:	77 08                	ja     800c16 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800c0e:	0f be d2             	movsbl %dl,%edx
  800c11:	83 ea 57             	sub    $0x57,%edx
  800c14:	eb 10                	jmp    800c26 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800c16:	8d 72 bf             	lea    -0x41(%edx),%esi
  800c19:	89 f3                	mov    %esi,%ebx
  800c1b:	80 fb 19             	cmp    $0x19,%bl
  800c1e:	77 16                	ja     800c36 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800c20:	0f be d2             	movsbl %dl,%edx
  800c23:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800c26:	3b 55 10             	cmp    0x10(%ebp),%edx
  800c29:	7d 0b                	jge    800c36 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800c2b:	83 c1 01             	add    $0x1,%ecx
  800c2e:	0f af 45 10          	imul   0x10(%ebp),%eax
  800c32:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800c34:	eb b9                	jmp    800bef <strtol+0x76>

	if (endptr)
  800c36:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c3a:	74 0d                	je     800c49 <strtol+0xd0>
		*endptr = (char *) s;
  800c3c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c3f:	89 0e                	mov    %ecx,(%esi)
  800c41:	eb 06                	jmp    800c49 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c43:	85 db                	test   %ebx,%ebx
  800c45:	74 98                	je     800bdf <strtol+0x66>
  800c47:	eb 9e                	jmp    800be7 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800c49:	89 c2                	mov    %eax,%edx
  800c4b:	f7 da                	neg    %edx
  800c4d:	85 ff                	test   %edi,%edi
  800c4f:	0f 45 c2             	cmovne %edx,%eax
}
  800c52:	5b                   	pop    %ebx
  800c53:	5e                   	pop    %esi
  800c54:	5f                   	pop    %edi
  800c55:	5d                   	pop    %ebp
  800c56:	c3                   	ret    

00800c57 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800c57:	55                   	push   %ebp
  800c58:	89 e5                	mov    %esp,%ebp
  800c5a:	57                   	push   %edi
  800c5b:	56                   	push   %esi
  800c5c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c5d:	b8 00 00 00 00       	mov    $0x0,%eax
  800c62:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c65:	8b 55 08             	mov    0x8(%ebp),%edx
  800c68:	89 c3                	mov    %eax,%ebx
  800c6a:	89 c7                	mov    %eax,%edi
  800c6c:	89 c6                	mov    %eax,%esi
  800c6e:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800c70:	5b                   	pop    %ebx
  800c71:	5e                   	pop    %esi
  800c72:	5f                   	pop    %edi
  800c73:	5d                   	pop    %ebp
  800c74:	c3                   	ret    

00800c75 <sys_cgetc>:

int
sys_cgetc(void)
{
  800c75:	55                   	push   %ebp
  800c76:	89 e5                	mov    %esp,%ebp
  800c78:	57                   	push   %edi
  800c79:	56                   	push   %esi
  800c7a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c7b:	ba 00 00 00 00       	mov    $0x0,%edx
  800c80:	b8 01 00 00 00       	mov    $0x1,%eax
  800c85:	89 d1                	mov    %edx,%ecx
  800c87:	89 d3                	mov    %edx,%ebx
  800c89:	89 d7                	mov    %edx,%edi
  800c8b:	89 d6                	mov    %edx,%esi
  800c8d:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c8f:	5b                   	pop    %ebx
  800c90:	5e                   	pop    %esi
  800c91:	5f                   	pop    %edi
  800c92:	5d                   	pop    %ebp
  800c93:	c3                   	ret    

00800c94 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c94:	55                   	push   %ebp
  800c95:	89 e5                	mov    %esp,%ebp
  800c97:	57                   	push   %edi
  800c98:	56                   	push   %esi
  800c99:	53                   	push   %ebx
  800c9a:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c9d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ca2:	b8 03 00 00 00       	mov    $0x3,%eax
  800ca7:	8b 55 08             	mov    0x8(%ebp),%edx
  800caa:	89 cb                	mov    %ecx,%ebx
  800cac:	89 cf                	mov    %ecx,%edi
  800cae:	89 ce                	mov    %ecx,%esi
  800cb0:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cb2:	85 c0                	test   %eax,%eax
  800cb4:	7e 17                	jle    800ccd <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cb6:	83 ec 0c             	sub    $0xc,%esp
  800cb9:	50                   	push   %eax
  800cba:	6a 03                	push   $0x3
  800cbc:	68 64 14 80 00       	push   $0x801464
  800cc1:	6a 23                	push   $0x23
  800cc3:	68 81 14 80 00       	push   $0x801481
  800cc8:	e8 66 f5 ff ff       	call   800233 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800ccd:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cd0:	5b                   	pop    %ebx
  800cd1:	5e                   	pop    %esi
  800cd2:	5f                   	pop    %edi
  800cd3:	5d                   	pop    %ebp
  800cd4:	c3                   	ret    

00800cd5 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800cd5:	55                   	push   %ebp
  800cd6:	89 e5                	mov    %esp,%ebp
  800cd8:	57                   	push   %edi
  800cd9:	56                   	push   %esi
  800cda:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cdb:	ba 00 00 00 00       	mov    $0x0,%edx
  800ce0:	b8 02 00 00 00       	mov    $0x2,%eax
  800ce5:	89 d1                	mov    %edx,%ecx
  800ce7:	89 d3                	mov    %edx,%ebx
  800ce9:	89 d7                	mov    %edx,%edi
  800ceb:	89 d6                	mov    %edx,%esi
  800ced:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800cef:	5b                   	pop    %ebx
  800cf0:	5e                   	pop    %esi
  800cf1:	5f                   	pop    %edi
  800cf2:	5d                   	pop    %ebp
  800cf3:	c3                   	ret    

00800cf4 <sys_yield>:

void
sys_yield(void)
{
  800cf4:	55                   	push   %ebp
  800cf5:	89 e5                	mov    %esp,%ebp
  800cf7:	57                   	push   %edi
  800cf8:	56                   	push   %esi
  800cf9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cfa:	ba 00 00 00 00       	mov    $0x0,%edx
  800cff:	b8 0a 00 00 00       	mov    $0xa,%eax
  800d04:	89 d1                	mov    %edx,%ecx
  800d06:	89 d3                	mov    %edx,%ebx
  800d08:	89 d7                	mov    %edx,%edi
  800d0a:	89 d6                	mov    %edx,%esi
  800d0c:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800d0e:	5b                   	pop    %ebx
  800d0f:	5e                   	pop    %esi
  800d10:	5f                   	pop    %edi
  800d11:	5d                   	pop    %ebp
  800d12:	c3                   	ret    

00800d13 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800d13:	55                   	push   %ebp
  800d14:	89 e5                	mov    %esp,%ebp
  800d16:	57                   	push   %edi
  800d17:	56                   	push   %esi
  800d18:	53                   	push   %ebx
  800d19:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d1c:	be 00 00 00 00       	mov    $0x0,%esi
  800d21:	b8 04 00 00 00       	mov    $0x4,%eax
  800d26:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d29:	8b 55 08             	mov    0x8(%ebp),%edx
  800d2c:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d2f:	89 f7                	mov    %esi,%edi
  800d31:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d33:	85 c0                	test   %eax,%eax
  800d35:	7e 17                	jle    800d4e <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d37:	83 ec 0c             	sub    $0xc,%esp
  800d3a:	50                   	push   %eax
  800d3b:	6a 04                	push   $0x4
  800d3d:	68 64 14 80 00       	push   $0x801464
  800d42:	6a 23                	push   $0x23
  800d44:	68 81 14 80 00       	push   $0x801481
  800d49:	e8 e5 f4 ff ff       	call   800233 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800d4e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d51:	5b                   	pop    %ebx
  800d52:	5e                   	pop    %esi
  800d53:	5f                   	pop    %edi
  800d54:	5d                   	pop    %ebp
  800d55:	c3                   	ret    

00800d56 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800d56:	55                   	push   %ebp
  800d57:	89 e5                	mov    %esp,%ebp
  800d59:	57                   	push   %edi
  800d5a:	56                   	push   %esi
  800d5b:	53                   	push   %ebx
  800d5c:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d5f:	b8 05 00 00 00       	mov    $0x5,%eax
  800d64:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d67:	8b 55 08             	mov    0x8(%ebp),%edx
  800d6a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d6d:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d70:	8b 75 18             	mov    0x18(%ebp),%esi
  800d73:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d75:	85 c0                	test   %eax,%eax
  800d77:	7e 17                	jle    800d90 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d79:	83 ec 0c             	sub    $0xc,%esp
  800d7c:	50                   	push   %eax
  800d7d:	6a 05                	push   $0x5
  800d7f:	68 64 14 80 00       	push   $0x801464
  800d84:	6a 23                	push   $0x23
  800d86:	68 81 14 80 00       	push   $0x801481
  800d8b:	e8 a3 f4 ff ff       	call   800233 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800d90:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d93:	5b                   	pop    %ebx
  800d94:	5e                   	pop    %esi
  800d95:	5f                   	pop    %edi
  800d96:	5d                   	pop    %ebp
  800d97:	c3                   	ret    

00800d98 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
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
  800da1:	bb 00 00 00 00       	mov    $0x0,%ebx
  800da6:	b8 06 00 00 00       	mov    $0x6,%eax
  800dab:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800dae:	8b 55 08             	mov    0x8(%ebp),%edx
  800db1:	89 df                	mov    %ebx,%edi
  800db3:	89 de                	mov    %ebx,%esi
  800db5:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800db7:	85 c0                	test   %eax,%eax
  800db9:	7e 17                	jle    800dd2 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800dbb:	83 ec 0c             	sub    $0xc,%esp
  800dbe:	50                   	push   %eax
  800dbf:	6a 06                	push   $0x6
  800dc1:	68 64 14 80 00       	push   $0x801464
  800dc6:	6a 23                	push   $0x23
  800dc8:	68 81 14 80 00       	push   $0x801481
  800dcd:	e8 61 f4 ff ff       	call   800233 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800dd2:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800dd5:	5b                   	pop    %ebx
  800dd6:	5e                   	pop    %esi
  800dd7:	5f                   	pop    %edi
  800dd8:	5d                   	pop    %ebp
  800dd9:	c3                   	ret    

00800dda <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800dda:	55                   	push   %ebp
  800ddb:	89 e5                	mov    %esp,%ebp
  800ddd:	57                   	push   %edi
  800dde:	56                   	push   %esi
  800ddf:	53                   	push   %ebx
  800de0:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800de3:	bb 00 00 00 00       	mov    $0x0,%ebx
  800de8:	b8 08 00 00 00       	mov    $0x8,%eax
  800ded:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800df0:	8b 55 08             	mov    0x8(%ebp),%edx
  800df3:	89 df                	mov    %ebx,%edi
  800df5:	89 de                	mov    %ebx,%esi
  800df7:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800df9:	85 c0                	test   %eax,%eax
  800dfb:	7e 17                	jle    800e14 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800dfd:	83 ec 0c             	sub    $0xc,%esp
  800e00:	50                   	push   %eax
  800e01:	6a 08                	push   $0x8
  800e03:	68 64 14 80 00       	push   $0x801464
  800e08:	6a 23                	push   $0x23
  800e0a:	68 81 14 80 00       	push   $0x801481
  800e0f:	e8 1f f4 ff ff       	call   800233 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800e14:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800e17:	5b                   	pop    %ebx
  800e18:	5e                   	pop    %esi
  800e19:	5f                   	pop    %edi
  800e1a:	5d                   	pop    %ebp
  800e1b:	c3                   	ret    

00800e1c <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800e1c:	55                   	push   %ebp
  800e1d:	89 e5                	mov    %esp,%ebp
  800e1f:	57                   	push   %edi
  800e20:	56                   	push   %esi
  800e21:	53                   	push   %ebx
  800e22:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e25:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e2a:	b8 09 00 00 00       	mov    $0x9,%eax
  800e2f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e32:	8b 55 08             	mov    0x8(%ebp),%edx
  800e35:	89 df                	mov    %ebx,%edi
  800e37:	89 de                	mov    %ebx,%esi
  800e39:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800e3b:	85 c0                	test   %eax,%eax
  800e3d:	7e 17                	jle    800e56 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e3f:	83 ec 0c             	sub    $0xc,%esp
  800e42:	50                   	push   %eax
  800e43:	6a 09                	push   $0x9
  800e45:	68 64 14 80 00       	push   $0x801464
  800e4a:	6a 23                	push   $0x23
  800e4c:	68 81 14 80 00       	push   $0x801481
  800e51:	e8 dd f3 ff ff       	call   800233 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800e56:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800e59:	5b                   	pop    %ebx
  800e5a:	5e                   	pop    %esi
  800e5b:	5f                   	pop    %edi
  800e5c:	5d                   	pop    %ebp
  800e5d:	c3                   	ret    

00800e5e <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800e5e:	55                   	push   %ebp
  800e5f:	89 e5                	mov    %esp,%ebp
  800e61:	57                   	push   %edi
  800e62:	56                   	push   %esi
  800e63:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e64:	be 00 00 00 00       	mov    $0x0,%esi
  800e69:	b8 0b 00 00 00       	mov    $0xb,%eax
  800e6e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e71:	8b 55 08             	mov    0x8(%ebp),%edx
  800e74:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e77:	8b 7d 14             	mov    0x14(%ebp),%edi
  800e7a:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800e7c:	5b                   	pop    %ebx
  800e7d:	5e                   	pop    %esi
  800e7e:	5f                   	pop    %edi
  800e7f:	5d                   	pop    %ebp
  800e80:	c3                   	ret    

00800e81 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800e81:	55                   	push   %ebp
  800e82:	89 e5                	mov    %esp,%ebp
  800e84:	57                   	push   %edi
  800e85:	56                   	push   %esi
  800e86:	53                   	push   %ebx
  800e87:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e8a:	b9 00 00 00 00       	mov    $0x0,%ecx
  800e8f:	b8 0c 00 00 00       	mov    $0xc,%eax
  800e94:	8b 55 08             	mov    0x8(%ebp),%edx
  800e97:	89 cb                	mov    %ecx,%ebx
  800e99:	89 cf                	mov    %ecx,%edi
  800e9b:	89 ce                	mov    %ecx,%esi
  800e9d:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800e9f:	85 c0                	test   %eax,%eax
  800ea1:	7e 17                	jle    800eba <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ea3:	83 ec 0c             	sub    $0xc,%esp
  800ea6:	50                   	push   %eax
  800ea7:	6a 0c                	push   $0xc
  800ea9:	68 64 14 80 00       	push   $0x801464
  800eae:	6a 23                	push   $0x23
  800eb0:	68 81 14 80 00       	push   $0x801481
  800eb5:	e8 79 f3 ff ff       	call   800233 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800eba:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800ebd:	5b                   	pop    %ebx
  800ebe:	5e                   	pop    %esi
  800ebf:	5f                   	pop    %edi
  800ec0:	5d                   	pop    %ebp
  800ec1:	c3                   	ret    
  800ec2:	66 90                	xchg   %ax,%ax
  800ec4:	66 90                	xchg   %ax,%ax
  800ec6:	66 90                	xchg   %ax,%ax
  800ec8:	66 90                	xchg   %ax,%ax
  800eca:	66 90                	xchg   %ax,%ax
  800ecc:	66 90                	xchg   %ax,%ax
  800ece:	66 90                	xchg   %ax,%ax

00800ed0 <__udivdi3>:
  800ed0:	55                   	push   %ebp
  800ed1:	57                   	push   %edi
  800ed2:	56                   	push   %esi
  800ed3:	53                   	push   %ebx
  800ed4:	83 ec 1c             	sub    $0x1c,%esp
  800ed7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800edb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800edf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800ee3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800ee7:	85 f6                	test   %esi,%esi
  800ee9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800eed:	89 ca                	mov    %ecx,%edx
  800eef:	89 f8                	mov    %edi,%eax
  800ef1:	75 3d                	jne    800f30 <__udivdi3+0x60>
  800ef3:	39 cf                	cmp    %ecx,%edi
  800ef5:	0f 87 c5 00 00 00    	ja     800fc0 <__udivdi3+0xf0>
  800efb:	85 ff                	test   %edi,%edi
  800efd:	89 fd                	mov    %edi,%ebp
  800eff:	75 0b                	jne    800f0c <__udivdi3+0x3c>
  800f01:	b8 01 00 00 00       	mov    $0x1,%eax
  800f06:	31 d2                	xor    %edx,%edx
  800f08:	f7 f7                	div    %edi
  800f0a:	89 c5                	mov    %eax,%ebp
  800f0c:	89 c8                	mov    %ecx,%eax
  800f0e:	31 d2                	xor    %edx,%edx
  800f10:	f7 f5                	div    %ebp
  800f12:	89 c1                	mov    %eax,%ecx
  800f14:	89 d8                	mov    %ebx,%eax
  800f16:	89 cf                	mov    %ecx,%edi
  800f18:	f7 f5                	div    %ebp
  800f1a:	89 c3                	mov    %eax,%ebx
  800f1c:	89 d8                	mov    %ebx,%eax
  800f1e:	89 fa                	mov    %edi,%edx
  800f20:	83 c4 1c             	add    $0x1c,%esp
  800f23:	5b                   	pop    %ebx
  800f24:	5e                   	pop    %esi
  800f25:	5f                   	pop    %edi
  800f26:	5d                   	pop    %ebp
  800f27:	c3                   	ret    
  800f28:	90                   	nop
  800f29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f30:	39 ce                	cmp    %ecx,%esi
  800f32:	77 74                	ja     800fa8 <__udivdi3+0xd8>
  800f34:	0f bd fe             	bsr    %esi,%edi
  800f37:	83 f7 1f             	xor    $0x1f,%edi
  800f3a:	0f 84 98 00 00 00    	je     800fd8 <__udivdi3+0x108>
  800f40:	bb 20 00 00 00       	mov    $0x20,%ebx
  800f45:	89 f9                	mov    %edi,%ecx
  800f47:	89 c5                	mov    %eax,%ebp
  800f49:	29 fb                	sub    %edi,%ebx
  800f4b:	d3 e6                	shl    %cl,%esi
  800f4d:	89 d9                	mov    %ebx,%ecx
  800f4f:	d3 ed                	shr    %cl,%ebp
  800f51:	89 f9                	mov    %edi,%ecx
  800f53:	d3 e0                	shl    %cl,%eax
  800f55:	09 ee                	or     %ebp,%esi
  800f57:	89 d9                	mov    %ebx,%ecx
  800f59:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800f5d:	89 d5                	mov    %edx,%ebp
  800f5f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800f63:	d3 ed                	shr    %cl,%ebp
  800f65:	89 f9                	mov    %edi,%ecx
  800f67:	d3 e2                	shl    %cl,%edx
  800f69:	89 d9                	mov    %ebx,%ecx
  800f6b:	d3 e8                	shr    %cl,%eax
  800f6d:	09 c2                	or     %eax,%edx
  800f6f:	89 d0                	mov    %edx,%eax
  800f71:	89 ea                	mov    %ebp,%edx
  800f73:	f7 f6                	div    %esi
  800f75:	89 d5                	mov    %edx,%ebp
  800f77:	89 c3                	mov    %eax,%ebx
  800f79:	f7 64 24 0c          	mull   0xc(%esp)
  800f7d:	39 d5                	cmp    %edx,%ebp
  800f7f:	72 10                	jb     800f91 <__udivdi3+0xc1>
  800f81:	8b 74 24 08          	mov    0x8(%esp),%esi
  800f85:	89 f9                	mov    %edi,%ecx
  800f87:	d3 e6                	shl    %cl,%esi
  800f89:	39 c6                	cmp    %eax,%esi
  800f8b:	73 07                	jae    800f94 <__udivdi3+0xc4>
  800f8d:	39 d5                	cmp    %edx,%ebp
  800f8f:	75 03                	jne    800f94 <__udivdi3+0xc4>
  800f91:	83 eb 01             	sub    $0x1,%ebx
  800f94:	31 ff                	xor    %edi,%edi
  800f96:	89 d8                	mov    %ebx,%eax
  800f98:	89 fa                	mov    %edi,%edx
  800f9a:	83 c4 1c             	add    $0x1c,%esp
  800f9d:	5b                   	pop    %ebx
  800f9e:	5e                   	pop    %esi
  800f9f:	5f                   	pop    %edi
  800fa0:	5d                   	pop    %ebp
  800fa1:	c3                   	ret    
  800fa2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800fa8:	31 ff                	xor    %edi,%edi
  800faa:	31 db                	xor    %ebx,%ebx
  800fac:	89 d8                	mov    %ebx,%eax
  800fae:	89 fa                	mov    %edi,%edx
  800fb0:	83 c4 1c             	add    $0x1c,%esp
  800fb3:	5b                   	pop    %ebx
  800fb4:	5e                   	pop    %esi
  800fb5:	5f                   	pop    %edi
  800fb6:	5d                   	pop    %ebp
  800fb7:	c3                   	ret    
  800fb8:	90                   	nop
  800fb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800fc0:	89 d8                	mov    %ebx,%eax
  800fc2:	f7 f7                	div    %edi
  800fc4:	31 ff                	xor    %edi,%edi
  800fc6:	89 c3                	mov    %eax,%ebx
  800fc8:	89 d8                	mov    %ebx,%eax
  800fca:	89 fa                	mov    %edi,%edx
  800fcc:	83 c4 1c             	add    $0x1c,%esp
  800fcf:	5b                   	pop    %ebx
  800fd0:	5e                   	pop    %esi
  800fd1:	5f                   	pop    %edi
  800fd2:	5d                   	pop    %ebp
  800fd3:	c3                   	ret    
  800fd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800fd8:	39 ce                	cmp    %ecx,%esi
  800fda:	72 0c                	jb     800fe8 <__udivdi3+0x118>
  800fdc:	31 db                	xor    %ebx,%ebx
  800fde:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800fe2:	0f 87 34 ff ff ff    	ja     800f1c <__udivdi3+0x4c>
  800fe8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800fed:	e9 2a ff ff ff       	jmp    800f1c <__udivdi3+0x4c>
  800ff2:	66 90                	xchg   %ax,%ax
  800ff4:	66 90                	xchg   %ax,%ax
  800ff6:	66 90                	xchg   %ax,%ax
  800ff8:	66 90                	xchg   %ax,%ax
  800ffa:	66 90                	xchg   %ax,%ax
  800ffc:	66 90                	xchg   %ax,%ax
  800ffe:	66 90                	xchg   %ax,%ax

00801000 <__umoddi3>:
  801000:	55                   	push   %ebp
  801001:	57                   	push   %edi
  801002:	56                   	push   %esi
  801003:	53                   	push   %ebx
  801004:	83 ec 1c             	sub    $0x1c,%esp
  801007:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  80100b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80100f:	8b 74 24 34          	mov    0x34(%esp),%esi
  801013:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801017:	85 d2                	test   %edx,%edx
  801019:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  80101d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801021:	89 f3                	mov    %esi,%ebx
  801023:	89 3c 24             	mov    %edi,(%esp)
  801026:	89 74 24 04          	mov    %esi,0x4(%esp)
  80102a:	75 1c                	jne    801048 <__umoddi3+0x48>
  80102c:	39 f7                	cmp    %esi,%edi
  80102e:	76 50                	jbe    801080 <__umoddi3+0x80>
  801030:	89 c8                	mov    %ecx,%eax
  801032:	89 f2                	mov    %esi,%edx
  801034:	f7 f7                	div    %edi
  801036:	89 d0                	mov    %edx,%eax
  801038:	31 d2                	xor    %edx,%edx
  80103a:	83 c4 1c             	add    $0x1c,%esp
  80103d:	5b                   	pop    %ebx
  80103e:	5e                   	pop    %esi
  80103f:	5f                   	pop    %edi
  801040:	5d                   	pop    %ebp
  801041:	c3                   	ret    
  801042:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801048:	39 f2                	cmp    %esi,%edx
  80104a:	89 d0                	mov    %edx,%eax
  80104c:	77 52                	ja     8010a0 <__umoddi3+0xa0>
  80104e:	0f bd ea             	bsr    %edx,%ebp
  801051:	83 f5 1f             	xor    $0x1f,%ebp
  801054:	75 5a                	jne    8010b0 <__umoddi3+0xb0>
  801056:	3b 54 24 04          	cmp    0x4(%esp),%edx
  80105a:	0f 82 e0 00 00 00    	jb     801140 <__umoddi3+0x140>
  801060:	39 0c 24             	cmp    %ecx,(%esp)
  801063:	0f 86 d7 00 00 00    	jbe    801140 <__umoddi3+0x140>
  801069:	8b 44 24 08          	mov    0x8(%esp),%eax
  80106d:	8b 54 24 04          	mov    0x4(%esp),%edx
  801071:	83 c4 1c             	add    $0x1c,%esp
  801074:	5b                   	pop    %ebx
  801075:	5e                   	pop    %esi
  801076:	5f                   	pop    %edi
  801077:	5d                   	pop    %ebp
  801078:	c3                   	ret    
  801079:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801080:	85 ff                	test   %edi,%edi
  801082:	89 fd                	mov    %edi,%ebp
  801084:	75 0b                	jne    801091 <__umoddi3+0x91>
  801086:	b8 01 00 00 00       	mov    $0x1,%eax
  80108b:	31 d2                	xor    %edx,%edx
  80108d:	f7 f7                	div    %edi
  80108f:	89 c5                	mov    %eax,%ebp
  801091:	89 f0                	mov    %esi,%eax
  801093:	31 d2                	xor    %edx,%edx
  801095:	f7 f5                	div    %ebp
  801097:	89 c8                	mov    %ecx,%eax
  801099:	f7 f5                	div    %ebp
  80109b:	89 d0                	mov    %edx,%eax
  80109d:	eb 99                	jmp    801038 <__umoddi3+0x38>
  80109f:	90                   	nop
  8010a0:	89 c8                	mov    %ecx,%eax
  8010a2:	89 f2                	mov    %esi,%edx
  8010a4:	83 c4 1c             	add    $0x1c,%esp
  8010a7:	5b                   	pop    %ebx
  8010a8:	5e                   	pop    %esi
  8010a9:	5f                   	pop    %edi
  8010aa:	5d                   	pop    %ebp
  8010ab:	c3                   	ret    
  8010ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8010b0:	8b 34 24             	mov    (%esp),%esi
  8010b3:	bf 20 00 00 00       	mov    $0x20,%edi
  8010b8:	89 e9                	mov    %ebp,%ecx
  8010ba:	29 ef                	sub    %ebp,%edi
  8010bc:	d3 e0                	shl    %cl,%eax
  8010be:	89 f9                	mov    %edi,%ecx
  8010c0:	89 f2                	mov    %esi,%edx
  8010c2:	d3 ea                	shr    %cl,%edx
  8010c4:	89 e9                	mov    %ebp,%ecx
  8010c6:	09 c2                	or     %eax,%edx
  8010c8:	89 d8                	mov    %ebx,%eax
  8010ca:	89 14 24             	mov    %edx,(%esp)
  8010cd:	89 f2                	mov    %esi,%edx
  8010cf:	d3 e2                	shl    %cl,%edx
  8010d1:	89 f9                	mov    %edi,%ecx
  8010d3:	89 54 24 04          	mov    %edx,0x4(%esp)
  8010d7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8010db:	d3 e8                	shr    %cl,%eax
  8010dd:	89 e9                	mov    %ebp,%ecx
  8010df:	89 c6                	mov    %eax,%esi
  8010e1:	d3 e3                	shl    %cl,%ebx
  8010e3:	89 f9                	mov    %edi,%ecx
  8010e5:	89 d0                	mov    %edx,%eax
  8010e7:	d3 e8                	shr    %cl,%eax
  8010e9:	89 e9                	mov    %ebp,%ecx
  8010eb:	09 d8                	or     %ebx,%eax
  8010ed:	89 d3                	mov    %edx,%ebx
  8010ef:	89 f2                	mov    %esi,%edx
  8010f1:	f7 34 24             	divl   (%esp)
  8010f4:	89 d6                	mov    %edx,%esi
  8010f6:	d3 e3                	shl    %cl,%ebx
  8010f8:	f7 64 24 04          	mull   0x4(%esp)
  8010fc:	39 d6                	cmp    %edx,%esi
  8010fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801102:	89 d1                	mov    %edx,%ecx
  801104:	89 c3                	mov    %eax,%ebx
  801106:	72 08                	jb     801110 <__umoddi3+0x110>
  801108:	75 11                	jne    80111b <__umoddi3+0x11b>
  80110a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80110e:	73 0b                	jae    80111b <__umoddi3+0x11b>
  801110:	2b 44 24 04          	sub    0x4(%esp),%eax
  801114:	1b 14 24             	sbb    (%esp),%edx
  801117:	89 d1                	mov    %edx,%ecx
  801119:	89 c3                	mov    %eax,%ebx
  80111b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80111f:	29 da                	sub    %ebx,%edx
  801121:	19 ce                	sbb    %ecx,%esi
  801123:	89 f9                	mov    %edi,%ecx
  801125:	89 f0                	mov    %esi,%eax
  801127:	d3 e0                	shl    %cl,%eax
  801129:	89 e9                	mov    %ebp,%ecx
  80112b:	d3 ea                	shr    %cl,%edx
  80112d:	89 e9                	mov    %ebp,%ecx
  80112f:	d3 ee                	shr    %cl,%esi
  801131:	09 d0                	or     %edx,%eax
  801133:	89 f2                	mov    %esi,%edx
  801135:	83 c4 1c             	add    $0x1c,%esp
  801138:	5b                   	pop    %ebx
  801139:	5e                   	pop    %esi
  80113a:	5f                   	pop    %edi
  80113b:	5d                   	pop    %ebp
  80113c:	c3                   	ret    
  80113d:	8d 76 00             	lea    0x0(%esi),%esi
  801140:	29 f9                	sub    %edi,%ecx
  801142:	19 d6                	sbb    %edx,%esi
  801144:	89 74 24 04          	mov    %esi,0x4(%esp)
  801148:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80114c:	e9 18 ff ff ff       	jmp    801069 <__umoddi3+0x69>
