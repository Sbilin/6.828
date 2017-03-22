
obj/user/faultregs:     file format elf32-i386


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
  80002c:	e8 66 05 00 00       	call   800597 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <check_regs>:
static struct regs before, during, after;

static void
check_regs(struct regs* a, const char *an, struct regs* b, const char *bn,
	   const char *testname)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	57                   	push   %edi
  800037:	56                   	push   %esi
  800038:	53                   	push   %ebx
  800039:	83 ec 0c             	sub    $0xc,%esp
  80003c:	89 c6                	mov    %eax,%esi
  80003e:	89 cb                	mov    %ecx,%ebx
	int mismatch = 0;

	cprintf("%-6s %-8s %-8s\n", "", an, bn);
  800040:	ff 75 08             	pushl  0x8(%ebp)
  800043:	52                   	push   %edx
  800044:	68 71 15 80 00       	push   $0x801571
  800049:	68 40 15 80 00       	push   $0x801540
  80004e:	e8 75 06 00 00       	call   8006c8 <cprintf>
			cprintf("MISMATCH\n");				\
			mismatch = 1;					\
		}							\
	} while (0)

	CHECK(edi, regs.reg_edi);
  800053:	ff 33                	pushl  (%ebx)
  800055:	ff 36                	pushl  (%esi)
  800057:	68 50 15 80 00       	push   $0x801550
  80005c:	68 54 15 80 00       	push   $0x801554
  800061:	e8 62 06 00 00       	call   8006c8 <cprintf>
  800066:	83 c4 20             	add    $0x20,%esp
  800069:	8b 03                	mov    (%ebx),%eax
  80006b:	39 06                	cmp    %eax,(%esi)
  80006d:	75 17                	jne    800086 <check_regs+0x53>
  80006f:	83 ec 0c             	sub    $0xc,%esp
  800072:	68 64 15 80 00       	push   $0x801564
  800077:	e8 4c 06 00 00       	call   8006c8 <cprintf>
  80007c:	83 c4 10             	add    $0x10,%esp

static void
check_regs(struct regs* a, const char *an, struct regs* b, const char *bn,
	   const char *testname)
{
	int mismatch = 0;
  80007f:	bf 00 00 00 00       	mov    $0x0,%edi
  800084:	eb 15                	jmp    80009b <check_regs+0x68>
			cprintf("MISMATCH\n");				\
			mismatch = 1;					\
		}							\
	} while (0)

	CHECK(edi, regs.reg_edi);
  800086:	83 ec 0c             	sub    $0xc,%esp
  800089:	68 68 15 80 00       	push   $0x801568
  80008e:	e8 35 06 00 00       	call   8006c8 <cprintf>
  800093:	83 c4 10             	add    $0x10,%esp
  800096:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(esi, regs.reg_esi);
  80009b:	ff 73 04             	pushl  0x4(%ebx)
  80009e:	ff 76 04             	pushl  0x4(%esi)
  8000a1:	68 72 15 80 00       	push   $0x801572
  8000a6:	68 54 15 80 00       	push   $0x801554
  8000ab:	e8 18 06 00 00       	call   8006c8 <cprintf>
  8000b0:	83 c4 10             	add    $0x10,%esp
  8000b3:	8b 43 04             	mov    0x4(%ebx),%eax
  8000b6:	39 46 04             	cmp    %eax,0x4(%esi)
  8000b9:	75 12                	jne    8000cd <check_regs+0x9a>
  8000bb:	83 ec 0c             	sub    $0xc,%esp
  8000be:	68 64 15 80 00       	push   $0x801564
  8000c3:	e8 00 06 00 00       	call   8006c8 <cprintf>
  8000c8:	83 c4 10             	add    $0x10,%esp
  8000cb:	eb 15                	jmp    8000e2 <check_regs+0xaf>
  8000cd:	83 ec 0c             	sub    $0xc,%esp
  8000d0:	68 68 15 80 00       	push   $0x801568
  8000d5:	e8 ee 05 00 00       	call   8006c8 <cprintf>
  8000da:	83 c4 10             	add    $0x10,%esp
  8000dd:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ebp, regs.reg_ebp);
  8000e2:	ff 73 08             	pushl  0x8(%ebx)
  8000e5:	ff 76 08             	pushl  0x8(%esi)
  8000e8:	68 76 15 80 00       	push   $0x801576
  8000ed:	68 54 15 80 00       	push   $0x801554
  8000f2:	e8 d1 05 00 00       	call   8006c8 <cprintf>
  8000f7:	83 c4 10             	add    $0x10,%esp
  8000fa:	8b 43 08             	mov    0x8(%ebx),%eax
  8000fd:	39 46 08             	cmp    %eax,0x8(%esi)
  800100:	75 12                	jne    800114 <check_regs+0xe1>
  800102:	83 ec 0c             	sub    $0xc,%esp
  800105:	68 64 15 80 00       	push   $0x801564
  80010a:	e8 b9 05 00 00       	call   8006c8 <cprintf>
  80010f:	83 c4 10             	add    $0x10,%esp
  800112:	eb 15                	jmp    800129 <check_regs+0xf6>
  800114:	83 ec 0c             	sub    $0xc,%esp
  800117:	68 68 15 80 00       	push   $0x801568
  80011c:	e8 a7 05 00 00       	call   8006c8 <cprintf>
  800121:	83 c4 10             	add    $0x10,%esp
  800124:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ebx, regs.reg_ebx);
  800129:	ff 73 10             	pushl  0x10(%ebx)
  80012c:	ff 76 10             	pushl  0x10(%esi)
  80012f:	68 7a 15 80 00       	push   $0x80157a
  800134:	68 54 15 80 00       	push   $0x801554
  800139:	e8 8a 05 00 00       	call   8006c8 <cprintf>
  80013e:	83 c4 10             	add    $0x10,%esp
  800141:	8b 43 10             	mov    0x10(%ebx),%eax
  800144:	39 46 10             	cmp    %eax,0x10(%esi)
  800147:	75 12                	jne    80015b <check_regs+0x128>
  800149:	83 ec 0c             	sub    $0xc,%esp
  80014c:	68 64 15 80 00       	push   $0x801564
  800151:	e8 72 05 00 00       	call   8006c8 <cprintf>
  800156:	83 c4 10             	add    $0x10,%esp
  800159:	eb 15                	jmp    800170 <check_regs+0x13d>
  80015b:	83 ec 0c             	sub    $0xc,%esp
  80015e:	68 68 15 80 00       	push   $0x801568
  800163:	e8 60 05 00 00       	call   8006c8 <cprintf>
  800168:	83 c4 10             	add    $0x10,%esp
  80016b:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(edx, regs.reg_edx);
  800170:	ff 73 14             	pushl  0x14(%ebx)
  800173:	ff 76 14             	pushl  0x14(%esi)
  800176:	68 7e 15 80 00       	push   $0x80157e
  80017b:	68 54 15 80 00       	push   $0x801554
  800180:	e8 43 05 00 00       	call   8006c8 <cprintf>
  800185:	83 c4 10             	add    $0x10,%esp
  800188:	8b 43 14             	mov    0x14(%ebx),%eax
  80018b:	39 46 14             	cmp    %eax,0x14(%esi)
  80018e:	75 12                	jne    8001a2 <check_regs+0x16f>
  800190:	83 ec 0c             	sub    $0xc,%esp
  800193:	68 64 15 80 00       	push   $0x801564
  800198:	e8 2b 05 00 00       	call   8006c8 <cprintf>
  80019d:	83 c4 10             	add    $0x10,%esp
  8001a0:	eb 15                	jmp    8001b7 <check_regs+0x184>
  8001a2:	83 ec 0c             	sub    $0xc,%esp
  8001a5:	68 68 15 80 00       	push   $0x801568
  8001aa:	e8 19 05 00 00       	call   8006c8 <cprintf>
  8001af:	83 c4 10             	add    $0x10,%esp
  8001b2:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ecx, regs.reg_ecx);
  8001b7:	ff 73 18             	pushl  0x18(%ebx)
  8001ba:	ff 76 18             	pushl  0x18(%esi)
  8001bd:	68 82 15 80 00       	push   $0x801582
  8001c2:	68 54 15 80 00       	push   $0x801554
  8001c7:	e8 fc 04 00 00       	call   8006c8 <cprintf>
  8001cc:	83 c4 10             	add    $0x10,%esp
  8001cf:	8b 43 18             	mov    0x18(%ebx),%eax
  8001d2:	39 46 18             	cmp    %eax,0x18(%esi)
  8001d5:	75 12                	jne    8001e9 <check_regs+0x1b6>
  8001d7:	83 ec 0c             	sub    $0xc,%esp
  8001da:	68 64 15 80 00       	push   $0x801564
  8001df:	e8 e4 04 00 00       	call   8006c8 <cprintf>
  8001e4:	83 c4 10             	add    $0x10,%esp
  8001e7:	eb 15                	jmp    8001fe <check_regs+0x1cb>
  8001e9:	83 ec 0c             	sub    $0xc,%esp
  8001ec:	68 68 15 80 00       	push   $0x801568
  8001f1:	e8 d2 04 00 00       	call   8006c8 <cprintf>
  8001f6:	83 c4 10             	add    $0x10,%esp
  8001f9:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eax, regs.reg_eax);
  8001fe:	ff 73 1c             	pushl  0x1c(%ebx)
  800201:	ff 76 1c             	pushl  0x1c(%esi)
  800204:	68 86 15 80 00       	push   $0x801586
  800209:	68 54 15 80 00       	push   $0x801554
  80020e:	e8 b5 04 00 00       	call   8006c8 <cprintf>
  800213:	83 c4 10             	add    $0x10,%esp
  800216:	8b 43 1c             	mov    0x1c(%ebx),%eax
  800219:	39 46 1c             	cmp    %eax,0x1c(%esi)
  80021c:	75 12                	jne    800230 <check_regs+0x1fd>
  80021e:	83 ec 0c             	sub    $0xc,%esp
  800221:	68 64 15 80 00       	push   $0x801564
  800226:	e8 9d 04 00 00       	call   8006c8 <cprintf>
  80022b:	83 c4 10             	add    $0x10,%esp
  80022e:	eb 15                	jmp    800245 <check_regs+0x212>
  800230:	83 ec 0c             	sub    $0xc,%esp
  800233:	68 68 15 80 00       	push   $0x801568
  800238:	e8 8b 04 00 00       	call   8006c8 <cprintf>
  80023d:	83 c4 10             	add    $0x10,%esp
  800240:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eip, eip);
  800245:	ff 73 20             	pushl  0x20(%ebx)
  800248:	ff 76 20             	pushl  0x20(%esi)
  80024b:	68 8a 15 80 00       	push   $0x80158a
  800250:	68 54 15 80 00       	push   $0x801554
  800255:	e8 6e 04 00 00       	call   8006c8 <cprintf>
  80025a:	83 c4 10             	add    $0x10,%esp
  80025d:	8b 43 20             	mov    0x20(%ebx),%eax
  800260:	39 46 20             	cmp    %eax,0x20(%esi)
  800263:	75 12                	jne    800277 <check_regs+0x244>
  800265:	83 ec 0c             	sub    $0xc,%esp
  800268:	68 64 15 80 00       	push   $0x801564
  80026d:	e8 56 04 00 00       	call   8006c8 <cprintf>
  800272:	83 c4 10             	add    $0x10,%esp
  800275:	eb 15                	jmp    80028c <check_regs+0x259>
  800277:	83 ec 0c             	sub    $0xc,%esp
  80027a:	68 68 15 80 00       	push   $0x801568
  80027f:	e8 44 04 00 00       	call   8006c8 <cprintf>
  800284:	83 c4 10             	add    $0x10,%esp
  800287:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eflags, eflags);
  80028c:	ff 73 24             	pushl  0x24(%ebx)
  80028f:	ff 76 24             	pushl  0x24(%esi)
  800292:	68 8e 15 80 00       	push   $0x80158e
  800297:	68 54 15 80 00       	push   $0x801554
  80029c:	e8 27 04 00 00       	call   8006c8 <cprintf>
  8002a1:	83 c4 10             	add    $0x10,%esp
  8002a4:	8b 43 24             	mov    0x24(%ebx),%eax
  8002a7:	39 46 24             	cmp    %eax,0x24(%esi)
  8002aa:	75 2f                	jne    8002db <check_regs+0x2a8>
  8002ac:	83 ec 0c             	sub    $0xc,%esp
  8002af:	68 64 15 80 00       	push   $0x801564
  8002b4:	e8 0f 04 00 00       	call   8006c8 <cprintf>
	CHECK(esp, esp);
  8002b9:	ff 73 28             	pushl  0x28(%ebx)
  8002bc:	ff 76 28             	pushl  0x28(%esi)
  8002bf:	68 95 15 80 00       	push   $0x801595
  8002c4:	68 54 15 80 00       	push   $0x801554
  8002c9:	e8 fa 03 00 00       	call   8006c8 <cprintf>
  8002ce:	83 c4 20             	add    $0x20,%esp
  8002d1:	8b 43 28             	mov    0x28(%ebx),%eax
  8002d4:	39 46 28             	cmp    %eax,0x28(%esi)
  8002d7:	74 31                	je     80030a <check_regs+0x2d7>
  8002d9:	eb 55                	jmp    800330 <check_regs+0x2fd>
	CHECK(ebx, regs.reg_ebx);
	CHECK(edx, regs.reg_edx);
	CHECK(ecx, regs.reg_ecx);
	CHECK(eax, regs.reg_eax);
	CHECK(eip, eip);
	CHECK(eflags, eflags);
  8002db:	83 ec 0c             	sub    $0xc,%esp
  8002de:	68 68 15 80 00       	push   $0x801568
  8002e3:	e8 e0 03 00 00       	call   8006c8 <cprintf>
	CHECK(esp, esp);
  8002e8:	ff 73 28             	pushl  0x28(%ebx)
  8002eb:	ff 76 28             	pushl  0x28(%esi)
  8002ee:	68 95 15 80 00       	push   $0x801595
  8002f3:	68 54 15 80 00       	push   $0x801554
  8002f8:	e8 cb 03 00 00       	call   8006c8 <cprintf>
  8002fd:	83 c4 20             	add    $0x20,%esp
  800300:	8b 43 28             	mov    0x28(%ebx),%eax
  800303:	39 46 28             	cmp    %eax,0x28(%esi)
  800306:	75 28                	jne    800330 <check_regs+0x2fd>
  800308:	eb 6c                	jmp    800376 <check_regs+0x343>
  80030a:	83 ec 0c             	sub    $0xc,%esp
  80030d:	68 64 15 80 00       	push   $0x801564
  800312:	e8 b1 03 00 00       	call   8006c8 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  800317:	83 c4 08             	add    $0x8,%esp
  80031a:	ff 75 0c             	pushl  0xc(%ebp)
  80031d:	68 99 15 80 00       	push   $0x801599
  800322:	e8 a1 03 00 00       	call   8006c8 <cprintf>
	if (!mismatch)
  800327:	83 c4 10             	add    $0x10,%esp
  80032a:	85 ff                	test   %edi,%edi
  80032c:	74 24                	je     800352 <check_regs+0x31f>
  80032e:	eb 34                	jmp    800364 <check_regs+0x331>
	CHECK(edx, regs.reg_edx);
	CHECK(ecx, regs.reg_ecx);
	CHECK(eax, regs.reg_eax);
	CHECK(eip, eip);
	CHECK(eflags, eflags);
	CHECK(esp, esp);
  800330:	83 ec 0c             	sub    $0xc,%esp
  800333:	68 68 15 80 00       	push   $0x801568
  800338:	e8 8b 03 00 00       	call   8006c8 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  80033d:	83 c4 08             	add    $0x8,%esp
  800340:	ff 75 0c             	pushl  0xc(%ebp)
  800343:	68 99 15 80 00       	push   $0x801599
  800348:	e8 7b 03 00 00       	call   8006c8 <cprintf>
  80034d:	83 c4 10             	add    $0x10,%esp
  800350:	eb 12                	jmp    800364 <check_regs+0x331>
	if (!mismatch)
		cprintf("OK\n");
  800352:	83 ec 0c             	sub    $0xc,%esp
  800355:	68 64 15 80 00       	push   $0x801564
  80035a:	e8 69 03 00 00       	call   8006c8 <cprintf>
  80035f:	83 c4 10             	add    $0x10,%esp
  800362:	eb 34                	jmp    800398 <check_regs+0x365>
	else
		cprintf("MISMATCH\n");
  800364:	83 ec 0c             	sub    $0xc,%esp
  800367:	68 68 15 80 00       	push   $0x801568
  80036c:	e8 57 03 00 00       	call   8006c8 <cprintf>
  800371:	83 c4 10             	add    $0x10,%esp
}
  800374:	eb 22                	jmp    800398 <check_regs+0x365>
	CHECK(edx, regs.reg_edx);
	CHECK(ecx, regs.reg_ecx);
	CHECK(eax, regs.reg_eax);
	CHECK(eip, eip);
	CHECK(eflags, eflags);
	CHECK(esp, esp);
  800376:	83 ec 0c             	sub    $0xc,%esp
  800379:	68 64 15 80 00       	push   $0x801564
  80037e:	e8 45 03 00 00       	call   8006c8 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  800383:	83 c4 08             	add    $0x8,%esp
  800386:	ff 75 0c             	pushl  0xc(%ebp)
  800389:	68 99 15 80 00       	push   $0x801599
  80038e:	e8 35 03 00 00       	call   8006c8 <cprintf>
  800393:	83 c4 10             	add    $0x10,%esp
  800396:	eb cc                	jmp    800364 <check_regs+0x331>
	if (!mismatch)
		cprintf("OK\n");
	else
		cprintf("MISMATCH\n");
}
  800398:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80039b:	5b                   	pop    %ebx
  80039c:	5e                   	pop    %esi
  80039d:	5f                   	pop    %edi
  80039e:	5d                   	pop    %ebp
  80039f:	c3                   	ret    

008003a0 <pgfault>:

static void
pgfault(struct UTrapframe *utf)
{
  8003a0:	55                   	push   %ebp
  8003a1:	89 e5                	mov    %esp,%ebp
  8003a3:	83 ec 08             	sub    $0x8,%esp
  8003a6:	8b 45 08             	mov    0x8(%ebp),%eax
	int r;

	if (utf->utf_fault_va != (uint32_t)UTEMP)
  8003a9:	8b 10                	mov    (%eax),%edx
  8003ab:	81 fa 00 00 40 00    	cmp    $0x400000,%edx
  8003b1:	74 18                	je     8003cb <pgfault+0x2b>
		panic("pgfault expected at UTEMP, got 0x%08x (eip %08x)",
  8003b3:	83 ec 0c             	sub    $0xc,%esp
  8003b6:	ff 70 28             	pushl  0x28(%eax)
  8003b9:	52                   	push   %edx
  8003ba:	68 00 16 80 00       	push   $0x801600
  8003bf:	6a 51                	push   $0x51
  8003c1:	68 a7 15 80 00       	push   $0x8015a7
  8003c6:	e8 24 02 00 00       	call   8005ef <_panic>
		      utf->utf_fault_va, utf->utf_eip);

	// Check registers in UTrapframe
	during.regs = utf->utf_regs;
  8003cb:	8b 50 08             	mov    0x8(%eax),%edx
  8003ce:	89 15 60 20 80 00    	mov    %edx,0x802060
  8003d4:	8b 50 0c             	mov    0xc(%eax),%edx
  8003d7:	89 15 64 20 80 00    	mov    %edx,0x802064
  8003dd:	8b 50 10             	mov    0x10(%eax),%edx
  8003e0:	89 15 68 20 80 00    	mov    %edx,0x802068
  8003e6:	8b 50 14             	mov    0x14(%eax),%edx
  8003e9:	89 15 6c 20 80 00    	mov    %edx,0x80206c
  8003ef:	8b 50 18             	mov    0x18(%eax),%edx
  8003f2:	89 15 70 20 80 00    	mov    %edx,0x802070
  8003f8:	8b 50 1c             	mov    0x1c(%eax),%edx
  8003fb:	89 15 74 20 80 00    	mov    %edx,0x802074
  800401:	8b 50 20             	mov    0x20(%eax),%edx
  800404:	89 15 78 20 80 00    	mov    %edx,0x802078
  80040a:	8b 50 24             	mov    0x24(%eax),%edx
  80040d:	89 15 7c 20 80 00    	mov    %edx,0x80207c
	during.eip = utf->utf_eip;
  800413:	8b 50 28             	mov    0x28(%eax),%edx
  800416:	89 15 80 20 80 00    	mov    %edx,0x802080
	during.eflags = utf->utf_eflags & ~FL_RF;
  80041c:	8b 50 2c             	mov    0x2c(%eax),%edx
  80041f:	81 e2 ff ff fe ff    	and    $0xfffeffff,%edx
  800425:	89 15 84 20 80 00    	mov    %edx,0x802084
	during.esp = utf->utf_esp;
  80042b:	8b 40 30             	mov    0x30(%eax),%eax
  80042e:	a3 88 20 80 00       	mov    %eax,0x802088
	check_regs(&before, "before", &during, "during", "in UTrapframe");
  800433:	83 ec 08             	sub    $0x8,%esp
  800436:	68 bf 15 80 00       	push   $0x8015bf
  80043b:	68 cd 15 80 00       	push   $0x8015cd
  800440:	b9 60 20 80 00       	mov    $0x802060,%ecx
  800445:	ba b8 15 80 00       	mov    $0x8015b8,%edx
  80044a:	b8 a0 20 80 00       	mov    $0x8020a0,%eax
  80044f:	e8 df fb ff ff       	call   800033 <check_regs>

	// Map UTEMP so the write succeeds
	if ((r = sys_page_alloc(0, UTEMP, PTE_U|PTE_P|PTE_W)) < 0)
  800454:	83 c4 0c             	add    $0xc,%esp
  800457:	6a 07                	push   $0x7
  800459:	68 00 00 40 00       	push   $0x400000
  80045e:	6a 00                	push   $0x0
  800460:	e8 6a 0c 00 00       	call   8010cf <sys_page_alloc>
  800465:	83 c4 10             	add    $0x10,%esp
  800468:	85 c0                	test   %eax,%eax
  80046a:	79 12                	jns    80047e <pgfault+0xde>
		panic("sys_page_alloc: %e", r);
  80046c:	50                   	push   %eax
  80046d:	68 d4 15 80 00       	push   $0x8015d4
  800472:	6a 5c                	push   $0x5c
  800474:	68 a7 15 80 00       	push   $0x8015a7
  800479:	e8 71 01 00 00       	call   8005ef <_panic>
}
  80047e:	c9                   	leave  
  80047f:	c3                   	ret    

00800480 <umain>:

void
umain(int argc, char **argv)
{
  800480:	55                   	push   %ebp
  800481:	89 e5                	mov    %esp,%ebp
  800483:	83 ec 14             	sub    $0x14,%esp
	set_pgfault_handler(pgfault);
  800486:	68 a0 03 80 00       	push   $0x8003a0
  80048b:	e8 ee 0d 00 00       	call   80127e <set_pgfault_handler>

	asm volatile(
  800490:	50                   	push   %eax
  800491:	9c                   	pushf  
  800492:	58                   	pop    %eax
  800493:	0d d5 08 00 00       	or     $0x8d5,%eax
  800498:	50                   	push   %eax
  800499:	9d                   	popf   
  80049a:	a3 c4 20 80 00       	mov    %eax,0x8020c4
  80049f:	8d 05 da 04 80 00    	lea    0x8004da,%eax
  8004a5:	a3 c0 20 80 00       	mov    %eax,0x8020c0
  8004aa:	58                   	pop    %eax
  8004ab:	89 3d a0 20 80 00    	mov    %edi,0x8020a0
  8004b1:	89 35 a4 20 80 00    	mov    %esi,0x8020a4
  8004b7:	89 2d a8 20 80 00    	mov    %ebp,0x8020a8
  8004bd:	89 1d b0 20 80 00    	mov    %ebx,0x8020b0
  8004c3:	89 15 b4 20 80 00    	mov    %edx,0x8020b4
  8004c9:	89 0d b8 20 80 00    	mov    %ecx,0x8020b8
  8004cf:	a3 bc 20 80 00       	mov    %eax,0x8020bc
  8004d4:	89 25 c8 20 80 00    	mov    %esp,0x8020c8
  8004da:	c7 05 00 00 40 00 2a 	movl   $0x2a,0x400000
  8004e1:	00 00 00 
  8004e4:	89 3d 20 20 80 00    	mov    %edi,0x802020
  8004ea:	89 35 24 20 80 00    	mov    %esi,0x802024
  8004f0:	89 2d 28 20 80 00    	mov    %ebp,0x802028
  8004f6:	89 1d 30 20 80 00    	mov    %ebx,0x802030
  8004fc:	89 15 34 20 80 00    	mov    %edx,0x802034
  800502:	89 0d 38 20 80 00    	mov    %ecx,0x802038
  800508:	a3 3c 20 80 00       	mov    %eax,0x80203c
  80050d:	89 25 48 20 80 00    	mov    %esp,0x802048
  800513:	8b 3d a0 20 80 00    	mov    0x8020a0,%edi
  800519:	8b 35 a4 20 80 00    	mov    0x8020a4,%esi
  80051f:	8b 2d a8 20 80 00    	mov    0x8020a8,%ebp
  800525:	8b 1d b0 20 80 00    	mov    0x8020b0,%ebx
  80052b:	8b 15 b4 20 80 00    	mov    0x8020b4,%edx
  800531:	8b 0d b8 20 80 00    	mov    0x8020b8,%ecx
  800537:	a1 bc 20 80 00       	mov    0x8020bc,%eax
  80053c:	8b 25 c8 20 80 00    	mov    0x8020c8,%esp
  800542:	50                   	push   %eax
  800543:	9c                   	pushf  
  800544:	58                   	pop    %eax
  800545:	a3 44 20 80 00       	mov    %eax,0x802044
  80054a:	58                   	pop    %eax
		: : "m" (before), "m" (after) : "memory", "cc");

	// Check UTEMP to roughly determine that EIP was restored
	// correctly (of course, we probably wouldn't get this far if
	// it weren't)
	if (*(int*)UTEMP != 42)
  80054b:	83 c4 10             	add    $0x10,%esp
  80054e:	83 3d 00 00 40 00 2a 	cmpl   $0x2a,0x400000
  800555:	74 10                	je     800567 <umain+0xe7>
		cprintf("EIP after page-fault MISMATCH\n");
  800557:	83 ec 0c             	sub    $0xc,%esp
  80055a:	68 34 16 80 00       	push   $0x801634
  80055f:	e8 64 01 00 00       	call   8006c8 <cprintf>
  800564:	83 c4 10             	add    $0x10,%esp
	after.eip = before.eip;
  800567:	a1 c0 20 80 00       	mov    0x8020c0,%eax
  80056c:	a3 40 20 80 00       	mov    %eax,0x802040

	check_regs(&before, "before", &after, "after", "after page-fault");
  800571:	83 ec 08             	sub    $0x8,%esp
  800574:	68 e7 15 80 00       	push   $0x8015e7
  800579:	68 f8 15 80 00       	push   $0x8015f8
  80057e:	b9 20 20 80 00       	mov    $0x802020,%ecx
  800583:	ba b8 15 80 00       	mov    $0x8015b8,%edx
  800588:	b8 a0 20 80 00       	mov    $0x8020a0,%eax
  80058d:	e8 a1 fa ff ff       	call   800033 <check_regs>
}
  800592:	83 c4 10             	add    $0x10,%esp
  800595:	c9                   	leave  
  800596:	c3                   	ret    

00800597 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800597:	55                   	push   %ebp
  800598:	89 e5                	mov    %esp,%ebp
  80059a:	56                   	push   %esi
  80059b:	53                   	push   %ebx
  80059c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80059f:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = envs+ENVX(sys_getenvid());
  8005a2:	e8 ea 0a 00 00       	call   801091 <sys_getenvid>
  8005a7:	25 ff 03 00 00       	and    $0x3ff,%eax
  8005ac:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8005af:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8005b4:	a3 cc 20 80 00       	mov    %eax,0x8020cc
	// save the name of the program so that panic() can use it
	if (argc > 0)
  8005b9:	85 db                	test   %ebx,%ebx
  8005bb:	7e 07                	jle    8005c4 <libmain+0x2d>
		binaryname = argv[0];
  8005bd:	8b 06                	mov    (%esi),%eax
  8005bf:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8005c4:	83 ec 08             	sub    $0x8,%esp
  8005c7:	56                   	push   %esi
  8005c8:	53                   	push   %ebx
  8005c9:	e8 b2 fe ff ff       	call   800480 <umain>

	// exit gracefully
	exit();
  8005ce:	e8 0a 00 00 00       	call   8005dd <exit>
}
  8005d3:	83 c4 10             	add    $0x10,%esp
  8005d6:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8005d9:	5b                   	pop    %ebx
  8005da:	5e                   	pop    %esi
  8005db:	5d                   	pop    %ebp
  8005dc:	c3                   	ret    

008005dd <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8005dd:	55                   	push   %ebp
  8005de:	89 e5                	mov    %esp,%ebp
  8005e0:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8005e3:	6a 00                	push   $0x0
  8005e5:	e8 66 0a 00 00       	call   801050 <sys_env_destroy>
}
  8005ea:	83 c4 10             	add    $0x10,%esp
  8005ed:	c9                   	leave  
  8005ee:	c3                   	ret    

008005ef <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8005ef:	55                   	push   %ebp
  8005f0:	89 e5                	mov    %esp,%ebp
  8005f2:	56                   	push   %esi
  8005f3:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  8005f4:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8005f7:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8005fd:	e8 8f 0a 00 00       	call   801091 <sys_getenvid>
  800602:	83 ec 0c             	sub    $0xc,%esp
  800605:	ff 75 0c             	pushl  0xc(%ebp)
  800608:	ff 75 08             	pushl  0x8(%ebp)
  80060b:	56                   	push   %esi
  80060c:	50                   	push   %eax
  80060d:	68 60 16 80 00       	push   $0x801660
  800612:	e8 b1 00 00 00       	call   8006c8 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800617:	83 c4 18             	add    $0x18,%esp
  80061a:	53                   	push   %ebx
  80061b:	ff 75 10             	pushl  0x10(%ebp)
  80061e:	e8 54 00 00 00       	call   800677 <vcprintf>
	cprintf("\n");
  800623:	c7 04 24 70 15 80 00 	movl   $0x801570,(%esp)
  80062a:	e8 99 00 00 00       	call   8006c8 <cprintf>
  80062f:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800632:	cc                   	int3   
  800633:	eb fd                	jmp    800632 <_panic+0x43>

00800635 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800635:	55                   	push   %ebp
  800636:	89 e5                	mov    %esp,%ebp
  800638:	53                   	push   %ebx
  800639:	83 ec 04             	sub    $0x4,%esp
  80063c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80063f:	8b 13                	mov    (%ebx),%edx
  800641:	8d 42 01             	lea    0x1(%edx),%eax
  800644:	89 03                	mov    %eax,(%ebx)
  800646:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800649:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80064d:	3d ff 00 00 00       	cmp    $0xff,%eax
  800652:	75 1a                	jne    80066e <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800654:	83 ec 08             	sub    $0x8,%esp
  800657:	68 ff 00 00 00       	push   $0xff
  80065c:	8d 43 08             	lea    0x8(%ebx),%eax
  80065f:	50                   	push   %eax
  800660:	e8 ae 09 00 00       	call   801013 <sys_cputs>
		b->idx = 0;
  800665:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80066b:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80066e:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800672:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800675:	c9                   	leave  
  800676:	c3                   	ret    

00800677 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800677:	55                   	push   %ebp
  800678:	89 e5                	mov    %esp,%ebp
  80067a:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800680:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800687:	00 00 00 
	b.cnt = 0;
  80068a:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800691:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800694:	ff 75 0c             	pushl  0xc(%ebp)
  800697:	ff 75 08             	pushl  0x8(%ebp)
  80069a:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8006a0:	50                   	push   %eax
  8006a1:	68 35 06 80 00       	push   $0x800635
  8006a6:	e8 1a 01 00 00       	call   8007c5 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8006ab:	83 c4 08             	add    $0x8,%esp
  8006ae:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8006b4:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8006ba:	50                   	push   %eax
  8006bb:	e8 53 09 00 00       	call   801013 <sys_cputs>

	return b.cnt;
}
  8006c0:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8006c6:	c9                   	leave  
  8006c7:	c3                   	ret    

008006c8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8006c8:	55                   	push   %ebp
  8006c9:	89 e5                	mov    %esp,%ebp
  8006cb:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8006ce:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8006d1:	50                   	push   %eax
  8006d2:	ff 75 08             	pushl  0x8(%ebp)
  8006d5:	e8 9d ff ff ff       	call   800677 <vcprintf>
	va_end(ap);

	return cnt;
}
  8006da:	c9                   	leave  
  8006db:	c3                   	ret    

008006dc <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8006dc:	55                   	push   %ebp
  8006dd:	89 e5                	mov    %esp,%ebp
  8006df:	57                   	push   %edi
  8006e0:	56                   	push   %esi
  8006e1:	53                   	push   %ebx
  8006e2:	83 ec 1c             	sub    $0x1c,%esp
  8006e5:	89 c7                	mov    %eax,%edi
  8006e7:	89 d6                	mov    %edx,%esi
  8006e9:	8b 45 08             	mov    0x8(%ebp),%eax
  8006ec:	8b 55 0c             	mov    0xc(%ebp),%edx
  8006ef:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8006f2:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8006f5:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8006f8:	bb 00 00 00 00       	mov    $0x0,%ebx
  8006fd:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800700:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800703:	39 d3                	cmp    %edx,%ebx
  800705:	72 05                	jb     80070c <printnum+0x30>
  800707:	39 45 10             	cmp    %eax,0x10(%ebp)
  80070a:	77 45                	ja     800751 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80070c:	83 ec 0c             	sub    $0xc,%esp
  80070f:	ff 75 18             	pushl  0x18(%ebp)
  800712:	8b 45 14             	mov    0x14(%ebp),%eax
  800715:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800718:	53                   	push   %ebx
  800719:	ff 75 10             	pushl  0x10(%ebp)
  80071c:	83 ec 08             	sub    $0x8,%esp
  80071f:	ff 75 e4             	pushl  -0x1c(%ebp)
  800722:	ff 75 e0             	pushl  -0x20(%ebp)
  800725:	ff 75 dc             	pushl  -0x24(%ebp)
  800728:	ff 75 d8             	pushl  -0x28(%ebp)
  80072b:	e8 80 0b 00 00       	call   8012b0 <__udivdi3>
  800730:	83 c4 18             	add    $0x18,%esp
  800733:	52                   	push   %edx
  800734:	50                   	push   %eax
  800735:	89 f2                	mov    %esi,%edx
  800737:	89 f8                	mov    %edi,%eax
  800739:	e8 9e ff ff ff       	call   8006dc <printnum>
  80073e:	83 c4 20             	add    $0x20,%esp
  800741:	eb 18                	jmp    80075b <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800743:	83 ec 08             	sub    $0x8,%esp
  800746:	56                   	push   %esi
  800747:	ff 75 18             	pushl  0x18(%ebp)
  80074a:	ff d7                	call   *%edi
  80074c:	83 c4 10             	add    $0x10,%esp
  80074f:	eb 03                	jmp    800754 <printnum+0x78>
  800751:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800754:	83 eb 01             	sub    $0x1,%ebx
  800757:	85 db                	test   %ebx,%ebx
  800759:	7f e8                	jg     800743 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80075b:	83 ec 08             	sub    $0x8,%esp
  80075e:	56                   	push   %esi
  80075f:	83 ec 04             	sub    $0x4,%esp
  800762:	ff 75 e4             	pushl  -0x1c(%ebp)
  800765:	ff 75 e0             	pushl  -0x20(%ebp)
  800768:	ff 75 dc             	pushl  -0x24(%ebp)
  80076b:	ff 75 d8             	pushl  -0x28(%ebp)
  80076e:	e8 6d 0c 00 00       	call   8013e0 <__umoddi3>
  800773:	83 c4 14             	add    $0x14,%esp
  800776:	0f be 80 83 16 80 00 	movsbl 0x801683(%eax),%eax
  80077d:	50                   	push   %eax
  80077e:	ff d7                	call   *%edi
}
  800780:	83 c4 10             	add    $0x10,%esp
  800783:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800786:	5b                   	pop    %ebx
  800787:	5e                   	pop    %esi
  800788:	5f                   	pop    %edi
  800789:	5d                   	pop    %ebp
  80078a:	c3                   	ret    

0080078b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80078b:	55                   	push   %ebp
  80078c:	89 e5                	mov    %esp,%ebp
  80078e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800791:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800795:	8b 10                	mov    (%eax),%edx
  800797:	3b 50 04             	cmp    0x4(%eax),%edx
  80079a:	73 0a                	jae    8007a6 <sprintputch+0x1b>
		*b->buf++ = ch;
  80079c:	8d 4a 01             	lea    0x1(%edx),%ecx
  80079f:	89 08                	mov    %ecx,(%eax)
  8007a1:	8b 45 08             	mov    0x8(%ebp),%eax
  8007a4:	88 02                	mov    %al,(%edx)
}
  8007a6:	5d                   	pop    %ebp
  8007a7:	c3                   	ret    

008007a8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8007a8:	55                   	push   %ebp
  8007a9:	89 e5                	mov    %esp,%ebp
  8007ab:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8007ae:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8007b1:	50                   	push   %eax
  8007b2:	ff 75 10             	pushl  0x10(%ebp)
  8007b5:	ff 75 0c             	pushl  0xc(%ebp)
  8007b8:	ff 75 08             	pushl  0x8(%ebp)
  8007bb:	e8 05 00 00 00       	call   8007c5 <vprintfmt>
	va_end(ap);
}
  8007c0:	83 c4 10             	add    $0x10,%esp
  8007c3:	c9                   	leave  
  8007c4:	c3                   	ret    

008007c5 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8007c5:	55                   	push   %ebp
  8007c6:	89 e5                	mov    %esp,%ebp
  8007c8:	57                   	push   %edi
  8007c9:	56                   	push   %esi
  8007ca:	53                   	push   %ebx
  8007cb:	83 ec 2c             	sub    $0x2c,%esp
  8007ce:	8b 75 08             	mov    0x8(%ebp),%esi
  8007d1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8007d4:	8b 7d 10             	mov    0x10(%ebp),%edi
  8007d7:	eb 12                	jmp    8007eb <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8007d9:	85 c0                	test   %eax,%eax
  8007db:	0f 84 42 04 00 00    	je     800c23 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  8007e1:	83 ec 08             	sub    $0x8,%esp
  8007e4:	53                   	push   %ebx
  8007e5:	50                   	push   %eax
  8007e6:	ff d6                	call   *%esi
  8007e8:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8007eb:	83 c7 01             	add    $0x1,%edi
  8007ee:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8007f2:	83 f8 25             	cmp    $0x25,%eax
  8007f5:	75 e2                	jne    8007d9 <vprintfmt+0x14>
  8007f7:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8007fb:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800802:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800809:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800810:	b9 00 00 00 00       	mov    $0x0,%ecx
  800815:	eb 07                	jmp    80081e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800817:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80081a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80081e:	8d 47 01             	lea    0x1(%edi),%eax
  800821:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800824:	0f b6 07             	movzbl (%edi),%eax
  800827:	0f b6 d0             	movzbl %al,%edx
  80082a:	83 e8 23             	sub    $0x23,%eax
  80082d:	3c 55                	cmp    $0x55,%al
  80082f:	0f 87 d3 03 00 00    	ja     800c08 <vprintfmt+0x443>
  800835:	0f b6 c0             	movzbl %al,%eax
  800838:	ff 24 85 40 17 80 00 	jmp    *0x801740(,%eax,4)
  80083f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800842:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800846:	eb d6                	jmp    80081e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800848:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80084b:	b8 00 00 00 00       	mov    $0x0,%eax
  800850:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800853:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800856:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80085a:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  80085d:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800860:	83 f9 09             	cmp    $0x9,%ecx
  800863:	77 3f                	ja     8008a4 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800865:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800868:	eb e9                	jmp    800853 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80086a:	8b 45 14             	mov    0x14(%ebp),%eax
  80086d:	8b 00                	mov    (%eax),%eax
  80086f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800872:	8b 45 14             	mov    0x14(%ebp),%eax
  800875:	8d 40 04             	lea    0x4(%eax),%eax
  800878:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80087b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80087e:	eb 2a                	jmp    8008aa <vprintfmt+0xe5>
  800880:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800883:	85 c0                	test   %eax,%eax
  800885:	ba 00 00 00 00       	mov    $0x0,%edx
  80088a:	0f 49 d0             	cmovns %eax,%edx
  80088d:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800890:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800893:	eb 89                	jmp    80081e <vprintfmt+0x59>
  800895:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800898:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80089f:	e9 7a ff ff ff       	jmp    80081e <vprintfmt+0x59>
  8008a4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8008a7:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8008aa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8008ae:	0f 89 6a ff ff ff    	jns    80081e <vprintfmt+0x59>
				width = precision, precision = -1;
  8008b4:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8008b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8008ba:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8008c1:	e9 58 ff ff ff       	jmp    80081e <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8008c6:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8008cc:	e9 4d ff ff ff       	jmp    80081e <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8008d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8008d4:	8d 78 04             	lea    0x4(%eax),%edi
  8008d7:	83 ec 08             	sub    $0x8,%esp
  8008da:	53                   	push   %ebx
  8008db:	ff 30                	pushl  (%eax)
  8008dd:	ff d6                	call   *%esi
			break;
  8008df:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8008e2:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008e5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8008e8:	e9 fe fe ff ff       	jmp    8007eb <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8008ed:	8b 45 14             	mov    0x14(%ebp),%eax
  8008f0:	8d 78 04             	lea    0x4(%eax),%edi
  8008f3:	8b 00                	mov    (%eax),%eax
  8008f5:	99                   	cltd   
  8008f6:	31 d0                	xor    %edx,%eax
  8008f8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8008fa:	83 f8 08             	cmp    $0x8,%eax
  8008fd:	7f 0b                	jg     80090a <vprintfmt+0x145>
  8008ff:	8b 14 85 a0 18 80 00 	mov    0x8018a0(,%eax,4),%edx
  800906:	85 d2                	test   %edx,%edx
  800908:	75 1b                	jne    800925 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80090a:	50                   	push   %eax
  80090b:	68 9b 16 80 00       	push   $0x80169b
  800910:	53                   	push   %ebx
  800911:	56                   	push   %esi
  800912:	e8 91 fe ff ff       	call   8007a8 <printfmt>
  800917:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80091a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80091d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800920:	e9 c6 fe ff ff       	jmp    8007eb <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800925:	52                   	push   %edx
  800926:	68 a4 16 80 00       	push   $0x8016a4
  80092b:	53                   	push   %ebx
  80092c:	56                   	push   %esi
  80092d:	e8 76 fe ff ff       	call   8007a8 <printfmt>
  800932:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800935:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800938:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80093b:	e9 ab fe ff ff       	jmp    8007eb <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800940:	8b 45 14             	mov    0x14(%ebp),%eax
  800943:	83 c0 04             	add    $0x4,%eax
  800946:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800949:	8b 45 14             	mov    0x14(%ebp),%eax
  80094c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80094e:	85 ff                	test   %edi,%edi
  800950:	b8 94 16 80 00       	mov    $0x801694,%eax
  800955:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800958:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80095c:	0f 8e 94 00 00 00    	jle    8009f6 <vprintfmt+0x231>
  800962:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800966:	0f 84 98 00 00 00    	je     800a04 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  80096c:	83 ec 08             	sub    $0x8,%esp
  80096f:	ff 75 d0             	pushl  -0x30(%ebp)
  800972:	57                   	push   %edi
  800973:	e8 33 03 00 00       	call   800cab <strnlen>
  800978:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80097b:	29 c1                	sub    %eax,%ecx
  80097d:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  800980:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800983:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800987:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80098a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80098d:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80098f:	eb 0f                	jmp    8009a0 <vprintfmt+0x1db>
					putch(padc, putdat);
  800991:	83 ec 08             	sub    $0x8,%esp
  800994:	53                   	push   %ebx
  800995:	ff 75 e0             	pushl  -0x20(%ebp)
  800998:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80099a:	83 ef 01             	sub    $0x1,%edi
  80099d:	83 c4 10             	add    $0x10,%esp
  8009a0:	85 ff                	test   %edi,%edi
  8009a2:	7f ed                	jg     800991 <vprintfmt+0x1cc>
  8009a4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8009a7:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8009aa:	85 c9                	test   %ecx,%ecx
  8009ac:	b8 00 00 00 00       	mov    $0x0,%eax
  8009b1:	0f 49 c1             	cmovns %ecx,%eax
  8009b4:	29 c1                	sub    %eax,%ecx
  8009b6:	89 75 08             	mov    %esi,0x8(%ebp)
  8009b9:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8009bc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8009bf:	89 cb                	mov    %ecx,%ebx
  8009c1:	eb 4d                	jmp    800a10 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8009c3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8009c7:	74 1b                	je     8009e4 <vprintfmt+0x21f>
  8009c9:	0f be c0             	movsbl %al,%eax
  8009cc:	83 e8 20             	sub    $0x20,%eax
  8009cf:	83 f8 5e             	cmp    $0x5e,%eax
  8009d2:	76 10                	jbe    8009e4 <vprintfmt+0x21f>
					putch('?', putdat);
  8009d4:	83 ec 08             	sub    $0x8,%esp
  8009d7:	ff 75 0c             	pushl  0xc(%ebp)
  8009da:	6a 3f                	push   $0x3f
  8009dc:	ff 55 08             	call   *0x8(%ebp)
  8009df:	83 c4 10             	add    $0x10,%esp
  8009e2:	eb 0d                	jmp    8009f1 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  8009e4:	83 ec 08             	sub    $0x8,%esp
  8009e7:	ff 75 0c             	pushl  0xc(%ebp)
  8009ea:	52                   	push   %edx
  8009eb:	ff 55 08             	call   *0x8(%ebp)
  8009ee:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8009f1:	83 eb 01             	sub    $0x1,%ebx
  8009f4:	eb 1a                	jmp    800a10 <vprintfmt+0x24b>
  8009f6:	89 75 08             	mov    %esi,0x8(%ebp)
  8009f9:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8009fc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8009ff:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800a02:	eb 0c                	jmp    800a10 <vprintfmt+0x24b>
  800a04:	89 75 08             	mov    %esi,0x8(%ebp)
  800a07:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800a0a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800a0d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800a10:	83 c7 01             	add    $0x1,%edi
  800a13:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800a17:	0f be d0             	movsbl %al,%edx
  800a1a:	85 d2                	test   %edx,%edx
  800a1c:	74 23                	je     800a41 <vprintfmt+0x27c>
  800a1e:	85 f6                	test   %esi,%esi
  800a20:	78 a1                	js     8009c3 <vprintfmt+0x1fe>
  800a22:	83 ee 01             	sub    $0x1,%esi
  800a25:	79 9c                	jns    8009c3 <vprintfmt+0x1fe>
  800a27:	89 df                	mov    %ebx,%edi
  800a29:	8b 75 08             	mov    0x8(%ebp),%esi
  800a2c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a2f:	eb 18                	jmp    800a49 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800a31:	83 ec 08             	sub    $0x8,%esp
  800a34:	53                   	push   %ebx
  800a35:	6a 20                	push   $0x20
  800a37:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800a39:	83 ef 01             	sub    $0x1,%edi
  800a3c:	83 c4 10             	add    $0x10,%esp
  800a3f:	eb 08                	jmp    800a49 <vprintfmt+0x284>
  800a41:	89 df                	mov    %ebx,%edi
  800a43:	8b 75 08             	mov    0x8(%ebp),%esi
  800a46:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a49:	85 ff                	test   %edi,%edi
  800a4b:	7f e4                	jg     800a31 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800a4d:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800a50:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800a53:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800a56:	e9 90 fd ff ff       	jmp    8007eb <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800a5b:	83 f9 01             	cmp    $0x1,%ecx
  800a5e:	7e 19                	jle    800a79 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800a60:	8b 45 14             	mov    0x14(%ebp),%eax
  800a63:	8b 50 04             	mov    0x4(%eax),%edx
  800a66:	8b 00                	mov    (%eax),%eax
  800a68:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800a6b:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800a6e:	8b 45 14             	mov    0x14(%ebp),%eax
  800a71:	8d 40 08             	lea    0x8(%eax),%eax
  800a74:	89 45 14             	mov    %eax,0x14(%ebp)
  800a77:	eb 38                	jmp    800ab1 <vprintfmt+0x2ec>
	else if (lflag)
  800a79:	85 c9                	test   %ecx,%ecx
  800a7b:	74 1b                	je     800a98 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  800a7d:	8b 45 14             	mov    0x14(%ebp),%eax
  800a80:	8b 00                	mov    (%eax),%eax
  800a82:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800a85:	89 c1                	mov    %eax,%ecx
  800a87:	c1 f9 1f             	sar    $0x1f,%ecx
  800a8a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800a8d:	8b 45 14             	mov    0x14(%ebp),%eax
  800a90:	8d 40 04             	lea    0x4(%eax),%eax
  800a93:	89 45 14             	mov    %eax,0x14(%ebp)
  800a96:	eb 19                	jmp    800ab1 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800a98:	8b 45 14             	mov    0x14(%ebp),%eax
  800a9b:	8b 00                	mov    (%eax),%eax
  800a9d:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800aa0:	89 c1                	mov    %eax,%ecx
  800aa2:	c1 f9 1f             	sar    $0x1f,%ecx
  800aa5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800aa8:	8b 45 14             	mov    0x14(%ebp),%eax
  800aab:	8d 40 04             	lea    0x4(%eax),%eax
  800aae:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800ab1:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800ab4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800ab7:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800abc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800ac0:	0f 89 0e 01 00 00    	jns    800bd4 <vprintfmt+0x40f>
				putch('-', putdat);
  800ac6:	83 ec 08             	sub    $0x8,%esp
  800ac9:	53                   	push   %ebx
  800aca:	6a 2d                	push   $0x2d
  800acc:	ff d6                	call   *%esi
				num = -(long long) num;
  800ace:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800ad1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800ad4:	f7 da                	neg    %edx
  800ad6:	83 d1 00             	adc    $0x0,%ecx
  800ad9:	f7 d9                	neg    %ecx
  800adb:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800ade:	b8 0a 00 00 00       	mov    $0xa,%eax
  800ae3:	e9 ec 00 00 00       	jmp    800bd4 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800ae8:	83 f9 01             	cmp    $0x1,%ecx
  800aeb:	7e 18                	jle    800b05 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800aed:	8b 45 14             	mov    0x14(%ebp),%eax
  800af0:	8b 10                	mov    (%eax),%edx
  800af2:	8b 48 04             	mov    0x4(%eax),%ecx
  800af5:	8d 40 08             	lea    0x8(%eax),%eax
  800af8:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800afb:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b00:	e9 cf 00 00 00       	jmp    800bd4 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800b05:	85 c9                	test   %ecx,%ecx
  800b07:	74 1a                	je     800b23 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800b09:	8b 45 14             	mov    0x14(%ebp),%eax
  800b0c:	8b 10                	mov    (%eax),%edx
  800b0e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b13:	8d 40 04             	lea    0x4(%eax),%eax
  800b16:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800b19:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b1e:	e9 b1 00 00 00       	jmp    800bd4 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800b23:	8b 45 14             	mov    0x14(%ebp),%eax
  800b26:	8b 10                	mov    (%eax),%edx
  800b28:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b2d:	8d 40 04             	lea    0x4(%eax),%eax
  800b30:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800b33:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b38:	e9 97 00 00 00       	jmp    800bd4 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800b3d:	83 ec 08             	sub    $0x8,%esp
  800b40:	53                   	push   %ebx
  800b41:	6a 58                	push   $0x58
  800b43:	ff d6                	call   *%esi
			putch('X', putdat);
  800b45:	83 c4 08             	add    $0x8,%esp
  800b48:	53                   	push   %ebx
  800b49:	6a 58                	push   $0x58
  800b4b:	ff d6                	call   *%esi
			putch('X', putdat);
  800b4d:	83 c4 08             	add    $0x8,%esp
  800b50:	53                   	push   %ebx
  800b51:	6a 58                	push   $0x58
  800b53:	ff d6                	call   *%esi
			break;
  800b55:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800b58:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  800b5b:	e9 8b fc ff ff       	jmp    8007eb <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800b60:	83 ec 08             	sub    $0x8,%esp
  800b63:	53                   	push   %ebx
  800b64:	6a 30                	push   $0x30
  800b66:	ff d6                	call   *%esi
			putch('x', putdat);
  800b68:	83 c4 08             	add    $0x8,%esp
  800b6b:	53                   	push   %ebx
  800b6c:	6a 78                	push   $0x78
  800b6e:	ff d6                	call   *%esi
			num = (unsigned long long)
  800b70:	8b 45 14             	mov    0x14(%ebp),%eax
  800b73:	8b 10                	mov    (%eax),%edx
  800b75:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800b7a:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800b7d:	8d 40 04             	lea    0x4(%eax),%eax
  800b80:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800b83:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800b88:	eb 4a                	jmp    800bd4 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800b8a:	83 f9 01             	cmp    $0x1,%ecx
  800b8d:	7e 15                	jle    800ba4 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800b8f:	8b 45 14             	mov    0x14(%ebp),%eax
  800b92:	8b 10                	mov    (%eax),%edx
  800b94:	8b 48 04             	mov    0x4(%eax),%ecx
  800b97:	8d 40 08             	lea    0x8(%eax),%eax
  800b9a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800b9d:	b8 10 00 00 00       	mov    $0x10,%eax
  800ba2:	eb 30                	jmp    800bd4 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800ba4:	85 c9                	test   %ecx,%ecx
  800ba6:	74 17                	je     800bbf <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800ba8:	8b 45 14             	mov    0x14(%ebp),%eax
  800bab:	8b 10                	mov    (%eax),%edx
  800bad:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bb2:	8d 40 04             	lea    0x4(%eax),%eax
  800bb5:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800bb8:	b8 10 00 00 00       	mov    $0x10,%eax
  800bbd:	eb 15                	jmp    800bd4 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800bbf:	8b 45 14             	mov    0x14(%ebp),%eax
  800bc2:	8b 10                	mov    (%eax),%edx
  800bc4:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bc9:	8d 40 04             	lea    0x4(%eax),%eax
  800bcc:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800bcf:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800bd4:	83 ec 0c             	sub    $0xc,%esp
  800bd7:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800bdb:	57                   	push   %edi
  800bdc:	ff 75 e0             	pushl  -0x20(%ebp)
  800bdf:	50                   	push   %eax
  800be0:	51                   	push   %ecx
  800be1:	52                   	push   %edx
  800be2:	89 da                	mov    %ebx,%edx
  800be4:	89 f0                	mov    %esi,%eax
  800be6:	e8 f1 fa ff ff       	call   8006dc <printnum>
			break;
  800beb:	83 c4 20             	add    $0x20,%esp
  800bee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800bf1:	e9 f5 fb ff ff       	jmp    8007eb <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800bf6:	83 ec 08             	sub    $0x8,%esp
  800bf9:	53                   	push   %ebx
  800bfa:	52                   	push   %edx
  800bfb:	ff d6                	call   *%esi
			break;
  800bfd:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800c00:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800c03:	e9 e3 fb ff ff       	jmp    8007eb <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800c08:	83 ec 08             	sub    $0x8,%esp
  800c0b:	53                   	push   %ebx
  800c0c:	6a 25                	push   $0x25
  800c0e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800c10:	83 c4 10             	add    $0x10,%esp
  800c13:	eb 03                	jmp    800c18 <vprintfmt+0x453>
  800c15:	83 ef 01             	sub    $0x1,%edi
  800c18:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800c1c:	75 f7                	jne    800c15 <vprintfmt+0x450>
  800c1e:	e9 c8 fb ff ff       	jmp    8007eb <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800c23:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c26:	5b                   	pop    %ebx
  800c27:	5e                   	pop    %esi
  800c28:	5f                   	pop    %edi
  800c29:	5d                   	pop    %ebp
  800c2a:	c3                   	ret    

00800c2b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800c2b:	55                   	push   %ebp
  800c2c:	89 e5                	mov    %esp,%ebp
  800c2e:	83 ec 18             	sub    $0x18,%esp
  800c31:	8b 45 08             	mov    0x8(%ebp),%eax
  800c34:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800c37:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800c3a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800c3e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800c41:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800c48:	85 c0                	test   %eax,%eax
  800c4a:	74 26                	je     800c72 <vsnprintf+0x47>
  800c4c:	85 d2                	test   %edx,%edx
  800c4e:	7e 22                	jle    800c72 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800c50:	ff 75 14             	pushl  0x14(%ebp)
  800c53:	ff 75 10             	pushl  0x10(%ebp)
  800c56:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800c59:	50                   	push   %eax
  800c5a:	68 8b 07 80 00       	push   $0x80078b
  800c5f:	e8 61 fb ff ff       	call   8007c5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800c64:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800c67:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800c6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800c6d:	83 c4 10             	add    $0x10,%esp
  800c70:	eb 05                	jmp    800c77 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800c72:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800c77:	c9                   	leave  
  800c78:	c3                   	ret    

00800c79 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800c79:	55                   	push   %ebp
  800c7a:	89 e5                	mov    %esp,%ebp
  800c7c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800c7f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800c82:	50                   	push   %eax
  800c83:	ff 75 10             	pushl  0x10(%ebp)
  800c86:	ff 75 0c             	pushl  0xc(%ebp)
  800c89:	ff 75 08             	pushl  0x8(%ebp)
  800c8c:	e8 9a ff ff ff       	call   800c2b <vsnprintf>
	va_end(ap);

	return rc;
}
  800c91:	c9                   	leave  
  800c92:	c3                   	ret    

00800c93 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800c93:	55                   	push   %ebp
  800c94:	89 e5                	mov    %esp,%ebp
  800c96:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800c99:	b8 00 00 00 00       	mov    $0x0,%eax
  800c9e:	eb 03                	jmp    800ca3 <strlen+0x10>
		n++;
  800ca0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800ca3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800ca7:	75 f7                	jne    800ca0 <strlen+0xd>
		n++;
	return n;
}
  800ca9:	5d                   	pop    %ebp
  800caa:	c3                   	ret    

00800cab <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800cab:	55                   	push   %ebp
  800cac:	89 e5                	mov    %esp,%ebp
  800cae:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800cb1:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800cb4:	ba 00 00 00 00       	mov    $0x0,%edx
  800cb9:	eb 03                	jmp    800cbe <strnlen+0x13>
		n++;
  800cbb:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800cbe:	39 c2                	cmp    %eax,%edx
  800cc0:	74 08                	je     800cca <strnlen+0x1f>
  800cc2:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800cc6:	75 f3                	jne    800cbb <strnlen+0x10>
  800cc8:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800cca:	5d                   	pop    %ebp
  800ccb:	c3                   	ret    

00800ccc <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800ccc:	55                   	push   %ebp
  800ccd:	89 e5                	mov    %esp,%ebp
  800ccf:	53                   	push   %ebx
  800cd0:	8b 45 08             	mov    0x8(%ebp),%eax
  800cd3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800cd6:	89 c2                	mov    %eax,%edx
  800cd8:	83 c2 01             	add    $0x1,%edx
  800cdb:	83 c1 01             	add    $0x1,%ecx
  800cde:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800ce2:	88 5a ff             	mov    %bl,-0x1(%edx)
  800ce5:	84 db                	test   %bl,%bl
  800ce7:	75 ef                	jne    800cd8 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800ce9:	5b                   	pop    %ebx
  800cea:	5d                   	pop    %ebp
  800ceb:	c3                   	ret    

00800cec <strcat>:

char *
strcat(char *dst, const char *src)
{
  800cec:	55                   	push   %ebp
  800ced:	89 e5                	mov    %esp,%ebp
  800cef:	53                   	push   %ebx
  800cf0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800cf3:	53                   	push   %ebx
  800cf4:	e8 9a ff ff ff       	call   800c93 <strlen>
  800cf9:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800cfc:	ff 75 0c             	pushl  0xc(%ebp)
  800cff:	01 d8                	add    %ebx,%eax
  800d01:	50                   	push   %eax
  800d02:	e8 c5 ff ff ff       	call   800ccc <strcpy>
	return dst;
}
  800d07:	89 d8                	mov    %ebx,%eax
  800d09:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800d0c:	c9                   	leave  
  800d0d:	c3                   	ret    

00800d0e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800d0e:	55                   	push   %ebp
  800d0f:	89 e5                	mov    %esp,%ebp
  800d11:	56                   	push   %esi
  800d12:	53                   	push   %ebx
  800d13:	8b 75 08             	mov    0x8(%ebp),%esi
  800d16:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d19:	89 f3                	mov    %esi,%ebx
  800d1b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800d1e:	89 f2                	mov    %esi,%edx
  800d20:	eb 0f                	jmp    800d31 <strncpy+0x23>
		*dst++ = *src;
  800d22:	83 c2 01             	add    $0x1,%edx
  800d25:	0f b6 01             	movzbl (%ecx),%eax
  800d28:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800d2b:	80 39 01             	cmpb   $0x1,(%ecx)
  800d2e:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800d31:	39 da                	cmp    %ebx,%edx
  800d33:	75 ed                	jne    800d22 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800d35:	89 f0                	mov    %esi,%eax
  800d37:	5b                   	pop    %ebx
  800d38:	5e                   	pop    %esi
  800d39:	5d                   	pop    %ebp
  800d3a:	c3                   	ret    

00800d3b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800d3b:	55                   	push   %ebp
  800d3c:	89 e5                	mov    %esp,%ebp
  800d3e:	56                   	push   %esi
  800d3f:	53                   	push   %ebx
  800d40:	8b 75 08             	mov    0x8(%ebp),%esi
  800d43:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d46:	8b 55 10             	mov    0x10(%ebp),%edx
  800d49:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800d4b:	85 d2                	test   %edx,%edx
  800d4d:	74 21                	je     800d70 <strlcpy+0x35>
  800d4f:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800d53:	89 f2                	mov    %esi,%edx
  800d55:	eb 09                	jmp    800d60 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800d57:	83 c2 01             	add    $0x1,%edx
  800d5a:	83 c1 01             	add    $0x1,%ecx
  800d5d:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800d60:	39 c2                	cmp    %eax,%edx
  800d62:	74 09                	je     800d6d <strlcpy+0x32>
  800d64:	0f b6 19             	movzbl (%ecx),%ebx
  800d67:	84 db                	test   %bl,%bl
  800d69:	75 ec                	jne    800d57 <strlcpy+0x1c>
  800d6b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800d6d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800d70:	29 f0                	sub    %esi,%eax
}
  800d72:	5b                   	pop    %ebx
  800d73:	5e                   	pop    %esi
  800d74:	5d                   	pop    %ebp
  800d75:	c3                   	ret    

00800d76 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800d76:	55                   	push   %ebp
  800d77:	89 e5                	mov    %esp,%ebp
  800d79:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800d7c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800d7f:	eb 06                	jmp    800d87 <strcmp+0x11>
		p++, q++;
  800d81:	83 c1 01             	add    $0x1,%ecx
  800d84:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800d87:	0f b6 01             	movzbl (%ecx),%eax
  800d8a:	84 c0                	test   %al,%al
  800d8c:	74 04                	je     800d92 <strcmp+0x1c>
  800d8e:	3a 02                	cmp    (%edx),%al
  800d90:	74 ef                	je     800d81 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800d92:	0f b6 c0             	movzbl %al,%eax
  800d95:	0f b6 12             	movzbl (%edx),%edx
  800d98:	29 d0                	sub    %edx,%eax
}
  800d9a:	5d                   	pop    %ebp
  800d9b:	c3                   	ret    

00800d9c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800d9c:	55                   	push   %ebp
  800d9d:	89 e5                	mov    %esp,%ebp
  800d9f:	53                   	push   %ebx
  800da0:	8b 45 08             	mov    0x8(%ebp),%eax
  800da3:	8b 55 0c             	mov    0xc(%ebp),%edx
  800da6:	89 c3                	mov    %eax,%ebx
  800da8:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800dab:	eb 06                	jmp    800db3 <strncmp+0x17>
		n--, p++, q++;
  800dad:	83 c0 01             	add    $0x1,%eax
  800db0:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800db3:	39 d8                	cmp    %ebx,%eax
  800db5:	74 15                	je     800dcc <strncmp+0x30>
  800db7:	0f b6 08             	movzbl (%eax),%ecx
  800dba:	84 c9                	test   %cl,%cl
  800dbc:	74 04                	je     800dc2 <strncmp+0x26>
  800dbe:	3a 0a                	cmp    (%edx),%cl
  800dc0:	74 eb                	je     800dad <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800dc2:	0f b6 00             	movzbl (%eax),%eax
  800dc5:	0f b6 12             	movzbl (%edx),%edx
  800dc8:	29 d0                	sub    %edx,%eax
  800dca:	eb 05                	jmp    800dd1 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800dcc:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800dd1:	5b                   	pop    %ebx
  800dd2:	5d                   	pop    %ebp
  800dd3:	c3                   	ret    

00800dd4 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800dd4:	55                   	push   %ebp
  800dd5:	89 e5                	mov    %esp,%ebp
  800dd7:	8b 45 08             	mov    0x8(%ebp),%eax
  800dda:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800dde:	eb 07                	jmp    800de7 <strchr+0x13>
		if (*s == c)
  800de0:	38 ca                	cmp    %cl,%dl
  800de2:	74 0f                	je     800df3 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800de4:	83 c0 01             	add    $0x1,%eax
  800de7:	0f b6 10             	movzbl (%eax),%edx
  800dea:	84 d2                	test   %dl,%dl
  800dec:	75 f2                	jne    800de0 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800dee:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800df3:	5d                   	pop    %ebp
  800df4:	c3                   	ret    

00800df5 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800df5:	55                   	push   %ebp
  800df6:	89 e5                	mov    %esp,%ebp
  800df8:	8b 45 08             	mov    0x8(%ebp),%eax
  800dfb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800dff:	eb 03                	jmp    800e04 <strfind+0xf>
  800e01:	83 c0 01             	add    $0x1,%eax
  800e04:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800e07:	38 ca                	cmp    %cl,%dl
  800e09:	74 04                	je     800e0f <strfind+0x1a>
  800e0b:	84 d2                	test   %dl,%dl
  800e0d:	75 f2                	jne    800e01 <strfind+0xc>
			break;
	return (char *) s;
}
  800e0f:	5d                   	pop    %ebp
  800e10:	c3                   	ret    

00800e11 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800e11:	55                   	push   %ebp
  800e12:	89 e5                	mov    %esp,%ebp
  800e14:	57                   	push   %edi
  800e15:	56                   	push   %esi
  800e16:	53                   	push   %ebx
  800e17:	8b 7d 08             	mov    0x8(%ebp),%edi
  800e1a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800e1d:	85 c9                	test   %ecx,%ecx
  800e1f:	74 36                	je     800e57 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800e21:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800e27:	75 28                	jne    800e51 <memset+0x40>
  800e29:	f6 c1 03             	test   $0x3,%cl
  800e2c:	75 23                	jne    800e51 <memset+0x40>
		c &= 0xFF;
  800e2e:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800e32:	89 d3                	mov    %edx,%ebx
  800e34:	c1 e3 08             	shl    $0x8,%ebx
  800e37:	89 d6                	mov    %edx,%esi
  800e39:	c1 e6 18             	shl    $0x18,%esi
  800e3c:	89 d0                	mov    %edx,%eax
  800e3e:	c1 e0 10             	shl    $0x10,%eax
  800e41:	09 f0                	or     %esi,%eax
  800e43:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800e45:	89 d8                	mov    %ebx,%eax
  800e47:	09 d0                	or     %edx,%eax
  800e49:	c1 e9 02             	shr    $0x2,%ecx
  800e4c:	fc                   	cld    
  800e4d:	f3 ab                	rep stos %eax,%es:(%edi)
  800e4f:	eb 06                	jmp    800e57 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800e51:	8b 45 0c             	mov    0xc(%ebp),%eax
  800e54:	fc                   	cld    
  800e55:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800e57:	89 f8                	mov    %edi,%eax
  800e59:	5b                   	pop    %ebx
  800e5a:	5e                   	pop    %esi
  800e5b:	5f                   	pop    %edi
  800e5c:	5d                   	pop    %ebp
  800e5d:	c3                   	ret    

00800e5e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800e5e:	55                   	push   %ebp
  800e5f:	89 e5                	mov    %esp,%ebp
  800e61:	57                   	push   %edi
  800e62:	56                   	push   %esi
  800e63:	8b 45 08             	mov    0x8(%ebp),%eax
  800e66:	8b 75 0c             	mov    0xc(%ebp),%esi
  800e69:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800e6c:	39 c6                	cmp    %eax,%esi
  800e6e:	73 35                	jae    800ea5 <memmove+0x47>
  800e70:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800e73:	39 d0                	cmp    %edx,%eax
  800e75:	73 2e                	jae    800ea5 <memmove+0x47>
		s += n;
		d += n;
  800e77:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e7a:	89 d6                	mov    %edx,%esi
  800e7c:	09 fe                	or     %edi,%esi
  800e7e:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800e84:	75 13                	jne    800e99 <memmove+0x3b>
  800e86:	f6 c1 03             	test   $0x3,%cl
  800e89:	75 0e                	jne    800e99 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800e8b:	83 ef 04             	sub    $0x4,%edi
  800e8e:	8d 72 fc             	lea    -0x4(%edx),%esi
  800e91:	c1 e9 02             	shr    $0x2,%ecx
  800e94:	fd                   	std    
  800e95:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e97:	eb 09                	jmp    800ea2 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800e99:	83 ef 01             	sub    $0x1,%edi
  800e9c:	8d 72 ff             	lea    -0x1(%edx),%esi
  800e9f:	fd                   	std    
  800ea0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ea2:	fc                   	cld    
  800ea3:	eb 1d                	jmp    800ec2 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ea5:	89 f2                	mov    %esi,%edx
  800ea7:	09 c2                	or     %eax,%edx
  800ea9:	f6 c2 03             	test   $0x3,%dl
  800eac:	75 0f                	jne    800ebd <memmove+0x5f>
  800eae:	f6 c1 03             	test   $0x3,%cl
  800eb1:	75 0a                	jne    800ebd <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800eb3:	c1 e9 02             	shr    $0x2,%ecx
  800eb6:	89 c7                	mov    %eax,%edi
  800eb8:	fc                   	cld    
  800eb9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ebb:	eb 05                	jmp    800ec2 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800ebd:	89 c7                	mov    %eax,%edi
  800ebf:	fc                   	cld    
  800ec0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ec2:	5e                   	pop    %esi
  800ec3:	5f                   	pop    %edi
  800ec4:	5d                   	pop    %ebp
  800ec5:	c3                   	ret    

00800ec6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800ec6:	55                   	push   %ebp
  800ec7:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800ec9:	ff 75 10             	pushl  0x10(%ebp)
  800ecc:	ff 75 0c             	pushl  0xc(%ebp)
  800ecf:	ff 75 08             	pushl  0x8(%ebp)
  800ed2:	e8 87 ff ff ff       	call   800e5e <memmove>
}
  800ed7:	c9                   	leave  
  800ed8:	c3                   	ret    

00800ed9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800ed9:	55                   	push   %ebp
  800eda:	89 e5                	mov    %esp,%ebp
  800edc:	56                   	push   %esi
  800edd:	53                   	push   %ebx
  800ede:	8b 45 08             	mov    0x8(%ebp),%eax
  800ee1:	8b 55 0c             	mov    0xc(%ebp),%edx
  800ee4:	89 c6                	mov    %eax,%esi
  800ee6:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ee9:	eb 1a                	jmp    800f05 <memcmp+0x2c>
		if (*s1 != *s2)
  800eeb:	0f b6 08             	movzbl (%eax),%ecx
  800eee:	0f b6 1a             	movzbl (%edx),%ebx
  800ef1:	38 d9                	cmp    %bl,%cl
  800ef3:	74 0a                	je     800eff <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800ef5:	0f b6 c1             	movzbl %cl,%eax
  800ef8:	0f b6 db             	movzbl %bl,%ebx
  800efb:	29 d8                	sub    %ebx,%eax
  800efd:	eb 0f                	jmp    800f0e <memcmp+0x35>
		s1++, s2++;
  800eff:	83 c0 01             	add    $0x1,%eax
  800f02:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800f05:	39 f0                	cmp    %esi,%eax
  800f07:	75 e2                	jne    800eeb <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800f09:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800f0e:	5b                   	pop    %ebx
  800f0f:	5e                   	pop    %esi
  800f10:	5d                   	pop    %ebp
  800f11:	c3                   	ret    

00800f12 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800f12:	55                   	push   %ebp
  800f13:	89 e5                	mov    %esp,%ebp
  800f15:	53                   	push   %ebx
  800f16:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800f19:	89 c1                	mov    %eax,%ecx
  800f1b:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800f1e:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800f22:	eb 0a                	jmp    800f2e <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800f24:	0f b6 10             	movzbl (%eax),%edx
  800f27:	39 da                	cmp    %ebx,%edx
  800f29:	74 07                	je     800f32 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800f2b:	83 c0 01             	add    $0x1,%eax
  800f2e:	39 c8                	cmp    %ecx,%eax
  800f30:	72 f2                	jb     800f24 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800f32:	5b                   	pop    %ebx
  800f33:	5d                   	pop    %ebp
  800f34:	c3                   	ret    

00800f35 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800f35:	55                   	push   %ebp
  800f36:	89 e5                	mov    %esp,%ebp
  800f38:	57                   	push   %edi
  800f39:	56                   	push   %esi
  800f3a:	53                   	push   %ebx
  800f3b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800f3e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f41:	eb 03                	jmp    800f46 <strtol+0x11>
		s++;
  800f43:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f46:	0f b6 01             	movzbl (%ecx),%eax
  800f49:	3c 20                	cmp    $0x20,%al
  800f4b:	74 f6                	je     800f43 <strtol+0xe>
  800f4d:	3c 09                	cmp    $0x9,%al
  800f4f:	74 f2                	je     800f43 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800f51:	3c 2b                	cmp    $0x2b,%al
  800f53:	75 0a                	jne    800f5f <strtol+0x2a>
		s++;
  800f55:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800f58:	bf 00 00 00 00       	mov    $0x0,%edi
  800f5d:	eb 11                	jmp    800f70 <strtol+0x3b>
  800f5f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800f64:	3c 2d                	cmp    $0x2d,%al
  800f66:	75 08                	jne    800f70 <strtol+0x3b>
		s++, neg = 1;
  800f68:	83 c1 01             	add    $0x1,%ecx
  800f6b:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800f70:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800f76:	75 15                	jne    800f8d <strtol+0x58>
  800f78:	80 39 30             	cmpb   $0x30,(%ecx)
  800f7b:	75 10                	jne    800f8d <strtol+0x58>
  800f7d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800f81:	75 7c                	jne    800fff <strtol+0xca>
		s += 2, base = 16;
  800f83:	83 c1 02             	add    $0x2,%ecx
  800f86:	bb 10 00 00 00       	mov    $0x10,%ebx
  800f8b:	eb 16                	jmp    800fa3 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800f8d:	85 db                	test   %ebx,%ebx
  800f8f:	75 12                	jne    800fa3 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800f91:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800f96:	80 39 30             	cmpb   $0x30,(%ecx)
  800f99:	75 08                	jne    800fa3 <strtol+0x6e>
		s++, base = 8;
  800f9b:	83 c1 01             	add    $0x1,%ecx
  800f9e:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800fa3:	b8 00 00 00 00       	mov    $0x0,%eax
  800fa8:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800fab:	0f b6 11             	movzbl (%ecx),%edx
  800fae:	8d 72 d0             	lea    -0x30(%edx),%esi
  800fb1:	89 f3                	mov    %esi,%ebx
  800fb3:	80 fb 09             	cmp    $0x9,%bl
  800fb6:	77 08                	ja     800fc0 <strtol+0x8b>
			dig = *s - '0';
  800fb8:	0f be d2             	movsbl %dl,%edx
  800fbb:	83 ea 30             	sub    $0x30,%edx
  800fbe:	eb 22                	jmp    800fe2 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800fc0:	8d 72 9f             	lea    -0x61(%edx),%esi
  800fc3:	89 f3                	mov    %esi,%ebx
  800fc5:	80 fb 19             	cmp    $0x19,%bl
  800fc8:	77 08                	ja     800fd2 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800fca:	0f be d2             	movsbl %dl,%edx
  800fcd:	83 ea 57             	sub    $0x57,%edx
  800fd0:	eb 10                	jmp    800fe2 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800fd2:	8d 72 bf             	lea    -0x41(%edx),%esi
  800fd5:	89 f3                	mov    %esi,%ebx
  800fd7:	80 fb 19             	cmp    $0x19,%bl
  800fda:	77 16                	ja     800ff2 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800fdc:	0f be d2             	movsbl %dl,%edx
  800fdf:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800fe2:	3b 55 10             	cmp    0x10(%ebp),%edx
  800fe5:	7d 0b                	jge    800ff2 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800fe7:	83 c1 01             	add    $0x1,%ecx
  800fea:	0f af 45 10          	imul   0x10(%ebp),%eax
  800fee:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ff0:	eb b9                	jmp    800fab <strtol+0x76>

	if (endptr)
  800ff2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ff6:	74 0d                	je     801005 <strtol+0xd0>
		*endptr = (char *) s;
  800ff8:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ffb:	89 0e                	mov    %ecx,(%esi)
  800ffd:	eb 06                	jmp    801005 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800fff:	85 db                	test   %ebx,%ebx
  801001:	74 98                	je     800f9b <strtol+0x66>
  801003:	eb 9e                	jmp    800fa3 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  801005:	89 c2                	mov    %eax,%edx
  801007:	f7 da                	neg    %edx
  801009:	85 ff                	test   %edi,%edi
  80100b:	0f 45 c2             	cmovne %edx,%eax
}
  80100e:	5b                   	pop    %ebx
  80100f:	5e                   	pop    %esi
  801010:	5f                   	pop    %edi
  801011:	5d                   	pop    %ebp
  801012:	c3                   	ret    

00801013 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  801013:	55                   	push   %ebp
  801014:	89 e5                	mov    %esp,%ebp
  801016:	57                   	push   %edi
  801017:	56                   	push   %esi
  801018:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801019:	b8 00 00 00 00       	mov    $0x0,%eax
  80101e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801021:	8b 55 08             	mov    0x8(%ebp),%edx
  801024:	89 c3                	mov    %eax,%ebx
  801026:	89 c7                	mov    %eax,%edi
  801028:	89 c6                	mov    %eax,%esi
  80102a:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  80102c:	5b                   	pop    %ebx
  80102d:	5e                   	pop    %esi
  80102e:	5f                   	pop    %edi
  80102f:	5d                   	pop    %ebp
  801030:	c3                   	ret    

00801031 <sys_cgetc>:

int
sys_cgetc(void)
{
  801031:	55                   	push   %ebp
  801032:	89 e5                	mov    %esp,%ebp
  801034:	57                   	push   %edi
  801035:	56                   	push   %esi
  801036:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801037:	ba 00 00 00 00       	mov    $0x0,%edx
  80103c:	b8 01 00 00 00       	mov    $0x1,%eax
  801041:	89 d1                	mov    %edx,%ecx
  801043:	89 d3                	mov    %edx,%ebx
  801045:	89 d7                	mov    %edx,%edi
  801047:	89 d6                	mov    %edx,%esi
  801049:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  80104b:	5b                   	pop    %ebx
  80104c:	5e                   	pop    %esi
  80104d:	5f                   	pop    %edi
  80104e:	5d                   	pop    %ebp
  80104f:	c3                   	ret    

00801050 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  801050:	55                   	push   %ebp
  801051:	89 e5                	mov    %esp,%ebp
  801053:	57                   	push   %edi
  801054:	56                   	push   %esi
  801055:	53                   	push   %ebx
  801056:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801059:	b9 00 00 00 00       	mov    $0x0,%ecx
  80105e:	b8 03 00 00 00       	mov    $0x3,%eax
  801063:	8b 55 08             	mov    0x8(%ebp),%edx
  801066:	89 cb                	mov    %ecx,%ebx
  801068:	89 cf                	mov    %ecx,%edi
  80106a:	89 ce                	mov    %ecx,%esi
  80106c:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  80106e:	85 c0                	test   %eax,%eax
  801070:	7e 17                	jle    801089 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  801072:	83 ec 0c             	sub    $0xc,%esp
  801075:	50                   	push   %eax
  801076:	6a 03                	push   $0x3
  801078:	68 c4 18 80 00       	push   $0x8018c4
  80107d:	6a 23                	push   $0x23
  80107f:	68 e1 18 80 00       	push   $0x8018e1
  801084:	e8 66 f5 ff ff       	call   8005ef <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  801089:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80108c:	5b                   	pop    %ebx
  80108d:	5e                   	pop    %esi
  80108e:	5f                   	pop    %edi
  80108f:	5d                   	pop    %ebp
  801090:	c3                   	ret    

00801091 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  801091:	55                   	push   %ebp
  801092:	89 e5                	mov    %esp,%ebp
  801094:	57                   	push   %edi
  801095:	56                   	push   %esi
  801096:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801097:	ba 00 00 00 00       	mov    $0x0,%edx
  80109c:	b8 02 00 00 00       	mov    $0x2,%eax
  8010a1:	89 d1                	mov    %edx,%ecx
  8010a3:	89 d3                	mov    %edx,%ebx
  8010a5:	89 d7                	mov    %edx,%edi
  8010a7:	89 d6                	mov    %edx,%esi
  8010a9:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  8010ab:	5b                   	pop    %ebx
  8010ac:	5e                   	pop    %esi
  8010ad:	5f                   	pop    %edi
  8010ae:	5d                   	pop    %ebp
  8010af:	c3                   	ret    

008010b0 <sys_yield>:

void
sys_yield(void)
{
  8010b0:	55                   	push   %ebp
  8010b1:	89 e5                	mov    %esp,%ebp
  8010b3:	57                   	push   %edi
  8010b4:	56                   	push   %esi
  8010b5:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8010b6:	ba 00 00 00 00       	mov    $0x0,%edx
  8010bb:	b8 0a 00 00 00       	mov    $0xa,%eax
  8010c0:	89 d1                	mov    %edx,%ecx
  8010c2:	89 d3                	mov    %edx,%ebx
  8010c4:	89 d7                	mov    %edx,%edi
  8010c6:	89 d6                	mov    %edx,%esi
  8010c8:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  8010ca:	5b                   	pop    %ebx
  8010cb:	5e                   	pop    %esi
  8010cc:	5f                   	pop    %edi
  8010cd:	5d                   	pop    %ebp
  8010ce:	c3                   	ret    

008010cf <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  8010cf:	55                   	push   %ebp
  8010d0:	89 e5                	mov    %esp,%ebp
  8010d2:	57                   	push   %edi
  8010d3:	56                   	push   %esi
  8010d4:	53                   	push   %ebx
  8010d5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8010d8:	be 00 00 00 00       	mov    $0x0,%esi
  8010dd:	b8 04 00 00 00       	mov    $0x4,%eax
  8010e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8010e5:	8b 55 08             	mov    0x8(%ebp),%edx
  8010e8:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8010eb:	89 f7                	mov    %esi,%edi
  8010ed:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8010ef:	85 c0                	test   %eax,%eax
  8010f1:	7e 17                	jle    80110a <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  8010f3:	83 ec 0c             	sub    $0xc,%esp
  8010f6:	50                   	push   %eax
  8010f7:	6a 04                	push   $0x4
  8010f9:	68 c4 18 80 00       	push   $0x8018c4
  8010fe:	6a 23                	push   $0x23
  801100:	68 e1 18 80 00       	push   $0x8018e1
  801105:	e8 e5 f4 ff ff       	call   8005ef <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  80110a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80110d:	5b                   	pop    %ebx
  80110e:	5e                   	pop    %esi
  80110f:	5f                   	pop    %edi
  801110:	5d                   	pop    %ebp
  801111:	c3                   	ret    

00801112 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  801112:	55                   	push   %ebp
  801113:	89 e5                	mov    %esp,%ebp
  801115:	57                   	push   %edi
  801116:	56                   	push   %esi
  801117:	53                   	push   %ebx
  801118:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80111b:	b8 05 00 00 00       	mov    $0x5,%eax
  801120:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801123:	8b 55 08             	mov    0x8(%ebp),%edx
  801126:	8b 5d 10             	mov    0x10(%ebp),%ebx
  801129:	8b 7d 14             	mov    0x14(%ebp),%edi
  80112c:	8b 75 18             	mov    0x18(%ebp),%esi
  80112f:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  801131:	85 c0                	test   %eax,%eax
  801133:	7e 17                	jle    80114c <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  801135:	83 ec 0c             	sub    $0xc,%esp
  801138:	50                   	push   %eax
  801139:	6a 05                	push   $0x5
  80113b:	68 c4 18 80 00       	push   $0x8018c4
  801140:	6a 23                	push   $0x23
  801142:	68 e1 18 80 00       	push   $0x8018e1
  801147:	e8 a3 f4 ff ff       	call   8005ef <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  80114c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80114f:	5b                   	pop    %ebx
  801150:	5e                   	pop    %esi
  801151:	5f                   	pop    %edi
  801152:	5d                   	pop    %ebp
  801153:	c3                   	ret    

00801154 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  801154:	55                   	push   %ebp
  801155:	89 e5                	mov    %esp,%ebp
  801157:	57                   	push   %edi
  801158:	56                   	push   %esi
  801159:	53                   	push   %ebx
  80115a:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80115d:	bb 00 00 00 00       	mov    $0x0,%ebx
  801162:	b8 06 00 00 00       	mov    $0x6,%eax
  801167:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80116a:	8b 55 08             	mov    0x8(%ebp),%edx
  80116d:	89 df                	mov    %ebx,%edi
  80116f:	89 de                	mov    %ebx,%esi
  801171:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  801173:	85 c0                	test   %eax,%eax
  801175:	7e 17                	jle    80118e <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  801177:	83 ec 0c             	sub    $0xc,%esp
  80117a:	50                   	push   %eax
  80117b:	6a 06                	push   $0x6
  80117d:	68 c4 18 80 00       	push   $0x8018c4
  801182:	6a 23                	push   $0x23
  801184:	68 e1 18 80 00       	push   $0x8018e1
  801189:	e8 61 f4 ff ff       	call   8005ef <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  80118e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801191:	5b                   	pop    %ebx
  801192:	5e                   	pop    %esi
  801193:	5f                   	pop    %edi
  801194:	5d                   	pop    %ebp
  801195:	c3                   	ret    

00801196 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  801196:	55                   	push   %ebp
  801197:	89 e5                	mov    %esp,%ebp
  801199:	57                   	push   %edi
  80119a:	56                   	push   %esi
  80119b:	53                   	push   %ebx
  80119c:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80119f:	bb 00 00 00 00       	mov    $0x0,%ebx
  8011a4:	b8 08 00 00 00       	mov    $0x8,%eax
  8011a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8011ac:	8b 55 08             	mov    0x8(%ebp),%edx
  8011af:	89 df                	mov    %ebx,%edi
  8011b1:	89 de                	mov    %ebx,%esi
  8011b3:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8011b5:	85 c0                	test   %eax,%eax
  8011b7:	7e 17                	jle    8011d0 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8011b9:	83 ec 0c             	sub    $0xc,%esp
  8011bc:	50                   	push   %eax
  8011bd:	6a 08                	push   $0x8
  8011bf:	68 c4 18 80 00       	push   $0x8018c4
  8011c4:	6a 23                	push   $0x23
  8011c6:	68 e1 18 80 00       	push   $0x8018e1
  8011cb:	e8 1f f4 ff ff       	call   8005ef <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  8011d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8011d3:	5b                   	pop    %ebx
  8011d4:	5e                   	pop    %esi
  8011d5:	5f                   	pop    %edi
  8011d6:	5d                   	pop    %ebp
  8011d7:	c3                   	ret    

008011d8 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  8011d8:	55                   	push   %ebp
  8011d9:	89 e5                	mov    %esp,%ebp
  8011db:	57                   	push   %edi
  8011dc:	56                   	push   %esi
  8011dd:	53                   	push   %ebx
  8011de:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8011e1:	bb 00 00 00 00       	mov    $0x0,%ebx
  8011e6:	b8 09 00 00 00       	mov    $0x9,%eax
  8011eb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8011ee:	8b 55 08             	mov    0x8(%ebp),%edx
  8011f1:	89 df                	mov    %ebx,%edi
  8011f3:	89 de                	mov    %ebx,%esi
  8011f5:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8011f7:	85 c0                	test   %eax,%eax
  8011f9:	7e 17                	jle    801212 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8011fb:	83 ec 0c             	sub    $0xc,%esp
  8011fe:	50                   	push   %eax
  8011ff:	6a 09                	push   $0x9
  801201:	68 c4 18 80 00       	push   $0x8018c4
  801206:	6a 23                	push   $0x23
  801208:	68 e1 18 80 00       	push   $0x8018e1
  80120d:	e8 dd f3 ff ff       	call   8005ef <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  801212:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801215:	5b                   	pop    %ebx
  801216:	5e                   	pop    %esi
  801217:	5f                   	pop    %edi
  801218:	5d                   	pop    %ebp
  801219:	c3                   	ret    

0080121a <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  80121a:	55                   	push   %ebp
  80121b:	89 e5                	mov    %esp,%ebp
  80121d:	57                   	push   %edi
  80121e:	56                   	push   %esi
  80121f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801220:	be 00 00 00 00       	mov    $0x0,%esi
  801225:	b8 0b 00 00 00       	mov    $0xb,%eax
  80122a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80122d:	8b 55 08             	mov    0x8(%ebp),%edx
  801230:	8b 5d 10             	mov    0x10(%ebp),%ebx
  801233:	8b 7d 14             	mov    0x14(%ebp),%edi
  801236:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  801238:	5b                   	pop    %ebx
  801239:	5e                   	pop    %esi
  80123a:	5f                   	pop    %edi
  80123b:	5d                   	pop    %ebp
  80123c:	c3                   	ret    

0080123d <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  80123d:	55                   	push   %ebp
  80123e:	89 e5                	mov    %esp,%ebp
  801240:	57                   	push   %edi
  801241:	56                   	push   %esi
  801242:	53                   	push   %ebx
  801243:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801246:	b9 00 00 00 00       	mov    $0x0,%ecx
  80124b:	b8 0c 00 00 00       	mov    $0xc,%eax
  801250:	8b 55 08             	mov    0x8(%ebp),%edx
  801253:	89 cb                	mov    %ecx,%ebx
  801255:	89 cf                	mov    %ecx,%edi
  801257:	89 ce                	mov    %ecx,%esi
  801259:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  80125b:	85 c0                	test   %eax,%eax
  80125d:	7e 17                	jle    801276 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  80125f:	83 ec 0c             	sub    $0xc,%esp
  801262:	50                   	push   %eax
  801263:	6a 0c                	push   $0xc
  801265:	68 c4 18 80 00       	push   $0x8018c4
  80126a:	6a 23                	push   $0x23
  80126c:	68 e1 18 80 00       	push   $0x8018e1
  801271:	e8 79 f3 ff ff       	call   8005ef <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  801276:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801279:	5b                   	pop    %ebx
  80127a:	5e                   	pop    %esi
  80127b:	5f                   	pop    %edi
  80127c:	5d                   	pop    %ebp
  80127d:	c3                   	ret    

0080127e <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  80127e:	55                   	push   %ebp
  80127f:	89 e5                	mov    %esp,%ebp
  801281:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  801284:	83 3d d0 20 80 00 00 	cmpl   $0x0,0x8020d0
  80128b:	75 14                	jne    8012a1 <set_pgfault_handler+0x23>
		// First time through!
		// LAB 4: Your code here.
		panic("set_pgfault_handler not implemented");
  80128d:	83 ec 04             	sub    $0x4,%esp
  801290:	68 f0 18 80 00       	push   $0x8018f0
  801295:	6a 20                	push   $0x20
  801297:	68 14 19 80 00       	push   $0x801914
  80129c:	e8 4e f3 ff ff       	call   8005ef <_panic>
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  8012a1:	8b 45 08             	mov    0x8(%ebp),%eax
  8012a4:	a3 d0 20 80 00       	mov    %eax,0x8020d0
}
  8012a9:	c9                   	leave  
  8012aa:	c3                   	ret    
  8012ab:	66 90                	xchg   %ax,%ax
  8012ad:	66 90                	xchg   %ax,%ax
  8012af:	90                   	nop

008012b0 <__udivdi3>:
  8012b0:	55                   	push   %ebp
  8012b1:	57                   	push   %edi
  8012b2:	56                   	push   %esi
  8012b3:	53                   	push   %ebx
  8012b4:	83 ec 1c             	sub    $0x1c,%esp
  8012b7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  8012bb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  8012bf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  8012c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  8012c7:	85 f6                	test   %esi,%esi
  8012c9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8012cd:	89 ca                	mov    %ecx,%edx
  8012cf:	89 f8                	mov    %edi,%eax
  8012d1:	75 3d                	jne    801310 <__udivdi3+0x60>
  8012d3:	39 cf                	cmp    %ecx,%edi
  8012d5:	0f 87 c5 00 00 00    	ja     8013a0 <__udivdi3+0xf0>
  8012db:	85 ff                	test   %edi,%edi
  8012dd:	89 fd                	mov    %edi,%ebp
  8012df:	75 0b                	jne    8012ec <__udivdi3+0x3c>
  8012e1:	b8 01 00 00 00       	mov    $0x1,%eax
  8012e6:	31 d2                	xor    %edx,%edx
  8012e8:	f7 f7                	div    %edi
  8012ea:	89 c5                	mov    %eax,%ebp
  8012ec:	89 c8                	mov    %ecx,%eax
  8012ee:	31 d2                	xor    %edx,%edx
  8012f0:	f7 f5                	div    %ebp
  8012f2:	89 c1                	mov    %eax,%ecx
  8012f4:	89 d8                	mov    %ebx,%eax
  8012f6:	89 cf                	mov    %ecx,%edi
  8012f8:	f7 f5                	div    %ebp
  8012fa:	89 c3                	mov    %eax,%ebx
  8012fc:	89 d8                	mov    %ebx,%eax
  8012fe:	89 fa                	mov    %edi,%edx
  801300:	83 c4 1c             	add    $0x1c,%esp
  801303:	5b                   	pop    %ebx
  801304:	5e                   	pop    %esi
  801305:	5f                   	pop    %edi
  801306:	5d                   	pop    %ebp
  801307:	c3                   	ret    
  801308:	90                   	nop
  801309:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801310:	39 ce                	cmp    %ecx,%esi
  801312:	77 74                	ja     801388 <__udivdi3+0xd8>
  801314:	0f bd fe             	bsr    %esi,%edi
  801317:	83 f7 1f             	xor    $0x1f,%edi
  80131a:	0f 84 98 00 00 00    	je     8013b8 <__udivdi3+0x108>
  801320:	bb 20 00 00 00       	mov    $0x20,%ebx
  801325:	89 f9                	mov    %edi,%ecx
  801327:	89 c5                	mov    %eax,%ebp
  801329:	29 fb                	sub    %edi,%ebx
  80132b:	d3 e6                	shl    %cl,%esi
  80132d:	89 d9                	mov    %ebx,%ecx
  80132f:	d3 ed                	shr    %cl,%ebp
  801331:	89 f9                	mov    %edi,%ecx
  801333:	d3 e0                	shl    %cl,%eax
  801335:	09 ee                	or     %ebp,%esi
  801337:	89 d9                	mov    %ebx,%ecx
  801339:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80133d:	89 d5                	mov    %edx,%ebp
  80133f:	8b 44 24 08          	mov    0x8(%esp),%eax
  801343:	d3 ed                	shr    %cl,%ebp
  801345:	89 f9                	mov    %edi,%ecx
  801347:	d3 e2                	shl    %cl,%edx
  801349:	89 d9                	mov    %ebx,%ecx
  80134b:	d3 e8                	shr    %cl,%eax
  80134d:	09 c2                	or     %eax,%edx
  80134f:	89 d0                	mov    %edx,%eax
  801351:	89 ea                	mov    %ebp,%edx
  801353:	f7 f6                	div    %esi
  801355:	89 d5                	mov    %edx,%ebp
  801357:	89 c3                	mov    %eax,%ebx
  801359:	f7 64 24 0c          	mull   0xc(%esp)
  80135d:	39 d5                	cmp    %edx,%ebp
  80135f:	72 10                	jb     801371 <__udivdi3+0xc1>
  801361:	8b 74 24 08          	mov    0x8(%esp),%esi
  801365:	89 f9                	mov    %edi,%ecx
  801367:	d3 e6                	shl    %cl,%esi
  801369:	39 c6                	cmp    %eax,%esi
  80136b:	73 07                	jae    801374 <__udivdi3+0xc4>
  80136d:	39 d5                	cmp    %edx,%ebp
  80136f:	75 03                	jne    801374 <__udivdi3+0xc4>
  801371:	83 eb 01             	sub    $0x1,%ebx
  801374:	31 ff                	xor    %edi,%edi
  801376:	89 d8                	mov    %ebx,%eax
  801378:	89 fa                	mov    %edi,%edx
  80137a:	83 c4 1c             	add    $0x1c,%esp
  80137d:	5b                   	pop    %ebx
  80137e:	5e                   	pop    %esi
  80137f:	5f                   	pop    %edi
  801380:	5d                   	pop    %ebp
  801381:	c3                   	ret    
  801382:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801388:	31 ff                	xor    %edi,%edi
  80138a:	31 db                	xor    %ebx,%ebx
  80138c:	89 d8                	mov    %ebx,%eax
  80138e:	89 fa                	mov    %edi,%edx
  801390:	83 c4 1c             	add    $0x1c,%esp
  801393:	5b                   	pop    %ebx
  801394:	5e                   	pop    %esi
  801395:	5f                   	pop    %edi
  801396:	5d                   	pop    %ebp
  801397:	c3                   	ret    
  801398:	90                   	nop
  801399:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8013a0:	89 d8                	mov    %ebx,%eax
  8013a2:	f7 f7                	div    %edi
  8013a4:	31 ff                	xor    %edi,%edi
  8013a6:	89 c3                	mov    %eax,%ebx
  8013a8:	89 d8                	mov    %ebx,%eax
  8013aa:	89 fa                	mov    %edi,%edx
  8013ac:	83 c4 1c             	add    $0x1c,%esp
  8013af:	5b                   	pop    %ebx
  8013b0:	5e                   	pop    %esi
  8013b1:	5f                   	pop    %edi
  8013b2:	5d                   	pop    %ebp
  8013b3:	c3                   	ret    
  8013b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8013b8:	39 ce                	cmp    %ecx,%esi
  8013ba:	72 0c                	jb     8013c8 <__udivdi3+0x118>
  8013bc:	31 db                	xor    %ebx,%ebx
  8013be:	3b 44 24 08          	cmp    0x8(%esp),%eax
  8013c2:	0f 87 34 ff ff ff    	ja     8012fc <__udivdi3+0x4c>
  8013c8:	bb 01 00 00 00       	mov    $0x1,%ebx
  8013cd:	e9 2a ff ff ff       	jmp    8012fc <__udivdi3+0x4c>
  8013d2:	66 90                	xchg   %ax,%ax
  8013d4:	66 90                	xchg   %ax,%ax
  8013d6:	66 90                	xchg   %ax,%ax
  8013d8:	66 90                	xchg   %ax,%ax
  8013da:	66 90                	xchg   %ax,%ax
  8013dc:	66 90                	xchg   %ax,%ax
  8013de:	66 90                	xchg   %ax,%ax

008013e0 <__umoddi3>:
  8013e0:	55                   	push   %ebp
  8013e1:	57                   	push   %edi
  8013e2:	56                   	push   %esi
  8013e3:	53                   	push   %ebx
  8013e4:	83 ec 1c             	sub    $0x1c,%esp
  8013e7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  8013eb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  8013ef:	8b 74 24 34          	mov    0x34(%esp),%esi
  8013f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  8013f7:	85 d2                	test   %edx,%edx
  8013f9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8013fd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801401:	89 f3                	mov    %esi,%ebx
  801403:	89 3c 24             	mov    %edi,(%esp)
  801406:	89 74 24 04          	mov    %esi,0x4(%esp)
  80140a:	75 1c                	jne    801428 <__umoddi3+0x48>
  80140c:	39 f7                	cmp    %esi,%edi
  80140e:	76 50                	jbe    801460 <__umoddi3+0x80>
  801410:	89 c8                	mov    %ecx,%eax
  801412:	89 f2                	mov    %esi,%edx
  801414:	f7 f7                	div    %edi
  801416:	89 d0                	mov    %edx,%eax
  801418:	31 d2                	xor    %edx,%edx
  80141a:	83 c4 1c             	add    $0x1c,%esp
  80141d:	5b                   	pop    %ebx
  80141e:	5e                   	pop    %esi
  80141f:	5f                   	pop    %edi
  801420:	5d                   	pop    %ebp
  801421:	c3                   	ret    
  801422:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801428:	39 f2                	cmp    %esi,%edx
  80142a:	89 d0                	mov    %edx,%eax
  80142c:	77 52                	ja     801480 <__umoddi3+0xa0>
  80142e:	0f bd ea             	bsr    %edx,%ebp
  801431:	83 f5 1f             	xor    $0x1f,%ebp
  801434:	75 5a                	jne    801490 <__umoddi3+0xb0>
  801436:	3b 54 24 04          	cmp    0x4(%esp),%edx
  80143a:	0f 82 e0 00 00 00    	jb     801520 <__umoddi3+0x140>
  801440:	39 0c 24             	cmp    %ecx,(%esp)
  801443:	0f 86 d7 00 00 00    	jbe    801520 <__umoddi3+0x140>
  801449:	8b 44 24 08          	mov    0x8(%esp),%eax
  80144d:	8b 54 24 04          	mov    0x4(%esp),%edx
  801451:	83 c4 1c             	add    $0x1c,%esp
  801454:	5b                   	pop    %ebx
  801455:	5e                   	pop    %esi
  801456:	5f                   	pop    %edi
  801457:	5d                   	pop    %ebp
  801458:	c3                   	ret    
  801459:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801460:	85 ff                	test   %edi,%edi
  801462:	89 fd                	mov    %edi,%ebp
  801464:	75 0b                	jne    801471 <__umoddi3+0x91>
  801466:	b8 01 00 00 00       	mov    $0x1,%eax
  80146b:	31 d2                	xor    %edx,%edx
  80146d:	f7 f7                	div    %edi
  80146f:	89 c5                	mov    %eax,%ebp
  801471:	89 f0                	mov    %esi,%eax
  801473:	31 d2                	xor    %edx,%edx
  801475:	f7 f5                	div    %ebp
  801477:	89 c8                	mov    %ecx,%eax
  801479:	f7 f5                	div    %ebp
  80147b:	89 d0                	mov    %edx,%eax
  80147d:	eb 99                	jmp    801418 <__umoddi3+0x38>
  80147f:	90                   	nop
  801480:	89 c8                	mov    %ecx,%eax
  801482:	89 f2                	mov    %esi,%edx
  801484:	83 c4 1c             	add    $0x1c,%esp
  801487:	5b                   	pop    %ebx
  801488:	5e                   	pop    %esi
  801489:	5f                   	pop    %edi
  80148a:	5d                   	pop    %ebp
  80148b:	c3                   	ret    
  80148c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801490:	8b 34 24             	mov    (%esp),%esi
  801493:	bf 20 00 00 00       	mov    $0x20,%edi
  801498:	89 e9                	mov    %ebp,%ecx
  80149a:	29 ef                	sub    %ebp,%edi
  80149c:	d3 e0                	shl    %cl,%eax
  80149e:	89 f9                	mov    %edi,%ecx
  8014a0:	89 f2                	mov    %esi,%edx
  8014a2:	d3 ea                	shr    %cl,%edx
  8014a4:	89 e9                	mov    %ebp,%ecx
  8014a6:	09 c2                	or     %eax,%edx
  8014a8:	89 d8                	mov    %ebx,%eax
  8014aa:	89 14 24             	mov    %edx,(%esp)
  8014ad:	89 f2                	mov    %esi,%edx
  8014af:	d3 e2                	shl    %cl,%edx
  8014b1:	89 f9                	mov    %edi,%ecx
  8014b3:	89 54 24 04          	mov    %edx,0x4(%esp)
  8014b7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8014bb:	d3 e8                	shr    %cl,%eax
  8014bd:	89 e9                	mov    %ebp,%ecx
  8014bf:	89 c6                	mov    %eax,%esi
  8014c1:	d3 e3                	shl    %cl,%ebx
  8014c3:	89 f9                	mov    %edi,%ecx
  8014c5:	89 d0                	mov    %edx,%eax
  8014c7:	d3 e8                	shr    %cl,%eax
  8014c9:	89 e9                	mov    %ebp,%ecx
  8014cb:	09 d8                	or     %ebx,%eax
  8014cd:	89 d3                	mov    %edx,%ebx
  8014cf:	89 f2                	mov    %esi,%edx
  8014d1:	f7 34 24             	divl   (%esp)
  8014d4:	89 d6                	mov    %edx,%esi
  8014d6:	d3 e3                	shl    %cl,%ebx
  8014d8:	f7 64 24 04          	mull   0x4(%esp)
  8014dc:	39 d6                	cmp    %edx,%esi
  8014de:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8014e2:	89 d1                	mov    %edx,%ecx
  8014e4:	89 c3                	mov    %eax,%ebx
  8014e6:	72 08                	jb     8014f0 <__umoddi3+0x110>
  8014e8:	75 11                	jne    8014fb <__umoddi3+0x11b>
  8014ea:	39 44 24 08          	cmp    %eax,0x8(%esp)
  8014ee:	73 0b                	jae    8014fb <__umoddi3+0x11b>
  8014f0:	2b 44 24 04          	sub    0x4(%esp),%eax
  8014f4:	1b 14 24             	sbb    (%esp),%edx
  8014f7:	89 d1                	mov    %edx,%ecx
  8014f9:	89 c3                	mov    %eax,%ebx
  8014fb:	8b 54 24 08          	mov    0x8(%esp),%edx
  8014ff:	29 da                	sub    %ebx,%edx
  801501:	19 ce                	sbb    %ecx,%esi
  801503:	89 f9                	mov    %edi,%ecx
  801505:	89 f0                	mov    %esi,%eax
  801507:	d3 e0                	shl    %cl,%eax
  801509:	89 e9                	mov    %ebp,%ecx
  80150b:	d3 ea                	shr    %cl,%edx
  80150d:	89 e9                	mov    %ebp,%ecx
  80150f:	d3 ee                	shr    %cl,%esi
  801511:	09 d0                	or     %edx,%eax
  801513:	89 f2                	mov    %esi,%edx
  801515:	83 c4 1c             	add    $0x1c,%esp
  801518:	5b                   	pop    %ebx
  801519:	5e                   	pop    %esi
  80151a:	5f                   	pop    %edi
  80151b:	5d                   	pop    %ebp
  80151c:	c3                   	ret    
  80151d:	8d 76 00             	lea    0x0(%esi),%esi
  801520:	29 f9                	sub    %edi,%ecx
  801522:	19 d6                	sbb    %edx,%esi
  801524:	89 74 24 04          	mov    %esi,0x4(%esp)
  801528:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80152c:	e9 18 ff ff ff       	jmp    801449 <__umoddi3+0x69>
