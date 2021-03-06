
obj/user/faultnostack:     file format elf32-i386


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
  80002c:	e8 23 00 00 00       	call   800054 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

void _pgfault_upcall();

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_env_set_pgfault_upcall(0, (void*) _pgfault_upcall);
  800039:	68 17 03 80 00       	push   $0x800317
  80003e:	6a 00                	push   $0x0
  800040:	e8 2c 02 00 00       	call   800271 <sys_env_set_pgfault_upcall>
	*(int*)0 = 0;
  800045:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
  80004c:	00 00 00 
}
  80004f:	83 c4 10             	add    $0x10,%esp
  800052:	c9                   	leave  
  800053:	c3                   	ret    

00800054 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800054:	55                   	push   %ebp
  800055:	89 e5                	mov    %esp,%ebp
  800057:	56                   	push   %esi
  800058:	53                   	push   %ebx
  800059:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = envs+ENVX(sys_getenvid());
  80005f:	e8 c6 00 00 00       	call   80012a <sys_getenvid>
  800064:	25 ff 03 00 00       	and    $0x3ff,%eax
  800069:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80006c:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800071:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800076:	85 db                	test   %ebx,%ebx
  800078:	7e 07                	jle    800081 <libmain+0x2d>
		binaryname = argv[0];
  80007a:	8b 06                	mov    (%esi),%eax
  80007c:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800081:	83 ec 08             	sub    $0x8,%esp
  800084:	56                   	push   %esi
  800085:	53                   	push   %ebx
  800086:	e8 a8 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008b:	e8 0a 00 00 00       	call   80009a <exit>
}
  800090:	83 c4 10             	add    $0x10,%esp
  800093:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800096:	5b                   	pop    %ebx
  800097:	5e                   	pop    %esi
  800098:	5d                   	pop    %ebp
  800099:	c3                   	ret    

0080009a <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80009a:	55                   	push   %ebp
  80009b:	89 e5                	mov    %esp,%ebp
  80009d:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000a0:	6a 00                	push   $0x0
  8000a2:	e8 42 00 00 00       	call   8000e9 <sys_env_destroy>
}
  8000a7:	83 c4 10             	add    $0x10,%esp
  8000aa:	c9                   	leave  
  8000ab:	c3                   	ret    

008000ac <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000ac:	55                   	push   %ebp
  8000ad:	89 e5                	mov    %esp,%ebp
  8000af:	57                   	push   %edi
  8000b0:	56                   	push   %esi
  8000b1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b2:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000ba:	8b 55 08             	mov    0x8(%ebp),%edx
  8000bd:	89 c3                	mov    %eax,%ebx
  8000bf:	89 c7                	mov    %eax,%edi
  8000c1:	89 c6                	mov    %eax,%esi
  8000c3:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c5:	5b                   	pop    %ebx
  8000c6:	5e                   	pop    %esi
  8000c7:	5f                   	pop    %edi
  8000c8:	5d                   	pop    %ebp
  8000c9:	c3                   	ret    

008000ca <sys_cgetc>:

int
sys_cgetc(void)
{
  8000ca:	55                   	push   %ebp
  8000cb:	89 e5                	mov    %esp,%ebp
  8000cd:	57                   	push   %edi
  8000ce:	56                   	push   %esi
  8000cf:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d0:	ba 00 00 00 00       	mov    $0x0,%edx
  8000d5:	b8 01 00 00 00       	mov    $0x1,%eax
  8000da:	89 d1                	mov    %edx,%ecx
  8000dc:	89 d3                	mov    %edx,%ebx
  8000de:	89 d7                	mov    %edx,%edi
  8000e0:	89 d6                	mov    %edx,%esi
  8000e2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000e4:	5b                   	pop    %ebx
  8000e5:	5e                   	pop    %esi
  8000e6:	5f                   	pop    %edi
  8000e7:	5d                   	pop    %ebp
  8000e8:	c3                   	ret    

008000e9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000e9:	55                   	push   %ebp
  8000ea:	89 e5                	mov    %esp,%ebp
  8000ec:	57                   	push   %edi
  8000ed:	56                   	push   %esi
  8000ee:	53                   	push   %ebx
  8000ef:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000f2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000f7:	b8 03 00 00 00       	mov    $0x3,%eax
  8000fc:	8b 55 08             	mov    0x8(%ebp),%edx
  8000ff:	89 cb                	mov    %ecx,%ebx
  800101:	89 cf                	mov    %ecx,%edi
  800103:	89 ce                	mov    %ecx,%esi
  800105:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800107:	85 c0                	test   %eax,%eax
  800109:	7e 17                	jle    800122 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  80010b:	83 ec 0c             	sub    $0xc,%esp
  80010e:	50                   	push   %eax
  80010f:	6a 03                	push   $0x3
  800111:	68 2a 10 80 00       	push   $0x80102a
  800116:	6a 23                	push   $0x23
  800118:	68 47 10 80 00       	push   $0x801047
  80011d:	e8 00 02 00 00       	call   800322 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800122:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800125:	5b                   	pop    %ebx
  800126:	5e                   	pop    %esi
  800127:	5f                   	pop    %edi
  800128:	5d                   	pop    %ebp
  800129:	c3                   	ret    

0080012a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80012a:	55                   	push   %ebp
  80012b:	89 e5                	mov    %esp,%ebp
  80012d:	57                   	push   %edi
  80012e:	56                   	push   %esi
  80012f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800130:	ba 00 00 00 00       	mov    $0x0,%edx
  800135:	b8 02 00 00 00       	mov    $0x2,%eax
  80013a:	89 d1                	mov    %edx,%ecx
  80013c:	89 d3                	mov    %edx,%ebx
  80013e:	89 d7                	mov    %edx,%edi
  800140:	89 d6                	mov    %edx,%esi
  800142:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800144:	5b                   	pop    %ebx
  800145:	5e                   	pop    %esi
  800146:	5f                   	pop    %edi
  800147:	5d                   	pop    %ebp
  800148:	c3                   	ret    

00800149 <sys_yield>:

void
sys_yield(void)
{
  800149:	55                   	push   %ebp
  80014a:	89 e5                	mov    %esp,%ebp
  80014c:	57                   	push   %edi
  80014d:	56                   	push   %esi
  80014e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80014f:	ba 00 00 00 00       	mov    $0x0,%edx
  800154:	b8 0a 00 00 00       	mov    $0xa,%eax
  800159:	89 d1                	mov    %edx,%ecx
  80015b:	89 d3                	mov    %edx,%ebx
  80015d:	89 d7                	mov    %edx,%edi
  80015f:	89 d6                	mov    %edx,%esi
  800161:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800163:	5b                   	pop    %ebx
  800164:	5e                   	pop    %esi
  800165:	5f                   	pop    %edi
  800166:	5d                   	pop    %ebp
  800167:	c3                   	ret    

00800168 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800168:	55                   	push   %ebp
  800169:	89 e5                	mov    %esp,%ebp
  80016b:	57                   	push   %edi
  80016c:	56                   	push   %esi
  80016d:	53                   	push   %ebx
  80016e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800171:	be 00 00 00 00       	mov    $0x0,%esi
  800176:	b8 04 00 00 00       	mov    $0x4,%eax
  80017b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80017e:	8b 55 08             	mov    0x8(%ebp),%edx
  800181:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800184:	89 f7                	mov    %esi,%edi
  800186:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800188:	85 c0                	test   %eax,%eax
  80018a:	7e 17                	jle    8001a3 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  80018c:	83 ec 0c             	sub    $0xc,%esp
  80018f:	50                   	push   %eax
  800190:	6a 04                	push   $0x4
  800192:	68 2a 10 80 00       	push   $0x80102a
  800197:	6a 23                	push   $0x23
  800199:	68 47 10 80 00       	push   $0x801047
  80019e:	e8 7f 01 00 00       	call   800322 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  8001a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001a6:	5b                   	pop    %ebx
  8001a7:	5e                   	pop    %esi
  8001a8:	5f                   	pop    %edi
  8001a9:	5d                   	pop    %ebp
  8001aa:	c3                   	ret    

008001ab <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001ab:	55                   	push   %ebp
  8001ac:	89 e5                	mov    %esp,%ebp
  8001ae:	57                   	push   %edi
  8001af:	56                   	push   %esi
  8001b0:	53                   	push   %ebx
  8001b1:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001b4:	b8 05 00 00 00       	mov    $0x5,%eax
  8001b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001bc:	8b 55 08             	mov    0x8(%ebp),%edx
  8001bf:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001c2:	8b 7d 14             	mov    0x14(%ebp),%edi
  8001c5:	8b 75 18             	mov    0x18(%ebp),%esi
  8001c8:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8001ca:	85 c0                	test   %eax,%eax
  8001cc:	7e 17                	jle    8001e5 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8001ce:	83 ec 0c             	sub    $0xc,%esp
  8001d1:	50                   	push   %eax
  8001d2:	6a 05                	push   $0x5
  8001d4:	68 2a 10 80 00       	push   $0x80102a
  8001d9:	6a 23                	push   $0x23
  8001db:	68 47 10 80 00       	push   $0x801047
  8001e0:	e8 3d 01 00 00       	call   800322 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  8001e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001e8:	5b                   	pop    %ebx
  8001e9:	5e                   	pop    %esi
  8001ea:	5f                   	pop    %edi
  8001eb:	5d                   	pop    %ebp
  8001ec:	c3                   	ret    

008001ed <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001ed:	55                   	push   %ebp
  8001ee:	89 e5                	mov    %esp,%ebp
  8001f0:	57                   	push   %edi
  8001f1:	56                   	push   %esi
  8001f2:	53                   	push   %ebx
  8001f3:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001f6:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001fb:	b8 06 00 00 00       	mov    $0x6,%eax
  800200:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800203:	8b 55 08             	mov    0x8(%ebp),%edx
  800206:	89 df                	mov    %ebx,%edi
  800208:	89 de                	mov    %ebx,%esi
  80020a:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  80020c:	85 c0                	test   %eax,%eax
  80020e:	7e 17                	jle    800227 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800210:	83 ec 0c             	sub    $0xc,%esp
  800213:	50                   	push   %eax
  800214:	6a 06                	push   $0x6
  800216:	68 2a 10 80 00       	push   $0x80102a
  80021b:	6a 23                	push   $0x23
  80021d:	68 47 10 80 00       	push   $0x801047
  800222:	e8 fb 00 00 00       	call   800322 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800227:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80022a:	5b                   	pop    %ebx
  80022b:	5e                   	pop    %esi
  80022c:	5f                   	pop    %edi
  80022d:	5d                   	pop    %ebp
  80022e:	c3                   	ret    

0080022f <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  80022f:	55                   	push   %ebp
  800230:	89 e5                	mov    %esp,%ebp
  800232:	57                   	push   %edi
  800233:	56                   	push   %esi
  800234:	53                   	push   %ebx
  800235:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800238:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023d:	b8 08 00 00 00       	mov    $0x8,%eax
  800242:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800245:	8b 55 08             	mov    0x8(%ebp),%edx
  800248:	89 df                	mov    %ebx,%edi
  80024a:	89 de                	mov    %ebx,%esi
  80024c:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  80024e:	85 c0                	test   %eax,%eax
  800250:	7e 17                	jle    800269 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800252:	83 ec 0c             	sub    $0xc,%esp
  800255:	50                   	push   %eax
  800256:	6a 08                	push   $0x8
  800258:	68 2a 10 80 00       	push   $0x80102a
  80025d:	6a 23                	push   $0x23
  80025f:	68 47 10 80 00       	push   $0x801047
  800264:	e8 b9 00 00 00       	call   800322 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800269:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80026c:	5b                   	pop    %ebx
  80026d:	5e                   	pop    %esi
  80026e:	5f                   	pop    %edi
  80026f:	5d                   	pop    %ebp
  800270:	c3                   	ret    

00800271 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800271:	55                   	push   %ebp
  800272:	89 e5                	mov    %esp,%ebp
  800274:	57                   	push   %edi
  800275:	56                   	push   %esi
  800276:	53                   	push   %ebx
  800277:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80027a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80027f:	b8 09 00 00 00       	mov    $0x9,%eax
  800284:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800287:	8b 55 08             	mov    0x8(%ebp),%edx
  80028a:	89 df                	mov    %ebx,%edi
  80028c:	89 de                	mov    %ebx,%esi
  80028e:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800290:	85 c0                	test   %eax,%eax
  800292:	7e 17                	jle    8002ab <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800294:	83 ec 0c             	sub    $0xc,%esp
  800297:	50                   	push   %eax
  800298:	6a 09                	push   $0x9
  80029a:	68 2a 10 80 00       	push   $0x80102a
  80029f:	6a 23                	push   $0x23
  8002a1:	68 47 10 80 00       	push   $0x801047
  8002a6:	e8 77 00 00 00       	call   800322 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  8002ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002ae:	5b                   	pop    %ebx
  8002af:	5e                   	pop    %esi
  8002b0:	5f                   	pop    %edi
  8002b1:	5d                   	pop    %ebp
  8002b2:	c3                   	ret    

008002b3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  8002b3:	55                   	push   %ebp
  8002b4:	89 e5                	mov    %esp,%ebp
  8002b6:	57                   	push   %edi
  8002b7:	56                   	push   %esi
  8002b8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002b9:	be 00 00 00 00       	mov    $0x0,%esi
  8002be:	b8 0b 00 00 00       	mov    $0xb,%eax
  8002c3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002c6:	8b 55 08             	mov    0x8(%ebp),%edx
  8002c9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002cc:	8b 7d 14             	mov    0x14(%ebp),%edi
  8002cf:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8002d1:	5b                   	pop    %ebx
  8002d2:	5e                   	pop    %esi
  8002d3:	5f                   	pop    %edi
  8002d4:	5d                   	pop    %ebp
  8002d5:	c3                   	ret    

008002d6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  8002d6:	55                   	push   %ebp
  8002d7:	89 e5                	mov    %esp,%ebp
  8002d9:	57                   	push   %edi
  8002da:	56                   	push   %esi
  8002db:	53                   	push   %ebx
  8002dc:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002df:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002e4:	b8 0c 00 00 00       	mov    $0xc,%eax
  8002e9:	8b 55 08             	mov    0x8(%ebp),%edx
  8002ec:	89 cb                	mov    %ecx,%ebx
  8002ee:	89 cf                	mov    %ecx,%edi
  8002f0:	89 ce                	mov    %ecx,%esi
  8002f2:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8002f4:	85 c0                	test   %eax,%eax
  8002f6:	7e 17                	jle    80030f <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002f8:	83 ec 0c             	sub    $0xc,%esp
  8002fb:	50                   	push   %eax
  8002fc:	6a 0c                	push   $0xc
  8002fe:	68 2a 10 80 00       	push   $0x80102a
  800303:	6a 23                	push   $0x23
  800305:	68 47 10 80 00       	push   $0x801047
  80030a:	e8 13 00 00 00       	call   800322 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  80030f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800312:	5b                   	pop    %ebx
  800313:	5e                   	pop    %esi
  800314:	5f                   	pop    %edi
  800315:	5d                   	pop    %ebp
  800316:	c3                   	ret    

00800317 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  800317:	54                   	push   %esp
	movl _pgfault_handler, %eax
  800318:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  80031d:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  80031f:	83 c4 04             	add    $0x4,%esp

00800322 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800322:	55                   	push   %ebp
  800323:	89 e5                	mov    %esp,%ebp
  800325:	56                   	push   %esi
  800326:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800327:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80032a:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800330:	e8 f5 fd ff ff       	call   80012a <sys_getenvid>
  800335:	83 ec 0c             	sub    $0xc,%esp
  800338:	ff 75 0c             	pushl  0xc(%ebp)
  80033b:	ff 75 08             	pushl  0x8(%ebp)
  80033e:	56                   	push   %esi
  80033f:	50                   	push   %eax
  800340:	68 58 10 80 00       	push   $0x801058
  800345:	e8 b1 00 00 00       	call   8003fb <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80034a:	83 c4 18             	add    $0x18,%esp
  80034d:	53                   	push   %ebx
  80034e:	ff 75 10             	pushl  0x10(%ebp)
  800351:	e8 54 00 00 00       	call   8003aa <vcprintf>
	cprintf("\n");
  800356:	c7 04 24 7b 10 80 00 	movl   $0x80107b,(%esp)
  80035d:	e8 99 00 00 00       	call   8003fb <cprintf>
  800362:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800365:	cc                   	int3   
  800366:	eb fd                	jmp    800365 <_panic+0x43>

00800368 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800368:	55                   	push   %ebp
  800369:	89 e5                	mov    %esp,%ebp
  80036b:	53                   	push   %ebx
  80036c:	83 ec 04             	sub    $0x4,%esp
  80036f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800372:	8b 13                	mov    (%ebx),%edx
  800374:	8d 42 01             	lea    0x1(%edx),%eax
  800377:	89 03                	mov    %eax,(%ebx)
  800379:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80037c:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800380:	3d ff 00 00 00       	cmp    $0xff,%eax
  800385:	75 1a                	jne    8003a1 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800387:	83 ec 08             	sub    $0x8,%esp
  80038a:	68 ff 00 00 00       	push   $0xff
  80038f:	8d 43 08             	lea    0x8(%ebx),%eax
  800392:	50                   	push   %eax
  800393:	e8 14 fd ff ff       	call   8000ac <sys_cputs>
		b->idx = 0;
  800398:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80039e:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8003a1:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8003a5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8003a8:	c9                   	leave  
  8003a9:	c3                   	ret    

008003aa <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8003aa:	55                   	push   %ebp
  8003ab:	89 e5                	mov    %esp,%ebp
  8003ad:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8003b3:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8003ba:	00 00 00 
	b.cnt = 0;
  8003bd:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8003c4:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8003c7:	ff 75 0c             	pushl  0xc(%ebp)
  8003ca:	ff 75 08             	pushl  0x8(%ebp)
  8003cd:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8003d3:	50                   	push   %eax
  8003d4:	68 68 03 80 00       	push   $0x800368
  8003d9:	e8 1a 01 00 00       	call   8004f8 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8003de:	83 c4 08             	add    $0x8,%esp
  8003e1:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8003e7:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8003ed:	50                   	push   %eax
  8003ee:	e8 b9 fc ff ff       	call   8000ac <sys_cputs>

	return b.cnt;
}
  8003f3:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8003f9:	c9                   	leave  
  8003fa:	c3                   	ret    

008003fb <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8003fb:	55                   	push   %ebp
  8003fc:	89 e5                	mov    %esp,%ebp
  8003fe:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800401:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800404:	50                   	push   %eax
  800405:	ff 75 08             	pushl  0x8(%ebp)
  800408:	e8 9d ff ff ff       	call   8003aa <vcprintf>
	va_end(ap);

	return cnt;
}
  80040d:	c9                   	leave  
  80040e:	c3                   	ret    

0080040f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80040f:	55                   	push   %ebp
  800410:	89 e5                	mov    %esp,%ebp
  800412:	57                   	push   %edi
  800413:	56                   	push   %esi
  800414:	53                   	push   %ebx
  800415:	83 ec 1c             	sub    $0x1c,%esp
  800418:	89 c7                	mov    %eax,%edi
  80041a:	89 d6                	mov    %edx,%esi
  80041c:	8b 45 08             	mov    0x8(%ebp),%eax
  80041f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800422:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800425:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800428:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80042b:	bb 00 00 00 00       	mov    $0x0,%ebx
  800430:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800433:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800436:	39 d3                	cmp    %edx,%ebx
  800438:	72 05                	jb     80043f <printnum+0x30>
  80043a:	39 45 10             	cmp    %eax,0x10(%ebp)
  80043d:	77 45                	ja     800484 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80043f:	83 ec 0c             	sub    $0xc,%esp
  800442:	ff 75 18             	pushl  0x18(%ebp)
  800445:	8b 45 14             	mov    0x14(%ebp),%eax
  800448:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80044b:	53                   	push   %ebx
  80044c:	ff 75 10             	pushl  0x10(%ebp)
  80044f:	83 ec 08             	sub    $0x8,%esp
  800452:	ff 75 e4             	pushl  -0x1c(%ebp)
  800455:	ff 75 e0             	pushl  -0x20(%ebp)
  800458:	ff 75 dc             	pushl  -0x24(%ebp)
  80045b:	ff 75 d8             	pushl  -0x28(%ebp)
  80045e:	e8 1d 09 00 00       	call   800d80 <__udivdi3>
  800463:	83 c4 18             	add    $0x18,%esp
  800466:	52                   	push   %edx
  800467:	50                   	push   %eax
  800468:	89 f2                	mov    %esi,%edx
  80046a:	89 f8                	mov    %edi,%eax
  80046c:	e8 9e ff ff ff       	call   80040f <printnum>
  800471:	83 c4 20             	add    $0x20,%esp
  800474:	eb 18                	jmp    80048e <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800476:	83 ec 08             	sub    $0x8,%esp
  800479:	56                   	push   %esi
  80047a:	ff 75 18             	pushl  0x18(%ebp)
  80047d:	ff d7                	call   *%edi
  80047f:	83 c4 10             	add    $0x10,%esp
  800482:	eb 03                	jmp    800487 <printnum+0x78>
  800484:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800487:	83 eb 01             	sub    $0x1,%ebx
  80048a:	85 db                	test   %ebx,%ebx
  80048c:	7f e8                	jg     800476 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80048e:	83 ec 08             	sub    $0x8,%esp
  800491:	56                   	push   %esi
  800492:	83 ec 04             	sub    $0x4,%esp
  800495:	ff 75 e4             	pushl  -0x1c(%ebp)
  800498:	ff 75 e0             	pushl  -0x20(%ebp)
  80049b:	ff 75 dc             	pushl  -0x24(%ebp)
  80049e:	ff 75 d8             	pushl  -0x28(%ebp)
  8004a1:	e8 0a 0a 00 00       	call   800eb0 <__umoddi3>
  8004a6:	83 c4 14             	add    $0x14,%esp
  8004a9:	0f be 80 7d 10 80 00 	movsbl 0x80107d(%eax),%eax
  8004b0:	50                   	push   %eax
  8004b1:	ff d7                	call   *%edi
}
  8004b3:	83 c4 10             	add    $0x10,%esp
  8004b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8004b9:	5b                   	pop    %ebx
  8004ba:	5e                   	pop    %esi
  8004bb:	5f                   	pop    %edi
  8004bc:	5d                   	pop    %ebp
  8004bd:	c3                   	ret    

008004be <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8004be:	55                   	push   %ebp
  8004bf:	89 e5                	mov    %esp,%ebp
  8004c1:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004c4:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004c8:	8b 10                	mov    (%eax),%edx
  8004ca:	3b 50 04             	cmp    0x4(%eax),%edx
  8004cd:	73 0a                	jae    8004d9 <sprintputch+0x1b>
		*b->buf++ = ch;
  8004cf:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004d2:	89 08                	mov    %ecx,(%eax)
  8004d4:	8b 45 08             	mov    0x8(%ebp),%eax
  8004d7:	88 02                	mov    %al,(%edx)
}
  8004d9:	5d                   	pop    %ebp
  8004da:	c3                   	ret    

008004db <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004db:	55                   	push   %ebp
  8004dc:	89 e5                	mov    %esp,%ebp
  8004de:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8004e1:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8004e4:	50                   	push   %eax
  8004e5:	ff 75 10             	pushl  0x10(%ebp)
  8004e8:	ff 75 0c             	pushl  0xc(%ebp)
  8004eb:	ff 75 08             	pushl  0x8(%ebp)
  8004ee:	e8 05 00 00 00       	call   8004f8 <vprintfmt>
	va_end(ap);
}
  8004f3:	83 c4 10             	add    $0x10,%esp
  8004f6:	c9                   	leave  
  8004f7:	c3                   	ret    

008004f8 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8004f8:	55                   	push   %ebp
  8004f9:	89 e5                	mov    %esp,%ebp
  8004fb:	57                   	push   %edi
  8004fc:	56                   	push   %esi
  8004fd:	53                   	push   %ebx
  8004fe:	83 ec 2c             	sub    $0x2c,%esp
  800501:	8b 75 08             	mov    0x8(%ebp),%esi
  800504:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800507:	8b 7d 10             	mov    0x10(%ebp),%edi
  80050a:	eb 12                	jmp    80051e <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80050c:	85 c0                	test   %eax,%eax
  80050e:	0f 84 42 04 00 00    	je     800956 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800514:	83 ec 08             	sub    $0x8,%esp
  800517:	53                   	push   %ebx
  800518:	50                   	push   %eax
  800519:	ff d6                	call   *%esi
  80051b:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80051e:	83 c7 01             	add    $0x1,%edi
  800521:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800525:	83 f8 25             	cmp    $0x25,%eax
  800528:	75 e2                	jne    80050c <vprintfmt+0x14>
  80052a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80052e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800535:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80053c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800543:	b9 00 00 00 00       	mov    $0x0,%ecx
  800548:	eb 07                	jmp    800551 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80054a:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80054d:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800551:	8d 47 01             	lea    0x1(%edi),%eax
  800554:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800557:	0f b6 07             	movzbl (%edi),%eax
  80055a:	0f b6 d0             	movzbl %al,%edx
  80055d:	83 e8 23             	sub    $0x23,%eax
  800560:	3c 55                	cmp    $0x55,%al
  800562:	0f 87 d3 03 00 00    	ja     80093b <vprintfmt+0x443>
  800568:	0f b6 c0             	movzbl %al,%eax
  80056b:	ff 24 85 40 11 80 00 	jmp    *0x801140(,%eax,4)
  800572:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800575:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800579:	eb d6                	jmp    800551 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80057b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80057e:	b8 00 00 00 00       	mov    $0x0,%eax
  800583:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800586:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800589:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80058d:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800590:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800593:	83 f9 09             	cmp    $0x9,%ecx
  800596:	77 3f                	ja     8005d7 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800598:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80059b:	eb e9                	jmp    800586 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80059d:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a0:	8b 00                	mov    (%eax),%eax
  8005a2:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005a5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a8:	8d 40 04             	lea    0x4(%eax),%eax
  8005ab:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8005b1:	eb 2a                	jmp    8005dd <vprintfmt+0xe5>
  8005b3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005b6:	85 c0                	test   %eax,%eax
  8005b8:	ba 00 00 00 00       	mov    $0x0,%edx
  8005bd:	0f 49 d0             	cmovns %eax,%edx
  8005c0:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005c6:	eb 89                	jmp    800551 <vprintfmt+0x59>
  8005c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005cb:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8005d2:	e9 7a ff ff ff       	jmp    800551 <vprintfmt+0x59>
  8005d7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8005da:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8005dd:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005e1:	0f 89 6a ff ff ff    	jns    800551 <vprintfmt+0x59>
				width = precision, precision = -1;
  8005e7:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005ea:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005ed:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8005f4:	e9 58 ff ff ff       	jmp    800551 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8005f9:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005fc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8005ff:	e9 4d ff ff ff       	jmp    800551 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800604:	8b 45 14             	mov    0x14(%ebp),%eax
  800607:	8d 78 04             	lea    0x4(%eax),%edi
  80060a:	83 ec 08             	sub    $0x8,%esp
  80060d:	53                   	push   %ebx
  80060e:	ff 30                	pushl  (%eax)
  800610:	ff d6                	call   *%esi
			break;
  800612:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800615:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800618:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80061b:	e9 fe fe ff ff       	jmp    80051e <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800620:	8b 45 14             	mov    0x14(%ebp),%eax
  800623:	8d 78 04             	lea    0x4(%eax),%edi
  800626:	8b 00                	mov    (%eax),%eax
  800628:	99                   	cltd   
  800629:	31 d0                	xor    %edx,%eax
  80062b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80062d:	83 f8 08             	cmp    $0x8,%eax
  800630:	7f 0b                	jg     80063d <vprintfmt+0x145>
  800632:	8b 14 85 a0 12 80 00 	mov    0x8012a0(,%eax,4),%edx
  800639:	85 d2                	test   %edx,%edx
  80063b:	75 1b                	jne    800658 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80063d:	50                   	push   %eax
  80063e:	68 95 10 80 00       	push   $0x801095
  800643:	53                   	push   %ebx
  800644:	56                   	push   %esi
  800645:	e8 91 fe ff ff       	call   8004db <printfmt>
  80064a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80064d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800650:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800653:	e9 c6 fe ff ff       	jmp    80051e <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800658:	52                   	push   %edx
  800659:	68 9e 10 80 00       	push   $0x80109e
  80065e:	53                   	push   %ebx
  80065f:	56                   	push   %esi
  800660:	e8 76 fe ff ff       	call   8004db <printfmt>
  800665:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800668:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80066b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80066e:	e9 ab fe ff ff       	jmp    80051e <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800673:	8b 45 14             	mov    0x14(%ebp),%eax
  800676:	83 c0 04             	add    $0x4,%eax
  800679:	89 45 cc             	mov    %eax,-0x34(%ebp)
  80067c:	8b 45 14             	mov    0x14(%ebp),%eax
  80067f:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800681:	85 ff                	test   %edi,%edi
  800683:	b8 8e 10 80 00       	mov    $0x80108e,%eax
  800688:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80068b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80068f:	0f 8e 94 00 00 00    	jle    800729 <vprintfmt+0x231>
  800695:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800699:	0f 84 98 00 00 00    	je     800737 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  80069f:	83 ec 08             	sub    $0x8,%esp
  8006a2:	ff 75 d0             	pushl  -0x30(%ebp)
  8006a5:	57                   	push   %edi
  8006a6:	e8 33 03 00 00       	call   8009de <strnlen>
  8006ab:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8006ae:	29 c1                	sub    %eax,%ecx
  8006b0:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8006b3:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8006b6:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8006ba:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8006bd:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8006c0:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006c2:	eb 0f                	jmp    8006d3 <vprintfmt+0x1db>
					putch(padc, putdat);
  8006c4:	83 ec 08             	sub    $0x8,%esp
  8006c7:	53                   	push   %ebx
  8006c8:	ff 75 e0             	pushl  -0x20(%ebp)
  8006cb:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006cd:	83 ef 01             	sub    $0x1,%edi
  8006d0:	83 c4 10             	add    $0x10,%esp
  8006d3:	85 ff                	test   %edi,%edi
  8006d5:	7f ed                	jg     8006c4 <vprintfmt+0x1cc>
  8006d7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006da:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8006dd:	85 c9                	test   %ecx,%ecx
  8006df:	b8 00 00 00 00       	mov    $0x0,%eax
  8006e4:	0f 49 c1             	cmovns %ecx,%eax
  8006e7:	29 c1                	sub    %eax,%ecx
  8006e9:	89 75 08             	mov    %esi,0x8(%ebp)
  8006ec:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8006ef:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8006f2:	89 cb                	mov    %ecx,%ebx
  8006f4:	eb 4d                	jmp    800743 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8006f6:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006fa:	74 1b                	je     800717 <vprintfmt+0x21f>
  8006fc:	0f be c0             	movsbl %al,%eax
  8006ff:	83 e8 20             	sub    $0x20,%eax
  800702:	83 f8 5e             	cmp    $0x5e,%eax
  800705:	76 10                	jbe    800717 <vprintfmt+0x21f>
					putch('?', putdat);
  800707:	83 ec 08             	sub    $0x8,%esp
  80070a:	ff 75 0c             	pushl  0xc(%ebp)
  80070d:	6a 3f                	push   $0x3f
  80070f:	ff 55 08             	call   *0x8(%ebp)
  800712:	83 c4 10             	add    $0x10,%esp
  800715:	eb 0d                	jmp    800724 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800717:	83 ec 08             	sub    $0x8,%esp
  80071a:	ff 75 0c             	pushl  0xc(%ebp)
  80071d:	52                   	push   %edx
  80071e:	ff 55 08             	call   *0x8(%ebp)
  800721:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800724:	83 eb 01             	sub    $0x1,%ebx
  800727:	eb 1a                	jmp    800743 <vprintfmt+0x24b>
  800729:	89 75 08             	mov    %esi,0x8(%ebp)
  80072c:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80072f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800732:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800735:	eb 0c                	jmp    800743 <vprintfmt+0x24b>
  800737:	89 75 08             	mov    %esi,0x8(%ebp)
  80073a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80073d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800740:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800743:	83 c7 01             	add    $0x1,%edi
  800746:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80074a:	0f be d0             	movsbl %al,%edx
  80074d:	85 d2                	test   %edx,%edx
  80074f:	74 23                	je     800774 <vprintfmt+0x27c>
  800751:	85 f6                	test   %esi,%esi
  800753:	78 a1                	js     8006f6 <vprintfmt+0x1fe>
  800755:	83 ee 01             	sub    $0x1,%esi
  800758:	79 9c                	jns    8006f6 <vprintfmt+0x1fe>
  80075a:	89 df                	mov    %ebx,%edi
  80075c:	8b 75 08             	mov    0x8(%ebp),%esi
  80075f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800762:	eb 18                	jmp    80077c <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800764:	83 ec 08             	sub    $0x8,%esp
  800767:	53                   	push   %ebx
  800768:	6a 20                	push   $0x20
  80076a:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80076c:	83 ef 01             	sub    $0x1,%edi
  80076f:	83 c4 10             	add    $0x10,%esp
  800772:	eb 08                	jmp    80077c <vprintfmt+0x284>
  800774:	89 df                	mov    %ebx,%edi
  800776:	8b 75 08             	mov    0x8(%ebp),%esi
  800779:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80077c:	85 ff                	test   %edi,%edi
  80077e:	7f e4                	jg     800764 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800780:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800783:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800786:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800789:	e9 90 fd ff ff       	jmp    80051e <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80078e:	83 f9 01             	cmp    $0x1,%ecx
  800791:	7e 19                	jle    8007ac <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800793:	8b 45 14             	mov    0x14(%ebp),%eax
  800796:	8b 50 04             	mov    0x4(%eax),%edx
  800799:	8b 00                	mov    (%eax),%eax
  80079b:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80079e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8007a1:	8b 45 14             	mov    0x14(%ebp),%eax
  8007a4:	8d 40 08             	lea    0x8(%eax),%eax
  8007a7:	89 45 14             	mov    %eax,0x14(%ebp)
  8007aa:	eb 38                	jmp    8007e4 <vprintfmt+0x2ec>
	else if (lflag)
  8007ac:	85 c9                	test   %ecx,%ecx
  8007ae:	74 1b                	je     8007cb <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8007b0:	8b 45 14             	mov    0x14(%ebp),%eax
  8007b3:	8b 00                	mov    (%eax),%eax
  8007b5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007b8:	89 c1                	mov    %eax,%ecx
  8007ba:	c1 f9 1f             	sar    $0x1f,%ecx
  8007bd:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8007c0:	8b 45 14             	mov    0x14(%ebp),%eax
  8007c3:	8d 40 04             	lea    0x4(%eax),%eax
  8007c6:	89 45 14             	mov    %eax,0x14(%ebp)
  8007c9:	eb 19                	jmp    8007e4 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8007cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8007ce:	8b 00                	mov    (%eax),%eax
  8007d0:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007d3:	89 c1                	mov    %eax,%ecx
  8007d5:	c1 f9 1f             	sar    $0x1f,%ecx
  8007d8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8007db:	8b 45 14             	mov    0x14(%ebp),%eax
  8007de:	8d 40 04             	lea    0x4(%eax),%eax
  8007e1:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8007e4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8007e7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8007ea:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8007ef:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8007f3:	0f 89 0e 01 00 00    	jns    800907 <vprintfmt+0x40f>
				putch('-', putdat);
  8007f9:	83 ec 08             	sub    $0x8,%esp
  8007fc:	53                   	push   %ebx
  8007fd:	6a 2d                	push   $0x2d
  8007ff:	ff d6                	call   *%esi
				num = -(long long) num;
  800801:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800804:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800807:	f7 da                	neg    %edx
  800809:	83 d1 00             	adc    $0x0,%ecx
  80080c:	f7 d9                	neg    %ecx
  80080e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800811:	b8 0a 00 00 00       	mov    $0xa,%eax
  800816:	e9 ec 00 00 00       	jmp    800907 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80081b:	83 f9 01             	cmp    $0x1,%ecx
  80081e:	7e 18                	jle    800838 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800820:	8b 45 14             	mov    0x14(%ebp),%eax
  800823:	8b 10                	mov    (%eax),%edx
  800825:	8b 48 04             	mov    0x4(%eax),%ecx
  800828:	8d 40 08             	lea    0x8(%eax),%eax
  80082b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80082e:	b8 0a 00 00 00       	mov    $0xa,%eax
  800833:	e9 cf 00 00 00       	jmp    800907 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800838:	85 c9                	test   %ecx,%ecx
  80083a:	74 1a                	je     800856 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80083c:	8b 45 14             	mov    0x14(%ebp),%eax
  80083f:	8b 10                	mov    (%eax),%edx
  800841:	b9 00 00 00 00       	mov    $0x0,%ecx
  800846:	8d 40 04             	lea    0x4(%eax),%eax
  800849:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80084c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800851:	e9 b1 00 00 00       	jmp    800907 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800856:	8b 45 14             	mov    0x14(%ebp),%eax
  800859:	8b 10                	mov    (%eax),%edx
  80085b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800860:	8d 40 04             	lea    0x4(%eax),%eax
  800863:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800866:	b8 0a 00 00 00       	mov    $0xa,%eax
  80086b:	e9 97 00 00 00       	jmp    800907 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800870:	83 ec 08             	sub    $0x8,%esp
  800873:	53                   	push   %ebx
  800874:	6a 58                	push   $0x58
  800876:	ff d6                	call   *%esi
			putch('X', putdat);
  800878:	83 c4 08             	add    $0x8,%esp
  80087b:	53                   	push   %ebx
  80087c:	6a 58                	push   $0x58
  80087e:	ff d6                	call   *%esi
			putch('X', putdat);
  800880:	83 c4 08             	add    $0x8,%esp
  800883:	53                   	push   %ebx
  800884:	6a 58                	push   $0x58
  800886:	ff d6                	call   *%esi
			break;
  800888:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80088b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  80088e:	e9 8b fc ff ff       	jmp    80051e <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800893:	83 ec 08             	sub    $0x8,%esp
  800896:	53                   	push   %ebx
  800897:	6a 30                	push   $0x30
  800899:	ff d6                	call   *%esi
			putch('x', putdat);
  80089b:	83 c4 08             	add    $0x8,%esp
  80089e:	53                   	push   %ebx
  80089f:	6a 78                	push   $0x78
  8008a1:	ff d6                	call   *%esi
			num = (unsigned long long)
  8008a3:	8b 45 14             	mov    0x14(%ebp),%eax
  8008a6:	8b 10                	mov    (%eax),%edx
  8008a8:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8008ad:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8008b0:	8d 40 04             	lea    0x4(%eax),%eax
  8008b3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8008b6:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8008bb:	eb 4a                	jmp    800907 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8008bd:	83 f9 01             	cmp    $0x1,%ecx
  8008c0:	7e 15                	jle    8008d7 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8008c2:	8b 45 14             	mov    0x14(%ebp),%eax
  8008c5:	8b 10                	mov    (%eax),%edx
  8008c7:	8b 48 04             	mov    0x4(%eax),%ecx
  8008ca:	8d 40 08             	lea    0x8(%eax),%eax
  8008cd:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8008d0:	b8 10 00 00 00       	mov    $0x10,%eax
  8008d5:	eb 30                	jmp    800907 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8008d7:	85 c9                	test   %ecx,%ecx
  8008d9:	74 17                	je     8008f2 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8008db:	8b 45 14             	mov    0x14(%ebp),%eax
  8008de:	8b 10                	mov    (%eax),%edx
  8008e0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8008e5:	8d 40 04             	lea    0x4(%eax),%eax
  8008e8:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8008eb:	b8 10 00 00 00       	mov    $0x10,%eax
  8008f0:	eb 15                	jmp    800907 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8008f2:	8b 45 14             	mov    0x14(%ebp),%eax
  8008f5:	8b 10                	mov    (%eax),%edx
  8008f7:	b9 00 00 00 00       	mov    $0x0,%ecx
  8008fc:	8d 40 04             	lea    0x4(%eax),%eax
  8008ff:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800902:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800907:	83 ec 0c             	sub    $0xc,%esp
  80090a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80090e:	57                   	push   %edi
  80090f:	ff 75 e0             	pushl  -0x20(%ebp)
  800912:	50                   	push   %eax
  800913:	51                   	push   %ecx
  800914:	52                   	push   %edx
  800915:	89 da                	mov    %ebx,%edx
  800917:	89 f0                	mov    %esi,%eax
  800919:	e8 f1 fa ff ff       	call   80040f <printnum>
			break;
  80091e:	83 c4 20             	add    $0x20,%esp
  800921:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800924:	e9 f5 fb ff ff       	jmp    80051e <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800929:	83 ec 08             	sub    $0x8,%esp
  80092c:	53                   	push   %ebx
  80092d:	52                   	push   %edx
  80092e:	ff d6                	call   *%esi
			break;
  800930:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800933:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800936:	e9 e3 fb ff ff       	jmp    80051e <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80093b:	83 ec 08             	sub    $0x8,%esp
  80093e:	53                   	push   %ebx
  80093f:	6a 25                	push   $0x25
  800941:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800943:	83 c4 10             	add    $0x10,%esp
  800946:	eb 03                	jmp    80094b <vprintfmt+0x453>
  800948:	83 ef 01             	sub    $0x1,%edi
  80094b:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80094f:	75 f7                	jne    800948 <vprintfmt+0x450>
  800951:	e9 c8 fb ff ff       	jmp    80051e <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800956:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800959:	5b                   	pop    %ebx
  80095a:	5e                   	pop    %esi
  80095b:	5f                   	pop    %edi
  80095c:	5d                   	pop    %ebp
  80095d:	c3                   	ret    

0080095e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80095e:	55                   	push   %ebp
  80095f:	89 e5                	mov    %esp,%ebp
  800961:	83 ec 18             	sub    $0x18,%esp
  800964:	8b 45 08             	mov    0x8(%ebp),%eax
  800967:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80096a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80096d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800971:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800974:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80097b:	85 c0                	test   %eax,%eax
  80097d:	74 26                	je     8009a5 <vsnprintf+0x47>
  80097f:	85 d2                	test   %edx,%edx
  800981:	7e 22                	jle    8009a5 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800983:	ff 75 14             	pushl  0x14(%ebp)
  800986:	ff 75 10             	pushl  0x10(%ebp)
  800989:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80098c:	50                   	push   %eax
  80098d:	68 be 04 80 00       	push   $0x8004be
  800992:	e8 61 fb ff ff       	call   8004f8 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800997:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80099a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80099d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8009a0:	83 c4 10             	add    $0x10,%esp
  8009a3:	eb 05                	jmp    8009aa <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8009a5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8009aa:	c9                   	leave  
  8009ab:	c3                   	ret    

008009ac <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8009ac:	55                   	push   %ebp
  8009ad:	89 e5                	mov    %esp,%ebp
  8009af:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8009b2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8009b5:	50                   	push   %eax
  8009b6:	ff 75 10             	pushl  0x10(%ebp)
  8009b9:	ff 75 0c             	pushl  0xc(%ebp)
  8009bc:	ff 75 08             	pushl  0x8(%ebp)
  8009bf:	e8 9a ff ff ff       	call   80095e <vsnprintf>
	va_end(ap);

	return rc;
}
  8009c4:	c9                   	leave  
  8009c5:	c3                   	ret    

008009c6 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8009c6:	55                   	push   %ebp
  8009c7:	89 e5                	mov    %esp,%ebp
  8009c9:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8009cc:	b8 00 00 00 00       	mov    $0x0,%eax
  8009d1:	eb 03                	jmp    8009d6 <strlen+0x10>
		n++;
  8009d3:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8009d6:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8009da:	75 f7                	jne    8009d3 <strlen+0xd>
		n++;
	return n;
}
  8009dc:	5d                   	pop    %ebp
  8009dd:	c3                   	ret    

008009de <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8009de:	55                   	push   %ebp
  8009df:	89 e5                	mov    %esp,%ebp
  8009e1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009e4:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8009e7:	ba 00 00 00 00       	mov    $0x0,%edx
  8009ec:	eb 03                	jmp    8009f1 <strnlen+0x13>
		n++;
  8009ee:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8009f1:	39 c2                	cmp    %eax,%edx
  8009f3:	74 08                	je     8009fd <strnlen+0x1f>
  8009f5:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8009f9:	75 f3                	jne    8009ee <strnlen+0x10>
  8009fb:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8009fd:	5d                   	pop    %ebp
  8009fe:	c3                   	ret    

008009ff <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8009ff:	55                   	push   %ebp
  800a00:	89 e5                	mov    %esp,%ebp
  800a02:	53                   	push   %ebx
  800a03:	8b 45 08             	mov    0x8(%ebp),%eax
  800a06:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800a09:	89 c2                	mov    %eax,%edx
  800a0b:	83 c2 01             	add    $0x1,%edx
  800a0e:	83 c1 01             	add    $0x1,%ecx
  800a11:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800a15:	88 5a ff             	mov    %bl,-0x1(%edx)
  800a18:	84 db                	test   %bl,%bl
  800a1a:	75 ef                	jne    800a0b <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800a1c:	5b                   	pop    %ebx
  800a1d:	5d                   	pop    %ebp
  800a1e:	c3                   	ret    

00800a1f <strcat>:

char *
strcat(char *dst, const char *src)
{
  800a1f:	55                   	push   %ebp
  800a20:	89 e5                	mov    %esp,%ebp
  800a22:	53                   	push   %ebx
  800a23:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800a26:	53                   	push   %ebx
  800a27:	e8 9a ff ff ff       	call   8009c6 <strlen>
  800a2c:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800a2f:	ff 75 0c             	pushl  0xc(%ebp)
  800a32:	01 d8                	add    %ebx,%eax
  800a34:	50                   	push   %eax
  800a35:	e8 c5 ff ff ff       	call   8009ff <strcpy>
	return dst;
}
  800a3a:	89 d8                	mov    %ebx,%eax
  800a3c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800a3f:	c9                   	leave  
  800a40:	c3                   	ret    

00800a41 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800a41:	55                   	push   %ebp
  800a42:	89 e5                	mov    %esp,%ebp
  800a44:	56                   	push   %esi
  800a45:	53                   	push   %ebx
  800a46:	8b 75 08             	mov    0x8(%ebp),%esi
  800a49:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a4c:	89 f3                	mov    %esi,%ebx
  800a4e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a51:	89 f2                	mov    %esi,%edx
  800a53:	eb 0f                	jmp    800a64 <strncpy+0x23>
		*dst++ = *src;
  800a55:	83 c2 01             	add    $0x1,%edx
  800a58:	0f b6 01             	movzbl (%ecx),%eax
  800a5b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800a5e:	80 39 01             	cmpb   $0x1,(%ecx)
  800a61:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a64:	39 da                	cmp    %ebx,%edx
  800a66:	75 ed                	jne    800a55 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800a68:	89 f0                	mov    %esi,%eax
  800a6a:	5b                   	pop    %ebx
  800a6b:	5e                   	pop    %esi
  800a6c:	5d                   	pop    %ebp
  800a6d:	c3                   	ret    

00800a6e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800a6e:	55                   	push   %ebp
  800a6f:	89 e5                	mov    %esp,%ebp
  800a71:	56                   	push   %esi
  800a72:	53                   	push   %ebx
  800a73:	8b 75 08             	mov    0x8(%ebp),%esi
  800a76:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a79:	8b 55 10             	mov    0x10(%ebp),%edx
  800a7c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800a7e:	85 d2                	test   %edx,%edx
  800a80:	74 21                	je     800aa3 <strlcpy+0x35>
  800a82:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800a86:	89 f2                	mov    %esi,%edx
  800a88:	eb 09                	jmp    800a93 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800a8a:	83 c2 01             	add    $0x1,%edx
  800a8d:	83 c1 01             	add    $0x1,%ecx
  800a90:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800a93:	39 c2                	cmp    %eax,%edx
  800a95:	74 09                	je     800aa0 <strlcpy+0x32>
  800a97:	0f b6 19             	movzbl (%ecx),%ebx
  800a9a:	84 db                	test   %bl,%bl
  800a9c:	75 ec                	jne    800a8a <strlcpy+0x1c>
  800a9e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800aa0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800aa3:	29 f0                	sub    %esi,%eax
}
  800aa5:	5b                   	pop    %ebx
  800aa6:	5e                   	pop    %esi
  800aa7:	5d                   	pop    %ebp
  800aa8:	c3                   	ret    

00800aa9 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800aa9:	55                   	push   %ebp
  800aaa:	89 e5                	mov    %esp,%ebp
  800aac:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800aaf:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800ab2:	eb 06                	jmp    800aba <strcmp+0x11>
		p++, q++;
  800ab4:	83 c1 01             	add    $0x1,%ecx
  800ab7:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800aba:	0f b6 01             	movzbl (%ecx),%eax
  800abd:	84 c0                	test   %al,%al
  800abf:	74 04                	je     800ac5 <strcmp+0x1c>
  800ac1:	3a 02                	cmp    (%edx),%al
  800ac3:	74 ef                	je     800ab4 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800ac5:	0f b6 c0             	movzbl %al,%eax
  800ac8:	0f b6 12             	movzbl (%edx),%edx
  800acb:	29 d0                	sub    %edx,%eax
}
  800acd:	5d                   	pop    %ebp
  800ace:	c3                   	ret    

00800acf <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800acf:	55                   	push   %ebp
  800ad0:	89 e5                	mov    %esp,%ebp
  800ad2:	53                   	push   %ebx
  800ad3:	8b 45 08             	mov    0x8(%ebp),%eax
  800ad6:	8b 55 0c             	mov    0xc(%ebp),%edx
  800ad9:	89 c3                	mov    %eax,%ebx
  800adb:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800ade:	eb 06                	jmp    800ae6 <strncmp+0x17>
		n--, p++, q++;
  800ae0:	83 c0 01             	add    $0x1,%eax
  800ae3:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800ae6:	39 d8                	cmp    %ebx,%eax
  800ae8:	74 15                	je     800aff <strncmp+0x30>
  800aea:	0f b6 08             	movzbl (%eax),%ecx
  800aed:	84 c9                	test   %cl,%cl
  800aef:	74 04                	je     800af5 <strncmp+0x26>
  800af1:	3a 0a                	cmp    (%edx),%cl
  800af3:	74 eb                	je     800ae0 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800af5:	0f b6 00             	movzbl (%eax),%eax
  800af8:	0f b6 12             	movzbl (%edx),%edx
  800afb:	29 d0                	sub    %edx,%eax
  800afd:	eb 05                	jmp    800b04 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800aff:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800b04:	5b                   	pop    %ebx
  800b05:	5d                   	pop    %ebp
  800b06:	c3                   	ret    

00800b07 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800b07:	55                   	push   %ebp
  800b08:	89 e5                	mov    %esp,%ebp
  800b0a:	8b 45 08             	mov    0x8(%ebp),%eax
  800b0d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b11:	eb 07                	jmp    800b1a <strchr+0x13>
		if (*s == c)
  800b13:	38 ca                	cmp    %cl,%dl
  800b15:	74 0f                	je     800b26 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800b17:	83 c0 01             	add    $0x1,%eax
  800b1a:	0f b6 10             	movzbl (%eax),%edx
  800b1d:	84 d2                	test   %dl,%dl
  800b1f:	75 f2                	jne    800b13 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800b21:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b26:	5d                   	pop    %ebp
  800b27:	c3                   	ret    

00800b28 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800b28:	55                   	push   %ebp
  800b29:	89 e5                	mov    %esp,%ebp
  800b2b:	8b 45 08             	mov    0x8(%ebp),%eax
  800b2e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b32:	eb 03                	jmp    800b37 <strfind+0xf>
  800b34:	83 c0 01             	add    $0x1,%eax
  800b37:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800b3a:	38 ca                	cmp    %cl,%dl
  800b3c:	74 04                	je     800b42 <strfind+0x1a>
  800b3e:	84 d2                	test   %dl,%dl
  800b40:	75 f2                	jne    800b34 <strfind+0xc>
			break;
	return (char *) s;
}
  800b42:	5d                   	pop    %ebp
  800b43:	c3                   	ret    

00800b44 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800b44:	55                   	push   %ebp
  800b45:	89 e5                	mov    %esp,%ebp
  800b47:	57                   	push   %edi
  800b48:	56                   	push   %esi
  800b49:	53                   	push   %ebx
  800b4a:	8b 7d 08             	mov    0x8(%ebp),%edi
  800b4d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800b50:	85 c9                	test   %ecx,%ecx
  800b52:	74 36                	je     800b8a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800b54:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b5a:	75 28                	jne    800b84 <memset+0x40>
  800b5c:	f6 c1 03             	test   $0x3,%cl
  800b5f:	75 23                	jne    800b84 <memset+0x40>
		c &= 0xFF;
  800b61:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b65:	89 d3                	mov    %edx,%ebx
  800b67:	c1 e3 08             	shl    $0x8,%ebx
  800b6a:	89 d6                	mov    %edx,%esi
  800b6c:	c1 e6 18             	shl    $0x18,%esi
  800b6f:	89 d0                	mov    %edx,%eax
  800b71:	c1 e0 10             	shl    $0x10,%eax
  800b74:	09 f0                	or     %esi,%eax
  800b76:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800b78:	89 d8                	mov    %ebx,%eax
  800b7a:	09 d0                	or     %edx,%eax
  800b7c:	c1 e9 02             	shr    $0x2,%ecx
  800b7f:	fc                   	cld    
  800b80:	f3 ab                	rep stos %eax,%es:(%edi)
  800b82:	eb 06                	jmp    800b8a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b84:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b87:	fc                   	cld    
  800b88:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800b8a:	89 f8                	mov    %edi,%eax
  800b8c:	5b                   	pop    %ebx
  800b8d:	5e                   	pop    %esi
  800b8e:	5f                   	pop    %edi
  800b8f:	5d                   	pop    %ebp
  800b90:	c3                   	ret    

00800b91 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b91:	55                   	push   %ebp
  800b92:	89 e5                	mov    %esp,%ebp
  800b94:	57                   	push   %edi
  800b95:	56                   	push   %esi
  800b96:	8b 45 08             	mov    0x8(%ebp),%eax
  800b99:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b9c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b9f:	39 c6                	cmp    %eax,%esi
  800ba1:	73 35                	jae    800bd8 <memmove+0x47>
  800ba3:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800ba6:	39 d0                	cmp    %edx,%eax
  800ba8:	73 2e                	jae    800bd8 <memmove+0x47>
		s += n;
		d += n;
  800baa:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800bad:	89 d6                	mov    %edx,%esi
  800baf:	09 fe                	or     %edi,%esi
  800bb1:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800bb7:	75 13                	jne    800bcc <memmove+0x3b>
  800bb9:	f6 c1 03             	test   $0x3,%cl
  800bbc:	75 0e                	jne    800bcc <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800bbe:	83 ef 04             	sub    $0x4,%edi
  800bc1:	8d 72 fc             	lea    -0x4(%edx),%esi
  800bc4:	c1 e9 02             	shr    $0x2,%ecx
  800bc7:	fd                   	std    
  800bc8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bca:	eb 09                	jmp    800bd5 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800bcc:	83 ef 01             	sub    $0x1,%edi
  800bcf:	8d 72 ff             	lea    -0x1(%edx),%esi
  800bd2:	fd                   	std    
  800bd3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800bd5:	fc                   	cld    
  800bd6:	eb 1d                	jmp    800bf5 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800bd8:	89 f2                	mov    %esi,%edx
  800bda:	09 c2                	or     %eax,%edx
  800bdc:	f6 c2 03             	test   $0x3,%dl
  800bdf:	75 0f                	jne    800bf0 <memmove+0x5f>
  800be1:	f6 c1 03             	test   $0x3,%cl
  800be4:	75 0a                	jne    800bf0 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800be6:	c1 e9 02             	shr    $0x2,%ecx
  800be9:	89 c7                	mov    %eax,%edi
  800beb:	fc                   	cld    
  800bec:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bee:	eb 05                	jmp    800bf5 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800bf0:	89 c7                	mov    %eax,%edi
  800bf2:	fc                   	cld    
  800bf3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800bf5:	5e                   	pop    %esi
  800bf6:	5f                   	pop    %edi
  800bf7:	5d                   	pop    %ebp
  800bf8:	c3                   	ret    

00800bf9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800bf9:	55                   	push   %ebp
  800bfa:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800bfc:	ff 75 10             	pushl  0x10(%ebp)
  800bff:	ff 75 0c             	pushl  0xc(%ebp)
  800c02:	ff 75 08             	pushl  0x8(%ebp)
  800c05:	e8 87 ff ff ff       	call   800b91 <memmove>
}
  800c0a:	c9                   	leave  
  800c0b:	c3                   	ret    

00800c0c <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800c0c:	55                   	push   %ebp
  800c0d:	89 e5                	mov    %esp,%ebp
  800c0f:	56                   	push   %esi
  800c10:	53                   	push   %ebx
  800c11:	8b 45 08             	mov    0x8(%ebp),%eax
  800c14:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c17:	89 c6                	mov    %eax,%esi
  800c19:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c1c:	eb 1a                	jmp    800c38 <memcmp+0x2c>
		if (*s1 != *s2)
  800c1e:	0f b6 08             	movzbl (%eax),%ecx
  800c21:	0f b6 1a             	movzbl (%edx),%ebx
  800c24:	38 d9                	cmp    %bl,%cl
  800c26:	74 0a                	je     800c32 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800c28:	0f b6 c1             	movzbl %cl,%eax
  800c2b:	0f b6 db             	movzbl %bl,%ebx
  800c2e:	29 d8                	sub    %ebx,%eax
  800c30:	eb 0f                	jmp    800c41 <memcmp+0x35>
		s1++, s2++;
  800c32:	83 c0 01             	add    $0x1,%eax
  800c35:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c38:	39 f0                	cmp    %esi,%eax
  800c3a:	75 e2                	jne    800c1e <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c3c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c41:	5b                   	pop    %ebx
  800c42:	5e                   	pop    %esi
  800c43:	5d                   	pop    %ebp
  800c44:	c3                   	ret    

00800c45 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c45:	55                   	push   %ebp
  800c46:	89 e5                	mov    %esp,%ebp
  800c48:	53                   	push   %ebx
  800c49:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800c4c:	89 c1                	mov    %eax,%ecx
  800c4e:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800c51:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c55:	eb 0a                	jmp    800c61 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c57:	0f b6 10             	movzbl (%eax),%edx
  800c5a:	39 da                	cmp    %ebx,%edx
  800c5c:	74 07                	je     800c65 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c5e:	83 c0 01             	add    $0x1,%eax
  800c61:	39 c8                	cmp    %ecx,%eax
  800c63:	72 f2                	jb     800c57 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c65:	5b                   	pop    %ebx
  800c66:	5d                   	pop    %ebp
  800c67:	c3                   	ret    

00800c68 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c68:	55                   	push   %ebp
  800c69:	89 e5                	mov    %esp,%ebp
  800c6b:	57                   	push   %edi
  800c6c:	56                   	push   %esi
  800c6d:	53                   	push   %ebx
  800c6e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c71:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c74:	eb 03                	jmp    800c79 <strtol+0x11>
		s++;
  800c76:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c79:	0f b6 01             	movzbl (%ecx),%eax
  800c7c:	3c 20                	cmp    $0x20,%al
  800c7e:	74 f6                	je     800c76 <strtol+0xe>
  800c80:	3c 09                	cmp    $0x9,%al
  800c82:	74 f2                	je     800c76 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c84:	3c 2b                	cmp    $0x2b,%al
  800c86:	75 0a                	jne    800c92 <strtol+0x2a>
		s++;
  800c88:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800c8b:	bf 00 00 00 00       	mov    $0x0,%edi
  800c90:	eb 11                	jmp    800ca3 <strtol+0x3b>
  800c92:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800c97:	3c 2d                	cmp    $0x2d,%al
  800c99:	75 08                	jne    800ca3 <strtol+0x3b>
		s++, neg = 1;
  800c9b:	83 c1 01             	add    $0x1,%ecx
  800c9e:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ca3:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ca9:	75 15                	jne    800cc0 <strtol+0x58>
  800cab:	80 39 30             	cmpb   $0x30,(%ecx)
  800cae:	75 10                	jne    800cc0 <strtol+0x58>
  800cb0:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800cb4:	75 7c                	jne    800d32 <strtol+0xca>
		s += 2, base = 16;
  800cb6:	83 c1 02             	add    $0x2,%ecx
  800cb9:	bb 10 00 00 00       	mov    $0x10,%ebx
  800cbe:	eb 16                	jmp    800cd6 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800cc0:	85 db                	test   %ebx,%ebx
  800cc2:	75 12                	jne    800cd6 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800cc4:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800cc9:	80 39 30             	cmpb   $0x30,(%ecx)
  800ccc:	75 08                	jne    800cd6 <strtol+0x6e>
		s++, base = 8;
  800cce:	83 c1 01             	add    $0x1,%ecx
  800cd1:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800cd6:	b8 00 00 00 00       	mov    $0x0,%eax
  800cdb:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800cde:	0f b6 11             	movzbl (%ecx),%edx
  800ce1:	8d 72 d0             	lea    -0x30(%edx),%esi
  800ce4:	89 f3                	mov    %esi,%ebx
  800ce6:	80 fb 09             	cmp    $0x9,%bl
  800ce9:	77 08                	ja     800cf3 <strtol+0x8b>
			dig = *s - '0';
  800ceb:	0f be d2             	movsbl %dl,%edx
  800cee:	83 ea 30             	sub    $0x30,%edx
  800cf1:	eb 22                	jmp    800d15 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800cf3:	8d 72 9f             	lea    -0x61(%edx),%esi
  800cf6:	89 f3                	mov    %esi,%ebx
  800cf8:	80 fb 19             	cmp    $0x19,%bl
  800cfb:	77 08                	ja     800d05 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800cfd:	0f be d2             	movsbl %dl,%edx
  800d00:	83 ea 57             	sub    $0x57,%edx
  800d03:	eb 10                	jmp    800d15 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800d05:	8d 72 bf             	lea    -0x41(%edx),%esi
  800d08:	89 f3                	mov    %esi,%ebx
  800d0a:	80 fb 19             	cmp    $0x19,%bl
  800d0d:	77 16                	ja     800d25 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800d0f:	0f be d2             	movsbl %dl,%edx
  800d12:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800d15:	3b 55 10             	cmp    0x10(%ebp),%edx
  800d18:	7d 0b                	jge    800d25 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800d1a:	83 c1 01             	add    $0x1,%ecx
  800d1d:	0f af 45 10          	imul   0x10(%ebp),%eax
  800d21:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800d23:	eb b9                	jmp    800cde <strtol+0x76>

	if (endptr)
  800d25:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d29:	74 0d                	je     800d38 <strtol+0xd0>
		*endptr = (char *) s;
  800d2b:	8b 75 0c             	mov    0xc(%ebp),%esi
  800d2e:	89 0e                	mov    %ecx,(%esi)
  800d30:	eb 06                	jmp    800d38 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800d32:	85 db                	test   %ebx,%ebx
  800d34:	74 98                	je     800cce <strtol+0x66>
  800d36:	eb 9e                	jmp    800cd6 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800d38:	89 c2                	mov    %eax,%edx
  800d3a:	f7 da                	neg    %edx
  800d3c:	85 ff                	test   %edi,%edi
  800d3e:	0f 45 c2             	cmovne %edx,%eax
}
  800d41:	5b                   	pop    %ebx
  800d42:	5e                   	pop    %esi
  800d43:	5f                   	pop    %edi
  800d44:	5d                   	pop    %ebp
  800d45:	c3                   	ret    

00800d46 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  800d46:	55                   	push   %ebp
  800d47:	89 e5                	mov    %esp,%ebp
  800d49:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  800d4c:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  800d53:	75 14                	jne    800d69 <set_pgfault_handler+0x23>
		// First time through!
		// LAB 4: Your code here.
		panic("set_pgfault_handler not implemented");
  800d55:	83 ec 04             	sub    $0x4,%esp
  800d58:	68 c4 12 80 00       	push   $0x8012c4
  800d5d:	6a 20                	push   $0x20
  800d5f:	68 e8 12 80 00       	push   $0x8012e8
  800d64:	e8 b9 f5 ff ff       	call   800322 <_panic>
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  800d69:	8b 45 08             	mov    0x8(%ebp),%eax
  800d6c:	a3 08 20 80 00       	mov    %eax,0x802008
}
  800d71:	c9                   	leave  
  800d72:	c3                   	ret    
  800d73:	66 90                	xchg   %ax,%ax
  800d75:	66 90                	xchg   %ax,%ax
  800d77:	66 90                	xchg   %ax,%ax
  800d79:	66 90                	xchg   %ax,%ax
  800d7b:	66 90                	xchg   %ax,%ax
  800d7d:	66 90                	xchg   %ax,%ax
  800d7f:	90                   	nop

00800d80 <__udivdi3>:
  800d80:	55                   	push   %ebp
  800d81:	57                   	push   %edi
  800d82:	56                   	push   %esi
  800d83:	53                   	push   %ebx
  800d84:	83 ec 1c             	sub    $0x1c,%esp
  800d87:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800d8b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800d8f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800d93:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d97:	85 f6                	test   %esi,%esi
  800d99:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d9d:	89 ca                	mov    %ecx,%edx
  800d9f:	89 f8                	mov    %edi,%eax
  800da1:	75 3d                	jne    800de0 <__udivdi3+0x60>
  800da3:	39 cf                	cmp    %ecx,%edi
  800da5:	0f 87 c5 00 00 00    	ja     800e70 <__udivdi3+0xf0>
  800dab:	85 ff                	test   %edi,%edi
  800dad:	89 fd                	mov    %edi,%ebp
  800daf:	75 0b                	jne    800dbc <__udivdi3+0x3c>
  800db1:	b8 01 00 00 00       	mov    $0x1,%eax
  800db6:	31 d2                	xor    %edx,%edx
  800db8:	f7 f7                	div    %edi
  800dba:	89 c5                	mov    %eax,%ebp
  800dbc:	89 c8                	mov    %ecx,%eax
  800dbe:	31 d2                	xor    %edx,%edx
  800dc0:	f7 f5                	div    %ebp
  800dc2:	89 c1                	mov    %eax,%ecx
  800dc4:	89 d8                	mov    %ebx,%eax
  800dc6:	89 cf                	mov    %ecx,%edi
  800dc8:	f7 f5                	div    %ebp
  800dca:	89 c3                	mov    %eax,%ebx
  800dcc:	89 d8                	mov    %ebx,%eax
  800dce:	89 fa                	mov    %edi,%edx
  800dd0:	83 c4 1c             	add    $0x1c,%esp
  800dd3:	5b                   	pop    %ebx
  800dd4:	5e                   	pop    %esi
  800dd5:	5f                   	pop    %edi
  800dd6:	5d                   	pop    %ebp
  800dd7:	c3                   	ret    
  800dd8:	90                   	nop
  800dd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800de0:	39 ce                	cmp    %ecx,%esi
  800de2:	77 74                	ja     800e58 <__udivdi3+0xd8>
  800de4:	0f bd fe             	bsr    %esi,%edi
  800de7:	83 f7 1f             	xor    $0x1f,%edi
  800dea:	0f 84 98 00 00 00    	je     800e88 <__udivdi3+0x108>
  800df0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800df5:	89 f9                	mov    %edi,%ecx
  800df7:	89 c5                	mov    %eax,%ebp
  800df9:	29 fb                	sub    %edi,%ebx
  800dfb:	d3 e6                	shl    %cl,%esi
  800dfd:	89 d9                	mov    %ebx,%ecx
  800dff:	d3 ed                	shr    %cl,%ebp
  800e01:	89 f9                	mov    %edi,%ecx
  800e03:	d3 e0                	shl    %cl,%eax
  800e05:	09 ee                	or     %ebp,%esi
  800e07:	89 d9                	mov    %ebx,%ecx
  800e09:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800e0d:	89 d5                	mov    %edx,%ebp
  800e0f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e13:	d3 ed                	shr    %cl,%ebp
  800e15:	89 f9                	mov    %edi,%ecx
  800e17:	d3 e2                	shl    %cl,%edx
  800e19:	89 d9                	mov    %ebx,%ecx
  800e1b:	d3 e8                	shr    %cl,%eax
  800e1d:	09 c2                	or     %eax,%edx
  800e1f:	89 d0                	mov    %edx,%eax
  800e21:	89 ea                	mov    %ebp,%edx
  800e23:	f7 f6                	div    %esi
  800e25:	89 d5                	mov    %edx,%ebp
  800e27:	89 c3                	mov    %eax,%ebx
  800e29:	f7 64 24 0c          	mull   0xc(%esp)
  800e2d:	39 d5                	cmp    %edx,%ebp
  800e2f:	72 10                	jb     800e41 <__udivdi3+0xc1>
  800e31:	8b 74 24 08          	mov    0x8(%esp),%esi
  800e35:	89 f9                	mov    %edi,%ecx
  800e37:	d3 e6                	shl    %cl,%esi
  800e39:	39 c6                	cmp    %eax,%esi
  800e3b:	73 07                	jae    800e44 <__udivdi3+0xc4>
  800e3d:	39 d5                	cmp    %edx,%ebp
  800e3f:	75 03                	jne    800e44 <__udivdi3+0xc4>
  800e41:	83 eb 01             	sub    $0x1,%ebx
  800e44:	31 ff                	xor    %edi,%edi
  800e46:	89 d8                	mov    %ebx,%eax
  800e48:	89 fa                	mov    %edi,%edx
  800e4a:	83 c4 1c             	add    $0x1c,%esp
  800e4d:	5b                   	pop    %ebx
  800e4e:	5e                   	pop    %esi
  800e4f:	5f                   	pop    %edi
  800e50:	5d                   	pop    %ebp
  800e51:	c3                   	ret    
  800e52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e58:	31 ff                	xor    %edi,%edi
  800e5a:	31 db                	xor    %ebx,%ebx
  800e5c:	89 d8                	mov    %ebx,%eax
  800e5e:	89 fa                	mov    %edi,%edx
  800e60:	83 c4 1c             	add    $0x1c,%esp
  800e63:	5b                   	pop    %ebx
  800e64:	5e                   	pop    %esi
  800e65:	5f                   	pop    %edi
  800e66:	5d                   	pop    %ebp
  800e67:	c3                   	ret    
  800e68:	90                   	nop
  800e69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e70:	89 d8                	mov    %ebx,%eax
  800e72:	f7 f7                	div    %edi
  800e74:	31 ff                	xor    %edi,%edi
  800e76:	89 c3                	mov    %eax,%ebx
  800e78:	89 d8                	mov    %ebx,%eax
  800e7a:	89 fa                	mov    %edi,%edx
  800e7c:	83 c4 1c             	add    $0x1c,%esp
  800e7f:	5b                   	pop    %ebx
  800e80:	5e                   	pop    %esi
  800e81:	5f                   	pop    %edi
  800e82:	5d                   	pop    %ebp
  800e83:	c3                   	ret    
  800e84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e88:	39 ce                	cmp    %ecx,%esi
  800e8a:	72 0c                	jb     800e98 <__udivdi3+0x118>
  800e8c:	31 db                	xor    %ebx,%ebx
  800e8e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800e92:	0f 87 34 ff ff ff    	ja     800dcc <__udivdi3+0x4c>
  800e98:	bb 01 00 00 00       	mov    $0x1,%ebx
  800e9d:	e9 2a ff ff ff       	jmp    800dcc <__udivdi3+0x4c>
  800ea2:	66 90                	xchg   %ax,%ax
  800ea4:	66 90                	xchg   %ax,%ax
  800ea6:	66 90                	xchg   %ax,%ax
  800ea8:	66 90                	xchg   %ax,%ax
  800eaa:	66 90                	xchg   %ax,%ax
  800eac:	66 90                	xchg   %ax,%ax
  800eae:	66 90                	xchg   %ax,%ax

00800eb0 <__umoddi3>:
  800eb0:	55                   	push   %ebp
  800eb1:	57                   	push   %edi
  800eb2:	56                   	push   %esi
  800eb3:	53                   	push   %ebx
  800eb4:	83 ec 1c             	sub    $0x1c,%esp
  800eb7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800ebb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800ebf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800ec3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800ec7:	85 d2                	test   %edx,%edx
  800ec9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800ecd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ed1:	89 f3                	mov    %esi,%ebx
  800ed3:	89 3c 24             	mov    %edi,(%esp)
  800ed6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800eda:	75 1c                	jne    800ef8 <__umoddi3+0x48>
  800edc:	39 f7                	cmp    %esi,%edi
  800ede:	76 50                	jbe    800f30 <__umoddi3+0x80>
  800ee0:	89 c8                	mov    %ecx,%eax
  800ee2:	89 f2                	mov    %esi,%edx
  800ee4:	f7 f7                	div    %edi
  800ee6:	89 d0                	mov    %edx,%eax
  800ee8:	31 d2                	xor    %edx,%edx
  800eea:	83 c4 1c             	add    $0x1c,%esp
  800eed:	5b                   	pop    %ebx
  800eee:	5e                   	pop    %esi
  800eef:	5f                   	pop    %edi
  800ef0:	5d                   	pop    %ebp
  800ef1:	c3                   	ret    
  800ef2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ef8:	39 f2                	cmp    %esi,%edx
  800efa:	89 d0                	mov    %edx,%eax
  800efc:	77 52                	ja     800f50 <__umoddi3+0xa0>
  800efe:	0f bd ea             	bsr    %edx,%ebp
  800f01:	83 f5 1f             	xor    $0x1f,%ebp
  800f04:	75 5a                	jne    800f60 <__umoddi3+0xb0>
  800f06:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800f0a:	0f 82 e0 00 00 00    	jb     800ff0 <__umoddi3+0x140>
  800f10:	39 0c 24             	cmp    %ecx,(%esp)
  800f13:	0f 86 d7 00 00 00    	jbe    800ff0 <__umoddi3+0x140>
  800f19:	8b 44 24 08          	mov    0x8(%esp),%eax
  800f1d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800f21:	83 c4 1c             	add    $0x1c,%esp
  800f24:	5b                   	pop    %ebx
  800f25:	5e                   	pop    %esi
  800f26:	5f                   	pop    %edi
  800f27:	5d                   	pop    %ebp
  800f28:	c3                   	ret    
  800f29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f30:	85 ff                	test   %edi,%edi
  800f32:	89 fd                	mov    %edi,%ebp
  800f34:	75 0b                	jne    800f41 <__umoddi3+0x91>
  800f36:	b8 01 00 00 00       	mov    $0x1,%eax
  800f3b:	31 d2                	xor    %edx,%edx
  800f3d:	f7 f7                	div    %edi
  800f3f:	89 c5                	mov    %eax,%ebp
  800f41:	89 f0                	mov    %esi,%eax
  800f43:	31 d2                	xor    %edx,%edx
  800f45:	f7 f5                	div    %ebp
  800f47:	89 c8                	mov    %ecx,%eax
  800f49:	f7 f5                	div    %ebp
  800f4b:	89 d0                	mov    %edx,%eax
  800f4d:	eb 99                	jmp    800ee8 <__umoddi3+0x38>
  800f4f:	90                   	nop
  800f50:	89 c8                	mov    %ecx,%eax
  800f52:	89 f2                	mov    %esi,%edx
  800f54:	83 c4 1c             	add    $0x1c,%esp
  800f57:	5b                   	pop    %ebx
  800f58:	5e                   	pop    %esi
  800f59:	5f                   	pop    %edi
  800f5a:	5d                   	pop    %ebp
  800f5b:	c3                   	ret    
  800f5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f60:	8b 34 24             	mov    (%esp),%esi
  800f63:	bf 20 00 00 00       	mov    $0x20,%edi
  800f68:	89 e9                	mov    %ebp,%ecx
  800f6a:	29 ef                	sub    %ebp,%edi
  800f6c:	d3 e0                	shl    %cl,%eax
  800f6e:	89 f9                	mov    %edi,%ecx
  800f70:	89 f2                	mov    %esi,%edx
  800f72:	d3 ea                	shr    %cl,%edx
  800f74:	89 e9                	mov    %ebp,%ecx
  800f76:	09 c2                	or     %eax,%edx
  800f78:	89 d8                	mov    %ebx,%eax
  800f7a:	89 14 24             	mov    %edx,(%esp)
  800f7d:	89 f2                	mov    %esi,%edx
  800f7f:	d3 e2                	shl    %cl,%edx
  800f81:	89 f9                	mov    %edi,%ecx
  800f83:	89 54 24 04          	mov    %edx,0x4(%esp)
  800f87:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800f8b:	d3 e8                	shr    %cl,%eax
  800f8d:	89 e9                	mov    %ebp,%ecx
  800f8f:	89 c6                	mov    %eax,%esi
  800f91:	d3 e3                	shl    %cl,%ebx
  800f93:	89 f9                	mov    %edi,%ecx
  800f95:	89 d0                	mov    %edx,%eax
  800f97:	d3 e8                	shr    %cl,%eax
  800f99:	89 e9                	mov    %ebp,%ecx
  800f9b:	09 d8                	or     %ebx,%eax
  800f9d:	89 d3                	mov    %edx,%ebx
  800f9f:	89 f2                	mov    %esi,%edx
  800fa1:	f7 34 24             	divl   (%esp)
  800fa4:	89 d6                	mov    %edx,%esi
  800fa6:	d3 e3                	shl    %cl,%ebx
  800fa8:	f7 64 24 04          	mull   0x4(%esp)
  800fac:	39 d6                	cmp    %edx,%esi
  800fae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800fb2:	89 d1                	mov    %edx,%ecx
  800fb4:	89 c3                	mov    %eax,%ebx
  800fb6:	72 08                	jb     800fc0 <__umoddi3+0x110>
  800fb8:	75 11                	jne    800fcb <__umoddi3+0x11b>
  800fba:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800fbe:	73 0b                	jae    800fcb <__umoddi3+0x11b>
  800fc0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800fc4:	1b 14 24             	sbb    (%esp),%edx
  800fc7:	89 d1                	mov    %edx,%ecx
  800fc9:	89 c3                	mov    %eax,%ebx
  800fcb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800fcf:	29 da                	sub    %ebx,%edx
  800fd1:	19 ce                	sbb    %ecx,%esi
  800fd3:	89 f9                	mov    %edi,%ecx
  800fd5:	89 f0                	mov    %esi,%eax
  800fd7:	d3 e0                	shl    %cl,%eax
  800fd9:	89 e9                	mov    %ebp,%ecx
  800fdb:	d3 ea                	shr    %cl,%edx
  800fdd:	89 e9                	mov    %ebp,%ecx
  800fdf:	d3 ee                	shr    %cl,%esi
  800fe1:	09 d0                	or     %edx,%eax
  800fe3:	89 f2                	mov    %esi,%edx
  800fe5:	83 c4 1c             	add    $0x1c,%esp
  800fe8:	5b                   	pop    %ebx
  800fe9:	5e                   	pop    %esi
  800fea:	5f                   	pop    %edi
  800feb:	5d                   	pop    %ebp
  800fec:	c3                   	ret    
  800fed:	8d 76 00             	lea    0x0(%esi),%esi
  800ff0:	29 f9                	sub    %edi,%ecx
  800ff2:	19 d6                	sbb    %edx,%esi
  800ff4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800ff8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ffc:	e9 18 ff ff ff       	jmp    800f19 <__umoddi3+0x69>
