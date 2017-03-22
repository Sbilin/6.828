
obj/user/idle:     file format elf32-i386


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
#include <inc/x86.h>
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 08             	sub    $0x8,%esp
	binaryname = "idle";
  800039:	c7 05 00 20 80 00 e0 	movl   $0x800fe0,0x802000
  800040:	0f 80 00 
	// Instead of busy-waiting like this,
	// a better way would be to use the processor's HLT instruction
	// to cause the processor to stop executing until the next interrupt -
	// doing so allows the processor to conserve power more effectively.
	while (1) {
		sys_yield();
  800043:	e8 f7 00 00 00       	call   80013f <sys_yield>
  800048:	eb f9                	jmp    800043 <umain+0x10>

0080004a <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80004a:	55                   	push   %ebp
  80004b:	89 e5                	mov    %esp,%ebp
  80004d:	56                   	push   %esi
  80004e:	53                   	push   %ebx
  80004f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800052:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = envs+ENVX(sys_getenvid());
  800055:	e8 c6 00 00 00       	call   800120 <sys_getenvid>
  80005a:	25 ff 03 00 00       	and    $0x3ff,%eax
  80005f:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800062:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800067:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  80006c:	85 db                	test   %ebx,%ebx
  80006e:	7e 07                	jle    800077 <libmain+0x2d>
		binaryname = argv[0];
  800070:	8b 06                	mov    (%esi),%eax
  800072:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800077:	83 ec 08             	sub    $0x8,%esp
  80007a:	56                   	push   %esi
  80007b:	53                   	push   %ebx
  80007c:	e8 b2 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800081:	e8 0a 00 00 00       	call   800090 <exit>
}
  800086:	83 c4 10             	add    $0x10,%esp
  800089:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80008c:	5b                   	pop    %ebx
  80008d:	5e                   	pop    %esi
  80008e:	5d                   	pop    %ebp
  80008f:	c3                   	ret    

00800090 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800090:	55                   	push   %ebp
  800091:	89 e5                	mov    %esp,%ebp
  800093:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800096:	6a 00                	push   $0x0
  800098:	e8 42 00 00 00       	call   8000df <sys_env_destroy>
}
  80009d:	83 c4 10             	add    $0x10,%esp
  8000a0:	c9                   	leave  
  8000a1:	c3                   	ret    

008000a2 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000a2:	55                   	push   %ebp
  8000a3:	89 e5                	mov    %esp,%ebp
  8000a5:	57                   	push   %edi
  8000a6:	56                   	push   %esi
  8000a7:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a8:	b8 00 00 00 00       	mov    $0x0,%eax
  8000ad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000b0:	8b 55 08             	mov    0x8(%ebp),%edx
  8000b3:	89 c3                	mov    %eax,%ebx
  8000b5:	89 c7                	mov    %eax,%edi
  8000b7:	89 c6                	mov    %eax,%esi
  8000b9:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000bb:	5b                   	pop    %ebx
  8000bc:	5e                   	pop    %esi
  8000bd:	5f                   	pop    %edi
  8000be:	5d                   	pop    %ebp
  8000bf:	c3                   	ret    

008000c0 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000c0:	55                   	push   %ebp
  8000c1:	89 e5                	mov    %esp,%ebp
  8000c3:	57                   	push   %edi
  8000c4:	56                   	push   %esi
  8000c5:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000c6:	ba 00 00 00 00       	mov    $0x0,%edx
  8000cb:	b8 01 00 00 00       	mov    $0x1,%eax
  8000d0:	89 d1                	mov    %edx,%ecx
  8000d2:	89 d3                	mov    %edx,%ebx
  8000d4:	89 d7                	mov    %edx,%edi
  8000d6:	89 d6                	mov    %edx,%esi
  8000d8:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000da:	5b                   	pop    %ebx
  8000db:	5e                   	pop    %esi
  8000dc:	5f                   	pop    %edi
  8000dd:	5d                   	pop    %ebp
  8000de:	c3                   	ret    

008000df <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000df:	55                   	push   %ebp
  8000e0:	89 e5                	mov    %esp,%ebp
  8000e2:	57                   	push   %edi
  8000e3:	56                   	push   %esi
  8000e4:	53                   	push   %ebx
  8000e5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000e8:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000ed:	b8 03 00 00 00       	mov    $0x3,%eax
  8000f2:	8b 55 08             	mov    0x8(%ebp),%edx
  8000f5:	89 cb                	mov    %ecx,%ebx
  8000f7:	89 cf                	mov    %ecx,%edi
  8000f9:	89 ce                	mov    %ecx,%esi
  8000fb:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000fd:	85 c0                	test   %eax,%eax
  8000ff:	7e 17                	jle    800118 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800101:	83 ec 0c             	sub    $0xc,%esp
  800104:	50                   	push   %eax
  800105:	6a 03                	push   $0x3
  800107:	68 ef 0f 80 00       	push   $0x800fef
  80010c:	6a 23                	push   $0x23
  80010e:	68 0c 10 80 00       	push   $0x80100c
  800113:	e8 f5 01 00 00       	call   80030d <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800118:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80011b:	5b                   	pop    %ebx
  80011c:	5e                   	pop    %esi
  80011d:	5f                   	pop    %edi
  80011e:	5d                   	pop    %ebp
  80011f:	c3                   	ret    

00800120 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800120:	55                   	push   %ebp
  800121:	89 e5                	mov    %esp,%ebp
  800123:	57                   	push   %edi
  800124:	56                   	push   %esi
  800125:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800126:	ba 00 00 00 00       	mov    $0x0,%edx
  80012b:	b8 02 00 00 00       	mov    $0x2,%eax
  800130:	89 d1                	mov    %edx,%ecx
  800132:	89 d3                	mov    %edx,%ebx
  800134:	89 d7                	mov    %edx,%edi
  800136:	89 d6                	mov    %edx,%esi
  800138:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80013a:	5b                   	pop    %ebx
  80013b:	5e                   	pop    %esi
  80013c:	5f                   	pop    %edi
  80013d:	5d                   	pop    %ebp
  80013e:	c3                   	ret    

0080013f <sys_yield>:

void
sys_yield(void)
{
  80013f:	55                   	push   %ebp
  800140:	89 e5                	mov    %esp,%ebp
  800142:	57                   	push   %edi
  800143:	56                   	push   %esi
  800144:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800145:	ba 00 00 00 00       	mov    $0x0,%edx
  80014a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80014f:	89 d1                	mov    %edx,%ecx
  800151:	89 d3                	mov    %edx,%ebx
  800153:	89 d7                	mov    %edx,%edi
  800155:	89 d6                	mov    %edx,%esi
  800157:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800159:	5b                   	pop    %ebx
  80015a:	5e                   	pop    %esi
  80015b:	5f                   	pop    %edi
  80015c:	5d                   	pop    %ebp
  80015d:	c3                   	ret    

0080015e <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  80015e:	55                   	push   %ebp
  80015f:	89 e5                	mov    %esp,%ebp
  800161:	57                   	push   %edi
  800162:	56                   	push   %esi
  800163:	53                   	push   %ebx
  800164:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800167:	be 00 00 00 00       	mov    $0x0,%esi
  80016c:	b8 04 00 00 00       	mov    $0x4,%eax
  800171:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800174:	8b 55 08             	mov    0x8(%ebp),%edx
  800177:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80017a:	89 f7                	mov    %esi,%edi
  80017c:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  80017e:	85 c0                	test   %eax,%eax
  800180:	7e 17                	jle    800199 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800182:	83 ec 0c             	sub    $0xc,%esp
  800185:	50                   	push   %eax
  800186:	6a 04                	push   $0x4
  800188:	68 ef 0f 80 00       	push   $0x800fef
  80018d:	6a 23                	push   $0x23
  80018f:	68 0c 10 80 00       	push   $0x80100c
  800194:	e8 74 01 00 00       	call   80030d <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800199:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80019c:	5b                   	pop    %ebx
  80019d:	5e                   	pop    %esi
  80019e:	5f                   	pop    %edi
  80019f:	5d                   	pop    %ebp
  8001a0:	c3                   	ret    

008001a1 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001a1:	55                   	push   %ebp
  8001a2:	89 e5                	mov    %esp,%ebp
  8001a4:	57                   	push   %edi
  8001a5:	56                   	push   %esi
  8001a6:	53                   	push   %ebx
  8001a7:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001aa:	b8 05 00 00 00       	mov    $0x5,%eax
  8001af:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001b2:	8b 55 08             	mov    0x8(%ebp),%edx
  8001b5:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001b8:	8b 7d 14             	mov    0x14(%ebp),%edi
  8001bb:	8b 75 18             	mov    0x18(%ebp),%esi
  8001be:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8001c0:	85 c0                	test   %eax,%eax
  8001c2:	7e 17                	jle    8001db <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8001c4:	83 ec 0c             	sub    $0xc,%esp
  8001c7:	50                   	push   %eax
  8001c8:	6a 05                	push   $0x5
  8001ca:	68 ef 0f 80 00       	push   $0x800fef
  8001cf:	6a 23                	push   $0x23
  8001d1:	68 0c 10 80 00       	push   $0x80100c
  8001d6:	e8 32 01 00 00       	call   80030d <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  8001db:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001de:	5b                   	pop    %ebx
  8001df:	5e                   	pop    %esi
  8001e0:	5f                   	pop    %edi
  8001e1:	5d                   	pop    %ebp
  8001e2:	c3                   	ret    

008001e3 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001e3:	55                   	push   %ebp
  8001e4:	89 e5                	mov    %esp,%ebp
  8001e6:	57                   	push   %edi
  8001e7:	56                   	push   %esi
  8001e8:	53                   	push   %ebx
  8001e9:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001ec:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001f1:	b8 06 00 00 00       	mov    $0x6,%eax
  8001f6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001f9:	8b 55 08             	mov    0x8(%ebp),%edx
  8001fc:	89 df                	mov    %ebx,%edi
  8001fe:	89 de                	mov    %ebx,%esi
  800200:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800202:	85 c0                	test   %eax,%eax
  800204:	7e 17                	jle    80021d <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800206:	83 ec 0c             	sub    $0xc,%esp
  800209:	50                   	push   %eax
  80020a:	6a 06                	push   $0x6
  80020c:	68 ef 0f 80 00       	push   $0x800fef
  800211:	6a 23                	push   $0x23
  800213:	68 0c 10 80 00       	push   $0x80100c
  800218:	e8 f0 00 00 00       	call   80030d <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  80021d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800220:	5b                   	pop    %ebx
  800221:	5e                   	pop    %esi
  800222:	5f                   	pop    %edi
  800223:	5d                   	pop    %ebp
  800224:	c3                   	ret    

00800225 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800225:	55                   	push   %ebp
  800226:	89 e5                	mov    %esp,%ebp
  800228:	57                   	push   %edi
  800229:	56                   	push   %esi
  80022a:	53                   	push   %ebx
  80022b:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80022e:	bb 00 00 00 00       	mov    $0x0,%ebx
  800233:	b8 08 00 00 00       	mov    $0x8,%eax
  800238:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80023b:	8b 55 08             	mov    0x8(%ebp),%edx
  80023e:	89 df                	mov    %ebx,%edi
  800240:	89 de                	mov    %ebx,%esi
  800242:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800244:	85 c0                	test   %eax,%eax
  800246:	7e 17                	jle    80025f <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800248:	83 ec 0c             	sub    $0xc,%esp
  80024b:	50                   	push   %eax
  80024c:	6a 08                	push   $0x8
  80024e:	68 ef 0f 80 00       	push   $0x800fef
  800253:	6a 23                	push   $0x23
  800255:	68 0c 10 80 00       	push   $0x80100c
  80025a:	e8 ae 00 00 00       	call   80030d <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  80025f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800262:	5b                   	pop    %ebx
  800263:	5e                   	pop    %esi
  800264:	5f                   	pop    %edi
  800265:	5d                   	pop    %ebp
  800266:	c3                   	ret    

00800267 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800267:	55                   	push   %ebp
  800268:	89 e5                	mov    %esp,%ebp
  80026a:	57                   	push   %edi
  80026b:	56                   	push   %esi
  80026c:	53                   	push   %ebx
  80026d:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800270:	bb 00 00 00 00       	mov    $0x0,%ebx
  800275:	b8 09 00 00 00       	mov    $0x9,%eax
  80027a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80027d:	8b 55 08             	mov    0x8(%ebp),%edx
  800280:	89 df                	mov    %ebx,%edi
  800282:	89 de                	mov    %ebx,%esi
  800284:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800286:	85 c0                	test   %eax,%eax
  800288:	7e 17                	jle    8002a1 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  80028a:	83 ec 0c             	sub    $0xc,%esp
  80028d:	50                   	push   %eax
  80028e:	6a 09                	push   $0x9
  800290:	68 ef 0f 80 00       	push   $0x800fef
  800295:	6a 23                	push   $0x23
  800297:	68 0c 10 80 00       	push   $0x80100c
  80029c:	e8 6c 00 00 00       	call   80030d <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  8002a1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002a4:	5b                   	pop    %ebx
  8002a5:	5e                   	pop    %esi
  8002a6:	5f                   	pop    %edi
  8002a7:	5d                   	pop    %ebp
  8002a8:	c3                   	ret    

008002a9 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  8002a9:	55                   	push   %ebp
  8002aa:	89 e5                	mov    %esp,%ebp
  8002ac:	57                   	push   %edi
  8002ad:	56                   	push   %esi
  8002ae:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002af:	be 00 00 00 00       	mov    $0x0,%esi
  8002b4:	b8 0b 00 00 00       	mov    $0xb,%eax
  8002b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002bc:	8b 55 08             	mov    0x8(%ebp),%edx
  8002bf:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002c2:	8b 7d 14             	mov    0x14(%ebp),%edi
  8002c5:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8002c7:	5b                   	pop    %ebx
  8002c8:	5e                   	pop    %esi
  8002c9:	5f                   	pop    %edi
  8002ca:	5d                   	pop    %ebp
  8002cb:	c3                   	ret    

008002cc <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  8002cc:	55                   	push   %ebp
  8002cd:	89 e5                	mov    %esp,%ebp
  8002cf:	57                   	push   %edi
  8002d0:	56                   	push   %esi
  8002d1:	53                   	push   %ebx
  8002d2:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002d5:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002da:	b8 0c 00 00 00       	mov    $0xc,%eax
  8002df:	8b 55 08             	mov    0x8(%ebp),%edx
  8002e2:	89 cb                	mov    %ecx,%ebx
  8002e4:	89 cf                	mov    %ecx,%edi
  8002e6:	89 ce                	mov    %ecx,%esi
  8002e8:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8002ea:	85 c0                	test   %eax,%eax
  8002ec:	7e 17                	jle    800305 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002ee:	83 ec 0c             	sub    $0xc,%esp
  8002f1:	50                   	push   %eax
  8002f2:	6a 0c                	push   $0xc
  8002f4:	68 ef 0f 80 00       	push   $0x800fef
  8002f9:	6a 23                	push   $0x23
  8002fb:	68 0c 10 80 00       	push   $0x80100c
  800300:	e8 08 00 00 00       	call   80030d <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800305:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800308:	5b                   	pop    %ebx
  800309:	5e                   	pop    %esi
  80030a:	5f                   	pop    %edi
  80030b:	5d                   	pop    %ebp
  80030c:	c3                   	ret    

0080030d <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80030d:	55                   	push   %ebp
  80030e:	89 e5                	mov    %esp,%ebp
  800310:	56                   	push   %esi
  800311:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800312:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800315:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80031b:	e8 00 fe ff ff       	call   800120 <sys_getenvid>
  800320:	83 ec 0c             	sub    $0xc,%esp
  800323:	ff 75 0c             	pushl  0xc(%ebp)
  800326:	ff 75 08             	pushl  0x8(%ebp)
  800329:	56                   	push   %esi
  80032a:	50                   	push   %eax
  80032b:	68 1c 10 80 00       	push   $0x80101c
  800330:	e8 b1 00 00 00       	call   8003e6 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800335:	83 c4 18             	add    $0x18,%esp
  800338:	53                   	push   %ebx
  800339:	ff 75 10             	pushl  0x10(%ebp)
  80033c:	e8 54 00 00 00       	call   800395 <vcprintf>
	cprintf("\n");
  800341:	c7 04 24 40 10 80 00 	movl   $0x801040,(%esp)
  800348:	e8 99 00 00 00       	call   8003e6 <cprintf>
  80034d:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800350:	cc                   	int3   
  800351:	eb fd                	jmp    800350 <_panic+0x43>

00800353 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800353:	55                   	push   %ebp
  800354:	89 e5                	mov    %esp,%ebp
  800356:	53                   	push   %ebx
  800357:	83 ec 04             	sub    $0x4,%esp
  80035a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80035d:	8b 13                	mov    (%ebx),%edx
  80035f:	8d 42 01             	lea    0x1(%edx),%eax
  800362:	89 03                	mov    %eax,(%ebx)
  800364:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800367:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80036b:	3d ff 00 00 00       	cmp    $0xff,%eax
  800370:	75 1a                	jne    80038c <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800372:	83 ec 08             	sub    $0x8,%esp
  800375:	68 ff 00 00 00       	push   $0xff
  80037a:	8d 43 08             	lea    0x8(%ebx),%eax
  80037d:	50                   	push   %eax
  80037e:	e8 1f fd ff ff       	call   8000a2 <sys_cputs>
		b->idx = 0;
  800383:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800389:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80038c:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800390:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800393:	c9                   	leave  
  800394:	c3                   	ret    

00800395 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800395:	55                   	push   %ebp
  800396:	89 e5                	mov    %esp,%ebp
  800398:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  80039e:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8003a5:	00 00 00 
	b.cnt = 0;
  8003a8:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8003af:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8003b2:	ff 75 0c             	pushl  0xc(%ebp)
  8003b5:	ff 75 08             	pushl  0x8(%ebp)
  8003b8:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8003be:	50                   	push   %eax
  8003bf:	68 53 03 80 00       	push   $0x800353
  8003c4:	e8 1a 01 00 00       	call   8004e3 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8003c9:	83 c4 08             	add    $0x8,%esp
  8003cc:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8003d2:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8003d8:	50                   	push   %eax
  8003d9:	e8 c4 fc ff ff       	call   8000a2 <sys_cputs>

	return b.cnt;
}
  8003de:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8003e4:	c9                   	leave  
  8003e5:	c3                   	ret    

008003e6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8003e6:	55                   	push   %ebp
  8003e7:	89 e5                	mov    %esp,%ebp
  8003e9:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8003ec:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8003ef:	50                   	push   %eax
  8003f0:	ff 75 08             	pushl  0x8(%ebp)
  8003f3:	e8 9d ff ff ff       	call   800395 <vcprintf>
	va_end(ap);

	return cnt;
}
  8003f8:	c9                   	leave  
  8003f9:	c3                   	ret    

008003fa <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8003fa:	55                   	push   %ebp
  8003fb:	89 e5                	mov    %esp,%ebp
  8003fd:	57                   	push   %edi
  8003fe:	56                   	push   %esi
  8003ff:	53                   	push   %ebx
  800400:	83 ec 1c             	sub    $0x1c,%esp
  800403:	89 c7                	mov    %eax,%edi
  800405:	89 d6                	mov    %edx,%esi
  800407:	8b 45 08             	mov    0x8(%ebp),%eax
  80040a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80040d:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800410:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800413:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800416:	bb 00 00 00 00       	mov    $0x0,%ebx
  80041b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80041e:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800421:	39 d3                	cmp    %edx,%ebx
  800423:	72 05                	jb     80042a <printnum+0x30>
  800425:	39 45 10             	cmp    %eax,0x10(%ebp)
  800428:	77 45                	ja     80046f <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80042a:	83 ec 0c             	sub    $0xc,%esp
  80042d:	ff 75 18             	pushl  0x18(%ebp)
  800430:	8b 45 14             	mov    0x14(%ebp),%eax
  800433:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800436:	53                   	push   %ebx
  800437:	ff 75 10             	pushl  0x10(%ebp)
  80043a:	83 ec 08             	sub    $0x8,%esp
  80043d:	ff 75 e4             	pushl  -0x1c(%ebp)
  800440:	ff 75 e0             	pushl  -0x20(%ebp)
  800443:	ff 75 dc             	pushl  -0x24(%ebp)
  800446:	ff 75 d8             	pushl  -0x28(%ebp)
  800449:	e8 f2 08 00 00       	call   800d40 <__udivdi3>
  80044e:	83 c4 18             	add    $0x18,%esp
  800451:	52                   	push   %edx
  800452:	50                   	push   %eax
  800453:	89 f2                	mov    %esi,%edx
  800455:	89 f8                	mov    %edi,%eax
  800457:	e8 9e ff ff ff       	call   8003fa <printnum>
  80045c:	83 c4 20             	add    $0x20,%esp
  80045f:	eb 18                	jmp    800479 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800461:	83 ec 08             	sub    $0x8,%esp
  800464:	56                   	push   %esi
  800465:	ff 75 18             	pushl  0x18(%ebp)
  800468:	ff d7                	call   *%edi
  80046a:	83 c4 10             	add    $0x10,%esp
  80046d:	eb 03                	jmp    800472 <printnum+0x78>
  80046f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800472:	83 eb 01             	sub    $0x1,%ebx
  800475:	85 db                	test   %ebx,%ebx
  800477:	7f e8                	jg     800461 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800479:	83 ec 08             	sub    $0x8,%esp
  80047c:	56                   	push   %esi
  80047d:	83 ec 04             	sub    $0x4,%esp
  800480:	ff 75 e4             	pushl  -0x1c(%ebp)
  800483:	ff 75 e0             	pushl  -0x20(%ebp)
  800486:	ff 75 dc             	pushl  -0x24(%ebp)
  800489:	ff 75 d8             	pushl  -0x28(%ebp)
  80048c:	e8 df 09 00 00       	call   800e70 <__umoddi3>
  800491:	83 c4 14             	add    $0x14,%esp
  800494:	0f be 80 42 10 80 00 	movsbl 0x801042(%eax),%eax
  80049b:	50                   	push   %eax
  80049c:	ff d7                	call   *%edi
}
  80049e:	83 c4 10             	add    $0x10,%esp
  8004a1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8004a4:	5b                   	pop    %ebx
  8004a5:	5e                   	pop    %esi
  8004a6:	5f                   	pop    %edi
  8004a7:	5d                   	pop    %ebp
  8004a8:	c3                   	ret    

008004a9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8004a9:	55                   	push   %ebp
  8004aa:	89 e5                	mov    %esp,%ebp
  8004ac:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004af:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004b3:	8b 10                	mov    (%eax),%edx
  8004b5:	3b 50 04             	cmp    0x4(%eax),%edx
  8004b8:	73 0a                	jae    8004c4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8004ba:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004bd:	89 08                	mov    %ecx,(%eax)
  8004bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8004c2:	88 02                	mov    %al,(%edx)
}
  8004c4:	5d                   	pop    %ebp
  8004c5:	c3                   	ret    

008004c6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004c6:	55                   	push   %ebp
  8004c7:	89 e5                	mov    %esp,%ebp
  8004c9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8004cc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8004cf:	50                   	push   %eax
  8004d0:	ff 75 10             	pushl  0x10(%ebp)
  8004d3:	ff 75 0c             	pushl  0xc(%ebp)
  8004d6:	ff 75 08             	pushl  0x8(%ebp)
  8004d9:	e8 05 00 00 00       	call   8004e3 <vprintfmt>
	va_end(ap);
}
  8004de:	83 c4 10             	add    $0x10,%esp
  8004e1:	c9                   	leave  
  8004e2:	c3                   	ret    

008004e3 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8004e3:	55                   	push   %ebp
  8004e4:	89 e5                	mov    %esp,%ebp
  8004e6:	57                   	push   %edi
  8004e7:	56                   	push   %esi
  8004e8:	53                   	push   %ebx
  8004e9:	83 ec 2c             	sub    $0x2c,%esp
  8004ec:	8b 75 08             	mov    0x8(%ebp),%esi
  8004ef:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004f2:	8b 7d 10             	mov    0x10(%ebp),%edi
  8004f5:	eb 12                	jmp    800509 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8004f7:	85 c0                	test   %eax,%eax
  8004f9:	0f 84 42 04 00 00    	je     800941 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  8004ff:	83 ec 08             	sub    $0x8,%esp
  800502:	53                   	push   %ebx
  800503:	50                   	push   %eax
  800504:	ff d6                	call   *%esi
  800506:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800509:	83 c7 01             	add    $0x1,%edi
  80050c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800510:	83 f8 25             	cmp    $0x25,%eax
  800513:	75 e2                	jne    8004f7 <vprintfmt+0x14>
  800515:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800519:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800520:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800527:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80052e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800533:	eb 07                	jmp    80053c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800535:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800538:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80053c:	8d 47 01             	lea    0x1(%edi),%eax
  80053f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800542:	0f b6 07             	movzbl (%edi),%eax
  800545:	0f b6 d0             	movzbl %al,%edx
  800548:	83 e8 23             	sub    $0x23,%eax
  80054b:	3c 55                	cmp    $0x55,%al
  80054d:	0f 87 d3 03 00 00    	ja     800926 <vprintfmt+0x443>
  800553:	0f b6 c0             	movzbl %al,%eax
  800556:	ff 24 85 00 11 80 00 	jmp    *0x801100(,%eax,4)
  80055d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800560:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800564:	eb d6                	jmp    80053c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800566:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800569:	b8 00 00 00 00       	mov    $0x0,%eax
  80056e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800571:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800574:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800578:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  80057b:	8d 4a d0             	lea    -0x30(%edx),%ecx
  80057e:	83 f9 09             	cmp    $0x9,%ecx
  800581:	77 3f                	ja     8005c2 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800583:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800586:	eb e9                	jmp    800571 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800588:	8b 45 14             	mov    0x14(%ebp),%eax
  80058b:	8b 00                	mov    (%eax),%eax
  80058d:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800590:	8b 45 14             	mov    0x14(%ebp),%eax
  800593:	8d 40 04             	lea    0x4(%eax),%eax
  800596:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800599:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80059c:	eb 2a                	jmp    8005c8 <vprintfmt+0xe5>
  80059e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005a1:	85 c0                	test   %eax,%eax
  8005a3:	ba 00 00 00 00       	mov    $0x0,%edx
  8005a8:	0f 49 d0             	cmovns %eax,%edx
  8005ab:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005b1:	eb 89                	jmp    80053c <vprintfmt+0x59>
  8005b3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005b6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8005bd:	e9 7a ff ff ff       	jmp    80053c <vprintfmt+0x59>
  8005c2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8005c5:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8005c8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005cc:	0f 89 6a ff ff ff    	jns    80053c <vprintfmt+0x59>
				width = precision, precision = -1;
  8005d2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005d5:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005d8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8005df:	e9 58 ff ff ff       	jmp    80053c <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8005e4:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005e7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8005ea:	e9 4d ff ff ff       	jmp    80053c <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8005ef:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f2:	8d 78 04             	lea    0x4(%eax),%edi
  8005f5:	83 ec 08             	sub    $0x8,%esp
  8005f8:	53                   	push   %ebx
  8005f9:	ff 30                	pushl  (%eax)
  8005fb:	ff d6                	call   *%esi
			break;
  8005fd:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800600:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800603:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800606:	e9 fe fe ff ff       	jmp    800509 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80060b:	8b 45 14             	mov    0x14(%ebp),%eax
  80060e:	8d 78 04             	lea    0x4(%eax),%edi
  800611:	8b 00                	mov    (%eax),%eax
  800613:	99                   	cltd   
  800614:	31 d0                	xor    %edx,%eax
  800616:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800618:	83 f8 08             	cmp    $0x8,%eax
  80061b:	7f 0b                	jg     800628 <vprintfmt+0x145>
  80061d:	8b 14 85 60 12 80 00 	mov    0x801260(,%eax,4),%edx
  800624:	85 d2                	test   %edx,%edx
  800626:	75 1b                	jne    800643 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800628:	50                   	push   %eax
  800629:	68 5a 10 80 00       	push   $0x80105a
  80062e:	53                   	push   %ebx
  80062f:	56                   	push   %esi
  800630:	e8 91 fe ff ff       	call   8004c6 <printfmt>
  800635:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800638:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80063b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80063e:	e9 c6 fe ff ff       	jmp    800509 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800643:	52                   	push   %edx
  800644:	68 63 10 80 00       	push   $0x801063
  800649:	53                   	push   %ebx
  80064a:	56                   	push   %esi
  80064b:	e8 76 fe ff ff       	call   8004c6 <printfmt>
  800650:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800653:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800656:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800659:	e9 ab fe ff ff       	jmp    800509 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80065e:	8b 45 14             	mov    0x14(%ebp),%eax
  800661:	83 c0 04             	add    $0x4,%eax
  800664:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800667:	8b 45 14             	mov    0x14(%ebp),%eax
  80066a:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80066c:	85 ff                	test   %edi,%edi
  80066e:	b8 53 10 80 00       	mov    $0x801053,%eax
  800673:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800676:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80067a:	0f 8e 94 00 00 00    	jle    800714 <vprintfmt+0x231>
  800680:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800684:	0f 84 98 00 00 00    	je     800722 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  80068a:	83 ec 08             	sub    $0x8,%esp
  80068d:	ff 75 d0             	pushl  -0x30(%ebp)
  800690:	57                   	push   %edi
  800691:	e8 33 03 00 00       	call   8009c9 <strnlen>
  800696:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800699:	29 c1                	sub    %eax,%ecx
  80069b:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  80069e:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8006a1:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8006a5:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8006a8:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8006ab:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006ad:	eb 0f                	jmp    8006be <vprintfmt+0x1db>
					putch(padc, putdat);
  8006af:	83 ec 08             	sub    $0x8,%esp
  8006b2:	53                   	push   %ebx
  8006b3:	ff 75 e0             	pushl  -0x20(%ebp)
  8006b6:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006b8:	83 ef 01             	sub    $0x1,%edi
  8006bb:	83 c4 10             	add    $0x10,%esp
  8006be:	85 ff                	test   %edi,%edi
  8006c0:	7f ed                	jg     8006af <vprintfmt+0x1cc>
  8006c2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006c5:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8006c8:	85 c9                	test   %ecx,%ecx
  8006ca:	b8 00 00 00 00       	mov    $0x0,%eax
  8006cf:	0f 49 c1             	cmovns %ecx,%eax
  8006d2:	29 c1                	sub    %eax,%ecx
  8006d4:	89 75 08             	mov    %esi,0x8(%ebp)
  8006d7:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8006da:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8006dd:	89 cb                	mov    %ecx,%ebx
  8006df:	eb 4d                	jmp    80072e <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8006e1:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8006e5:	74 1b                	je     800702 <vprintfmt+0x21f>
  8006e7:	0f be c0             	movsbl %al,%eax
  8006ea:	83 e8 20             	sub    $0x20,%eax
  8006ed:	83 f8 5e             	cmp    $0x5e,%eax
  8006f0:	76 10                	jbe    800702 <vprintfmt+0x21f>
					putch('?', putdat);
  8006f2:	83 ec 08             	sub    $0x8,%esp
  8006f5:	ff 75 0c             	pushl  0xc(%ebp)
  8006f8:	6a 3f                	push   $0x3f
  8006fa:	ff 55 08             	call   *0x8(%ebp)
  8006fd:	83 c4 10             	add    $0x10,%esp
  800700:	eb 0d                	jmp    80070f <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800702:	83 ec 08             	sub    $0x8,%esp
  800705:	ff 75 0c             	pushl  0xc(%ebp)
  800708:	52                   	push   %edx
  800709:	ff 55 08             	call   *0x8(%ebp)
  80070c:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80070f:	83 eb 01             	sub    $0x1,%ebx
  800712:	eb 1a                	jmp    80072e <vprintfmt+0x24b>
  800714:	89 75 08             	mov    %esi,0x8(%ebp)
  800717:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80071a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80071d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800720:	eb 0c                	jmp    80072e <vprintfmt+0x24b>
  800722:	89 75 08             	mov    %esi,0x8(%ebp)
  800725:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800728:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80072b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80072e:	83 c7 01             	add    $0x1,%edi
  800731:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800735:	0f be d0             	movsbl %al,%edx
  800738:	85 d2                	test   %edx,%edx
  80073a:	74 23                	je     80075f <vprintfmt+0x27c>
  80073c:	85 f6                	test   %esi,%esi
  80073e:	78 a1                	js     8006e1 <vprintfmt+0x1fe>
  800740:	83 ee 01             	sub    $0x1,%esi
  800743:	79 9c                	jns    8006e1 <vprintfmt+0x1fe>
  800745:	89 df                	mov    %ebx,%edi
  800747:	8b 75 08             	mov    0x8(%ebp),%esi
  80074a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80074d:	eb 18                	jmp    800767 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80074f:	83 ec 08             	sub    $0x8,%esp
  800752:	53                   	push   %ebx
  800753:	6a 20                	push   $0x20
  800755:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800757:	83 ef 01             	sub    $0x1,%edi
  80075a:	83 c4 10             	add    $0x10,%esp
  80075d:	eb 08                	jmp    800767 <vprintfmt+0x284>
  80075f:	89 df                	mov    %ebx,%edi
  800761:	8b 75 08             	mov    0x8(%ebp),%esi
  800764:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800767:	85 ff                	test   %edi,%edi
  800769:	7f e4                	jg     80074f <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80076b:	8b 45 cc             	mov    -0x34(%ebp),%eax
  80076e:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800771:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800774:	e9 90 fd ff ff       	jmp    800509 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800779:	83 f9 01             	cmp    $0x1,%ecx
  80077c:	7e 19                	jle    800797 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  80077e:	8b 45 14             	mov    0x14(%ebp),%eax
  800781:	8b 50 04             	mov    0x4(%eax),%edx
  800784:	8b 00                	mov    (%eax),%eax
  800786:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800789:	89 55 dc             	mov    %edx,-0x24(%ebp)
  80078c:	8b 45 14             	mov    0x14(%ebp),%eax
  80078f:	8d 40 08             	lea    0x8(%eax),%eax
  800792:	89 45 14             	mov    %eax,0x14(%ebp)
  800795:	eb 38                	jmp    8007cf <vprintfmt+0x2ec>
	else if (lflag)
  800797:	85 c9                	test   %ecx,%ecx
  800799:	74 1b                	je     8007b6 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  80079b:	8b 45 14             	mov    0x14(%ebp),%eax
  80079e:	8b 00                	mov    (%eax),%eax
  8007a0:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007a3:	89 c1                	mov    %eax,%ecx
  8007a5:	c1 f9 1f             	sar    $0x1f,%ecx
  8007a8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8007ab:	8b 45 14             	mov    0x14(%ebp),%eax
  8007ae:	8d 40 04             	lea    0x4(%eax),%eax
  8007b1:	89 45 14             	mov    %eax,0x14(%ebp)
  8007b4:	eb 19                	jmp    8007cf <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8007b6:	8b 45 14             	mov    0x14(%ebp),%eax
  8007b9:	8b 00                	mov    (%eax),%eax
  8007bb:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007be:	89 c1                	mov    %eax,%ecx
  8007c0:	c1 f9 1f             	sar    $0x1f,%ecx
  8007c3:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8007c6:	8b 45 14             	mov    0x14(%ebp),%eax
  8007c9:	8d 40 04             	lea    0x4(%eax),%eax
  8007cc:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8007cf:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8007d2:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8007d5:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8007da:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8007de:	0f 89 0e 01 00 00    	jns    8008f2 <vprintfmt+0x40f>
				putch('-', putdat);
  8007e4:	83 ec 08             	sub    $0x8,%esp
  8007e7:	53                   	push   %ebx
  8007e8:	6a 2d                	push   $0x2d
  8007ea:	ff d6                	call   *%esi
				num = -(long long) num;
  8007ec:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8007ef:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8007f2:	f7 da                	neg    %edx
  8007f4:	83 d1 00             	adc    $0x0,%ecx
  8007f7:	f7 d9                	neg    %ecx
  8007f9:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  8007fc:	b8 0a 00 00 00       	mov    $0xa,%eax
  800801:	e9 ec 00 00 00       	jmp    8008f2 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800806:	83 f9 01             	cmp    $0x1,%ecx
  800809:	7e 18                	jle    800823 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80080b:	8b 45 14             	mov    0x14(%ebp),%eax
  80080e:	8b 10                	mov    (%eax),%edx
  800810:	8b 48 04             	mov    0x4(%eax),%ecx
  800813:	8d 40 08             	lea    0x8(%eax),%eax
  800816:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800819:	b8 0a 00 00 00       	mov    $0xa,%eax
  80081e:	e9 cf 00 00 00       	jmp    8008f2 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800823:	85 c9                	test   %ecx,%ecx
  800825:	74 1a                	je     800841 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800827:	8b 45 14             	mov    0x14(%ebp),%eax
  80082a:	8b 10                	mov    (%eax),%edx
  80082c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800831:	8d 40 04             	lea    0x4(%eax),%eax
  800834:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800837:	b8 0a 00 00 00       	mov    $0xa,%eax
  80083c:	e9 b1 00 00 00       	jmp    8008f2 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800841:	8b 45 14             	mov    0x14(%ebp),%eax
  800844:	8b 10                	mov    (%eax),%edx
  800846:	b9 00 00 00 00       	mov    $0x0,%ecx
  80084b:	8d 40 04             	lea    0x4(%eax),%eax
  80084e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800851:	b8 0a 00 00 00       	mov    $0xa,%eax
  800856:	e9 97 00 00 00       	jmp    8008f2 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  80085b:	83 ec 08             	sub    $0x8,%esp
  80085e:	53                   	push   %ebx
  80085f:	6a 58                	push   $0x58
  800861:	ff d6                	call   *%esi
			putch('X', putdat);
  800863:	83 c4 08             	add    $0x8,%esp
  800866:	53                   	push   %ebx
  800867:	6a 58                	push   $0x58
  800869:	ff d6                	call   *%esi
			putch('X', putdat);
  80086b:	83 c4 08             	add    $0x8,%esp
  80086e:	53                   	push   %ebx
  80086f:	6a 58                	push   $0x58
  800871:	ff d6                	call   *%esi
			break;
  800873:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800876:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  800879:	e9 8b fc ff ff       	jmp    800509 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  80087e:	83 ec 08             	sub    $0x8,%esp
  800881:	53                   	push   %ebx
  800882:	6a 30                	push   $0x30
  800884:	ff d6                	call   *%esi
			putch('x', putdat);
  800886:	83 c4 08             	add    $0x8,%esp
  800889:	53                   	push   %ebx
  80088a:	6a 78                	push   $0x78
  80088c:	ff d6                	call   *%esi
			num = (unsigned long long)
  80088e:	8b 45 14             	mov    0x14(%ebp),%eax
  800891:	8b 10                	mov    (%eax),%edx
  800893:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800898:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80089b:	8d 40 04             	lea    0x4(%eax),%eax
  80089e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8008a1:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8008a6:	eb 4a                	jmp    8008f2 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8008a8:	83 f9 01             	cmp    $0x1,%ecx
  8008ab:	7e 15                	jle    8008c2 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8008ad:	8b 45 14             	mov    0x14(%ebp),%eax
  8008b0:	8b 10                	mov    (%eax),%edx
  8008b2:	8b 48 04             	mov    0x4(%eax),%ecx
  8008b5:	8d 40 08             	lea    0x8(%eax),%eax
  8008b8:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8008bb:	b8 10 00 00 00       	mov    $0x10,%eax
  8008c0:	eb 30                	jmp    8008f2 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8008c2:	85 c9                	test   %ecx,%ecx
  8008c4:	74 17                	je     8008dd <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8008c6:	8b 45 14             	mov    0x14(%ebp),%eax
  8008c9:	8b 10                	mov    (%eax),%edx
  8008cb:	b9 00 00 00 00       	mov    $0x0,%ecx
  8008d0:	8d 40 04             	lea    0x4(%eax),%eax
  8008d3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8008d6:	b8 10 00 00 00       	mov    $0x10,%eax
  8008db:	eb 15                	jmp    8008f2 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8008dd:	8b 45 14             	mov    0x14(%ebp),%eax
  8008e0:	8b 10                	mov    (%eax),%edx
  8008e2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8008e7:	8d 40 04             	lea    0x4(%eax),%eax
  8008ea:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8008ed:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  8008f2:	83 ec 0c             	sub    $0xc,%esp
  8008f5:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8008f9:	57                   	push   %edi
  8008fa:	ff 75 e0             	pushl  -0x20(%ebp)
  8008fd:	50                   	push   %eax
  8008fe:	51                   	push   %ecx
  8008ff:	52                   	push   %edx
  800900:	89 da                	mov    %ebx,%edx
  800902:	89 f0                	mov    %esi,%eax
  800904:	e8 f1 fa ff ff       	call   8003fa <printnum>
			break;
  800909:	83 c4 20             	add    $0x20,%esp
  80090c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80090f:	e9 f5 fb ff ff       	jmp    800509 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800914:	83 ec 08             	sub    $0x8,%esp
  800917:	53                   	push   %ebx
  800918:	52                   	push   %edx
  800919:	ff d6                	call   *%esi
			break;
  80091b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80091e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800921:	e9 e3 fb ff ff       	jmp    800509 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800926:	83 ec 08             	sub    $0x8,%esp
  800929:	53                   	push   %ebx
  80092a:	6a 25                	push   $0x25
  80092c:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80092e:	83 c4 10             	add    $0x10,%esp
  800931:	eb 03                	jmp    800936 <vprintfmt+0x453>
  800933:	83 ef 01             	sub    $0x1,%edi
  800936:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80093a:	75 f7                	jne    800933 <vprintfmt+0x450>
  80093c:	e9 c8 fb ff ff       	jmp    800509 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800941:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800944:	5b                   	pop    %ebx
  800945:	5e                   	pop    %esi
  800946:	5f                   	pop    %edi
  800947:	5d                   	pop    %ebp
  800948:	c3                   	ret    

00800949 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800949:	55                   	push   %ebp
  80094a:	89 e5                	mov    %esp,%ebp
  80094c:	83 ec 18             	sub    $0x18,%esp
  80094f:	8b 45 08             	mov    0x8(%ebp),%eax
  800952:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800955:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800958:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80095c:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80095f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800966:	85 c0                	test   %eax,%eax
  800968:	74 26                	je     800990 <vsnprintf+0x47>
  80096a:	85 d2                	test   %edx,%edx
  80096c:	7e 22                	jle    800990 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80096e:	ff 75 14             	pushl  0x14(%ebp)
  800971:	ff 75 10             	pushl  0x10(%ebp)
  800974:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800977:	50                   	push   %eax
  800978:	68 a9 04 80 00       	push   $0x8004a9
  80097d:	e8 61 fb ff ff       	call   8004e3 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800982:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800985:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800988:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80098b:	83 c4 10             	add    $0x10,%esp
  80098e:	eb 05                	jmp    800995 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800990:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800995:	c9                   	leave  
  800996:	c3                   	ret    

00800997 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800997:	55                   	push   %ebp
  800998:	89 e5                	mov    %esp,%ebp
  80099a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80099d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8009a0:	50                   	push   %eax
  8009a1:	ff 75 10             	pushl  0x10(%ebp)
  8009a4:	ff 75 0c             	pushl  0xc(%ebp)
  8009a7:	ff 75 08             	pushl  0x8(%ebp)
  8009aa:	e8 9a ff ff ff       	call   800949 <vsnprintf>
	va_end(ap);

	return rc;
}
  8009af:	c9                   	leave  
  8009b0:	c3                   	ret    

008009b1 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8009b1:	55                   	push   %ebp
  8009b2:	89 e5                	mov    %esp,%ebp
  8009b4:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8009b7:	b8 00 00 00 00       	mov    $0x0,%eax
  8009bc:	eb 03                	jmp    8009c1 <strlen+0x10>
		n++;
  8009be:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8009c1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8009c5:	75 f7                	jne    8009be <strlen+0xd>
		n++;
	return n;
}
  8009c7:	5d                   	pop    %ebp
  8009c8:	c3                   	ret    

008009c9 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8009c9:	55                   	push   %ebp
  8009ca:	89 e5                	mov    %esp,%ebp
  8009cc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009cf:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8009d2:	ba 00 00 00 00       	mov    $0x0,%edx
  8009d7:	eb 03                	jmp    8009dc <strnlen+0x13>
		n++;
  8009d9:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8009dc:	39 c2                	cmp    %eax,%edx
  8009de:	74 08                	je     8009e8 <strnlen+0x1f>
  8009e0:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8009e4:	75 f3                	jne    8009d9 <strnlen+0x10>
  8009e6:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8009e8:	5d                   	pop    %ebp
  8009e9:	c3                   	ret    

008009ea <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8009ea:	55                   	push   %ebp
  8009eb:	89 e5                	mov    %esp,%ebp
  8009ed:	53                   	push   %ebx
  8009ee:	8b 45 08             	mov    0x8(%ebp),%eax
  8009f1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8009f4:	89 c2                	mov    %eax,%edx
  8009f6:	83 c2 01             	add    $0x1,%edx
  8009f9:	83 c1 01             	add    $0x1,%ecx
  8009fc:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800a00:	88 5a ff             	mov    %bl,-0x1(%edx)
  800a03:	84 db                	test   %bl,%bl
  800a05:	75 ef                	jne    8009f6 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800a07:	5b                   	pop    %ebx
  800a08:	5d                   	pop    %ebp
  800a09:	c3                   	ret    

00800a0a <strcat>:

char *
strcat(char *dst, const char *src)
{
  800a0a:	55                   	push   %ebp
  800a0b:	89 e5                	mov    %esp,%ebp
  800a0d:	53                   	push   %ebx
  800a0e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800a11:	53                   	push   %ebx
  800a12:	e8 9a ff ff ff       	call   8009b1 <strlen>
  800a17:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800a1a:	ff 75 0c             	pushl  0xc(%ebp)
  800a1d:	01 d8                	add    %ebx,%eax
  800a1f:	50                   	push   %eax
  800a20:	e8 c5 ff ff ff       	call   8009ea <strcpy>
	return dst;
}
  800a25:	89 d8                	mov    %ebx,%eax
  800a27:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800a2a:	c9                   	leave  
  800a2b:	c3                   	ret    

00800a2c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800a2c:	55                   	push   %ebp
  800a2d:	89 e5                	mov    %esp,%ebp
  800a2f:	56                   	push   %esi
  800a30:	53                   	push   %ebx
  800a31:	8b 75 08             	mov    0x8(%ebp),%esi
  800a34:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a37:	89 f3                	mov    %esi,%ebx
  800a39:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a3c:	89 f2                	mov    %esi,%edx
  800a3e:	eb 0f                	jmp    800a4f <strncpy+0x23>
		*dst++ = *src;
  800a40:	83 c2 01             	add    $0x1,%edx
  800a43:	0f b6 01             	movzbl (%ecx),%eax
  800a46:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800a49:	80 39 01             	cmpb   $0x1,(%ecx)
  800a4c:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a4f:	39 da                	cmp    %ebx,%edx
  800a51:	75 ed                	jne    800a40 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800a53:	89 f0                	mov    %esi,%eax
  800a55:	5b                   	pop    %ebx
  800a56:	5e                   	pop    %esi
  800a57:	5d                   	pop    %ebp
  800a58:	c3                   	ret    

00800a59 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800a59:	55                   	push   %ebp
  800a5a:	89 e5                	mov    %esp,%ebp
  800a5c:	56                   	push   %esi
  800a5d:	53                   	push   %ebx
  800a5e:	8b 75 08             	mov    0x8(%ebp),%esi
  800a61:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a64:	8b 55 10             	mov    0x10(%ebp),%edx
  800a67:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800a69:	85 d2                	test   %edx,%edx
  800a6b:	74 21                	je     800a8e <strlcpy+0x35>
  800a6d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800a71:	89 f2                	mov    %esi,%edx
  800a73:	eb 09                	jmp    800a7e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800a75:	83 c2 01             	add    $0x1,%edx
  800a78:	83 c1 01             	add    $0x1,%ecx
  800a7b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800a7e:	39 c2                	cmp    %eax,%edx
  800a80:	74 09                	je     800a8b <strlcpy+0x32>
  800a82:	0f b6 19             	movzbl (%ecx),%ebx
  800a85:	84 db                	test   %bl,%bl
  800a87:	75 ec                	jne    800a75 <strlcpy+0x1c>
  800a89:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800a8b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800a8e:	29 f0                	sub    %esi,%eax
}
  800a90:	5b                   	pop    %ebx
  800a91:	5e                   	pop    %esi
  800a92:	5d                   	pop    %ebp
  800a93:	c3                   	ret    

00800a94 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800a94:	55                   	push   %ebp
  800a95:	89 e5                	mov    %esp,%ebp
  800a97:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a9a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800a9d:	eb 06                	jmp    800aa5 <strcmp+0x11>
		p++, q++;
  800a9f:	83 c1 01             	add    $0x1,%ecx
  800aa2:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800aa5:	0f b6 01             	movzbl (%ecx),%eax
  800aa8:	84 c0                	test   %al,%al
  800aaa:	74 04                	je     800ab0 <strcmp+0x1c>
  800aac:	3a 02                	cmp    (%edx),%al
  800aae:	74 ef                	je     800a9f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800ab0:	0f b6 c0             	movzbl %al,%eax
  800ab3:	0f b6 12             	movzbl (%edx),%edx
  800ab6:	29 d0                	sub    %edx,%eax
}
  800ab8:	5d                   	pop    %ebp
  800ab9:	c3                   	ret    

00800aba <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800aba:	55                   	push   %ebp
  800abb:	89 e5                	mov    %esp,%ebp
  800abd:	53                   	push   %ebx
  800abe:	8b 45 08             	mov    0x8(%ebp),%eax
  800ac1:	8b 55 0c             	mov    0xc(%ebp),%edx
  800ac4:	89 c3                	mov    %eax,%ebx
  800ac6:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800ac9:	eb 06                	jmp    800ad1 <strncmp+0x17>
		n--, p++, q++;
  800acb:	83 c0 01             	add    $0x1,%eax
  800ace:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800ad1:	39 d8                	cmp    %ebx,%eax
  800ad3:	74 15                	je     800aea <strncmp+0x30>
  800ad5:	0f b6 08             	movzbl (%eax),%ecx
  800ad8:	84 c9                	test   %cl,%cl
  800ada:	74 04                	je     800ae0 <strncmp+0x26>
  800adc:	3a 0a                	cmp    (%edx),%cl
  800ade:	74 eb                	je     800acb <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800ae0:	0f b6 00             	movzbl (%eax),%eax
  800ae3:	0f b6 12             	movzbl (%edx),%edx
  800ae6:	29 d0                	sub    %edx,%eax
  800ae8:	eb 05                	jmp    800aef <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800aea:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800aef:	5b                   	pop    %ebx
  800af0:	5d                   	pop    %ebp
  800af1:	c3                   	ret    

00800af2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800af2:	55                   	push   %ebp
  800af3:	89 e5                	mov    %esp,%ebp
  800af5:	8b 45 08             	mov    0x8(%ebp),%eax
  800af8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800afc:	eb 07                	jmp    800b05 <strchr+0x13>
		if (*s == c)
  800afe:	38 ca                	cmp    %cl,%dl
  800b00:	74 0f                	je     800b11 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800b02:	83 c0 01             	add    $0x1,%eax
  800b05:	0f b6 10             	movzbl (%eax),%edx
  800b08:	84 d2                	test   %dl,%dl
  800b0a:	75 f2                	jne    800afe <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800b0c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b11:	5d                   	pop    %ebp
  800b12:	c3                   	ret    

00800b13 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800b13:	55                   	push   %ebp
  800b14:	89 e5                	mov    %esp,%ebp
  800b16:	8b 45 08             	mov    0x8(%ebp),%eax
  800b19:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b1d:	eb 03                	jmp    800b22 <strfind+0xf>
  800b1f:	83 c0 01             	add    $0x1,%eax
  800b22:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800b25:	38 ca                	cmp    %cl,%dl
  800b27:	74 04                	je     800b2d <strfind+0x1a>
  800b29:	84 d2                	test   %dl,%dl
  800b2b:	75 f2                	jne    800b1f <strfind+0xc>
			break;
	return (char *) s;
}
  800b2d:	5d                   	pop    %ebp
  800b2e:	c3                   	ret    

00800b2f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800b2f:	55                   	push   %ebp
  800b30:	89 e5                	mov    %esp,%ebp
  800b32:	57                   	push   %edi
  800b33:	56                   	push   %esi
  800b34:	53                   	push   %ebx
  800b35:	8b 7d 08             	mov    0x8(%ebp),%edi
  800b38:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800b3b:	85 c9                	test   %ecx,%ecx
  800b3d:	74 36                	je     800b75 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800b3f:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b45:	75 28                	jne    800b6f <memset+0x40>
  800b47:	f6 c1 03             	test   $0x3,%cl
  800b4a:	75 23                	jne    800b6f <memset+0x40>
		c &= 0xFF;
  800b4c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b50:	89 d3                	mov    %edx,%ebx
  800b52:	c1 e3 08             	shl    $0x8,%ebx
  800b55:	89 d6                	mov    %edx,%esi
  800b57:	c1 e6 18             	shl    $0x18,%esi
  800b5a:	89 d0                	mov    %edx,%eax
  800b5c:	c1 e0 10             	shl    $0x10,%eax
  800b5f:	09 f0                	or     %esi,%eax
  800b61:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800b63:	89 d8                	mov    %ebx,%eax
  800b65:	09 d0                	or     %edx,%eax
  800b67:	c1 e9 02             	shr    $0x2,%ecx
  800b6a:	fc                   	cld    
  800b6b:	f3 ab                	rep stos %eax,%es:(%edi)
  800b6d:	eb 06                	jmp    800b75 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b6f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b72:	fc                   	cld    
  800b73:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800b75:	89 f8                	mov    %edi,%eax
  800b77:	5b                   	pop    %ebx
  800b78:	5e                   	pop    %esi
  800b79:	5f                   	pop    %edi
  800b7a:	5d                   	pop    %ebp
  800b7b:	c3                   	ret    

00800b7c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b7c:	55                   	push   %ebp
  800b7d:	89 e5                	mov    %esp,%ebp
  800b7f:	57                   	push   %edi
  800b80:	56                   	push   %esi
  800b81:	8b 45 08             	mov    0x8(%ebp),%eax
  800b84:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b87:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b8a:	39 c6                	cmp    %eax,%esi
  800b8c:	73 35                	jae    800bc3 <memmove+0x47>
  800b8e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800b91:	39 d0                	cmp    %edx,%eax
  800b93:	73 2e                	jae    800bc3 <memmove+0x47>
		s += n;
		d += n;
  800b95:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b98:	89 d6                	mov    %edx,%esi
  800b9a:	09 fe                	or     %edi,%esi
  800b9c:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800ba2:	75 13                	jne    800bb7 <memmove+0x3b>
  800ba4:	f6 c1 03             	test   $0x3,%cl
  800ba7:	75 0e                	jne    800bb7 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800ba9:	83 ef 04             	sub    $0x4,%edi
  800bac:	8d 72 fc             	lea    -0x4(%edx),%esi
  800baf:	c1 e9 02             	shr    $0x2,%ecx
  800bb2:	fd                   	std    
  800bb3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bb5:	eb 09                	jmp    800bc0 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800bb7:	83 ef 01             	sub    $0x1,%edi
  800bba:	8d 72 ff             	lea    -0x1(%edx),%esi
  800bbd:	fd                   	std    
  800bbe:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800bc0:	fc                   	cld    
  800bc1:	eb 1d                	jmp    800be0 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800bc3:	89 f2                	mov    %esi,%edx
  800bc5:	09 c2                	or     %eax,%edx
  800bc7:	f6 c2 03             	test   $0x3,%dl
  800bca:	75 0f                	jne    800bdb <memmove+0x5f>
  800bcc:	f6 c1 03             	test   $0x3,%cl
  800bcf:	75 0a                	jne    800bdb <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800bd1:	c1 e9 02             	shr    $0x2,%ecx
  800bd4:	89 c7                	mov    %eax,%edi
  800bd6:	fc                   	cld    
  800bd7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bd9:	eb 05                	jmp    800be0 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800bdb:	89 c7                	mov    %eax,%edi
  800bdd:	fc                   	cld    
  800bde:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800be0:	5e                   	pop    %esi
  800be1:	5f                   	pop    %edi
  800be2:	5d                   	pop    %ebp
  800be3:	c3                   	ret    

00800be4 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800be4:	55                   	push   %ebp
  800be5:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800be7:	ff 75 10             	pushl  0x10(%ebp)
  800bea:	ff 75 0c             	pushl  0xc(%ebp)
  800bed:	ff 75 08             	pushl  0x8(%ebp)
  800bf0:	e8 87 ff ff ff       	call   800b7c <memmove>
}
  800bf5:	c9                   	leave  
  800bf6:	c3                   	ret    

00800bf7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800bf7:	55                   	push   %ebp
  800bf8:	89 e5                	mov    %esp,%ebp
  800bfa:	56                   	push   %esi
  800bfb:	53                   	push   %ebx
  800bfc:	8b 45 08             	mov    0x8(%ebp),%eax
  800bff:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c02:	89 c6                	mov    %eax,%esi
  800c04:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c07:	eb 1a                	jmp    800c23 <memcmp+0x2c>
		if (*s1 != *s2)
  800c09:	0f b6 08             	movzbl (%eax),%ecx
  800c0c:	0f b6 1a             	movzbl (%edx),%ebx
  800c0f:	38 d9                	cmp    %bl,%cl
  800c11:	74 0a                	je     800c1d <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800c13:	0f b6 c1             	movzbl %cl,%eax
  800c16:	0f b6 db             	movzbl %bl,%ebx
  800c19:	29 d8                	sub    %ebx,%eax
  800c1b:	eb 0f                	jmp    800c2c <memcmp+0x35>
		s1++, s2++;
  800c1d:	83 c0 01             	add    $0x1,%eax
  800c20:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c23:	39 f0                	cmp    %esi,%eax
  800c25:	75 e2                	jne    800c09 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c27:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c2c:	5b                   	pop    %ebx
  800c2d:	5e                   	pop    %esi
  800c2e:	5d                   	pop    %ebp
  800c2f:	c3                   	ret    

00800c30 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c30:	55                   	push   %ebp
  800c31:	89 e5                	mov    %esp,%ebp
  800c33:	53                   	push   %ebx
  800c34:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800c37:	89 c1                	mov    %eax,%ecx
  800c39:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800c3c:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c40:	eb 0a                	jmp    800c4c <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c42:	0f b6 10             	movzbl (%eax),%edx
  800c45:	39 da                	cmp    %ebx,%edx
  800c47:	74 07                	je     800c50 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c49:	83 c0 01             	add    $0x1,%eax
  800c4c:	39 c8                	cmp    %ecx,%eax
  800c4e:	72 f2                	jb     800c42 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c50:	5b                   	pop    %ebx
  800c51:	5d                   	pop    %ebp
  800c52:	c3                   	ret    

00800c53 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c53:	55                   	push   %ebp
  800c54:	89 e5                	mov    %esp,%ebp
  800c56:	57                   	push   %edi
  800c57:	56                   	push   %esi
  800c58:	53                   	push   %ebx
  800c59:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c5c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c5f:	eb 03                	jmp    800c64 <strtol+0x11>
		s++;
  800c61:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c64:	0f b6 01             	movzbl (%ecx),%eax
  800c67:	3c 20                	cmp    $0x20,%al
  800c69:	74 f6                	je     800c61 <strtol+0xe>
  800c6b:	3c 09                	cmp    $0x9,%al
  800c6d:	74 f2                	je     800c61 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c6f:	3c 2b                	cmp    $0x2b,%al
  800c71:	75 0a                	jne    800c7d <strtol+0x2a>
		s++;
  800c73:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800c76:	bf 00 00 00 00       	mov    $0x0,%edi
  800c7b:	eb 11                	jmp    800c8e <strtol+0x3b>
  800c7d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800c82:	3c 2d                	cmp    $0x2d,%al
  800c84:	75 08                	jne    800c8e <strtol+0x3b>
		s++, neg = 1;
  800c86:	83 c1 01             	add    $0x1,%ecx
  800c89:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800c8e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800c94:	75 15                	jne    800cab <strtol+0x58>
  800c96:	80 39 30             	cmpb   $0x30,(%ecx)
  800c99:	75 10                	jne    800cab <strtol+0x58>
  800c9b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800c9f:	75 7c                	jne    800d1d <strtol+0xca>
		s += 2, base = 16;
  800ca1:	83 c1 02             	add    $0x2,%ecx
  800ca4:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ca9:	eb 16                	jmp    800cc1 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800cab:	85 db                	test   %ebx,%ebx
  800cad:	75 12                	jne    800cc1 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800caf:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800cb4:	80 39 30             	cmpb   $0x30,(%ecx)
  800cb7:	75 08                	jne    800cc1 <strtol+0x6e>
		s++, base = 8;
  800cb9:	83 c1 01             	add    $0x1,%ecx
  800cbc:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800cc1:	b8 00 00 00 00       	mov    $0x0,%eax
  800cc6:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800cc9:	0f b6 11             	movzbl (%ecx),%edx
  800ccc:	8d 72 d0             	lea    -0x30(%edx),%esi
  800ccf:	89 f3                	mov    %esi,%ebx
  800cd1:	80 fb 09             	cmp    $0x9,%bl
  800cd4:	77 08                	ja     800cde <strtol+0x8b>
			dig = *s - '0';
  800cd6:	0f be d2             	movsbl %dl,%edx
  800cd9:	83 ea 30             	sub    $0x30,%edx
  800cdc:	eb 22                	jmp    800d00 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800cde:	8d 72 9f             	lea    -0x61(%edx),%esi
  800ce1:	89 f3                	mov    %esi,%ebx
  800ce3:	80 fb 19             	cmp    $0x19,%bl
  800ce6:	77 08                	ja     800cf0 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800ce8:	0f be d2             	movsbl %dl,%edx
  800ceb:	83 ea 57             	sub    $0x57,%edx
  800cee:	eb 10                	jmp    800d00 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800cf0:	8d 72 bf             	lea    -0x41(%edx),%esi
  800cf3:	89 f3                	mov    %esi,%ebx
  800cf5:	80 fb 19             	cmp    $0x19,%bl
  800cf8:	77 16                	ja     800d10 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800cfa:	0f be d2             	movsbl %dl,%edx
  800cfd:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800d00:	3b 55 10             	cmp    0x10(%ebp),%edx
  800d03:	7d 0b                	jge    800d10 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800d05:	83 c1 01             	add    $0x1,%ecx
  800d08:	0f af 45 10          	imul   0x10(%ebp),%eax
  800d0c:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800d0e:	eb b9                	jmp    800cc9 <strtol+0x76>

	if (endptr)
  800d10:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d14:	74 0d                	je     800d23 <strtol+0xd0>
		*endptr = (char *) s;
  800d16:	8b 75 0c             	mov    0xc(%ebp),%esi
  800d19:	89 0e                	mov    %ecx,(%esi)
  800d1b:	eb 06                	jmp    800d23 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800d1d:	85 db                	test   %ebx,%ebx
  800d1f:	74 98                	je     800cb9 <strtol+0x66>
  800d21:	eb 9e                	jmp    800cc1 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800d23:	89 c2                	mov    %eax,%edx
  800d25:	f7 da                	neg    %edx
  800d27:	85 ff                	test   %edi,%edi
  800d29:	0f 45 c2             	cmovne %edx,%eax
}
  800d2c:	5b                   	pop    %ebx
  800d2d:	5e                   	pop    %esi
  800d2e:	5f                   	pop    %edi
  800d2f:	5d                   	pop    %ebp
  800d30:	c3                   	ret    
  800d31:	66 90                	xchg   %ax,%ax
  800d33:	66 90                	xchg   %ax,%ax
  800d35:	66 90                	xchg   %ax,%ax
  800d37:	66 90                	xchg   %ax,%ax
  800d39:	66 90                	xchg   %ax,%ax
  800d3b:	66 90                	xchg   %ax,%ax
  800d3d:	66 90                	xchg   %ax,%ax
  800d3f:	90                   	nop

00800d40 <__udivdi3>:
  800d40:	55                   	push   %ebp
  800d41:	57                   	push   %edi
  800d42:	56                   	push   %esi
  800d43:	53                   	push   %ebx
  800d44:	83 ec 1c             	sub    $0x1c,%esp
  800d47:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800d4b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800d4f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800d53:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d57:	85 f6                	test   %esi,%esi
  800d59:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d5d:	89 ca                	mov    %ecx,%edx
  800d5f:	89 f8                	mov    %edi,%eax
  800d61:	75 3d                	jne    800da0 <__udivdi3+0x60>
  800d63:	39 cf                	cmp    %ecx,%edi
  800d65:	0f 87 c5 00 00 00    	ja     800e30 <__udivdi3+0xf0>
  800d6b:	85 ff                	test   %edi,%edi
  800d6d:	89 fd                	mov    %edi,%ebp
  800d6f:	75 0b                	jne    800d7c <__udivdi3+0x3c>
  800d71:	b8 01 00 00 00       	mov    $0x1,%eax
  800d76:	31 d2                	xor    %edx,%edx
  800d78:	f7 f7                	div    %edi
  800d7a:	89 c5                	mov    %eax,%ebp
  800d7c:	89 c8                	mov    %ecx,%eax
  800d7e:	31 d2                	xor    %edx,%edx
  800d80:	f7 f5                	div    %ebp
  800d82:	89 c1                	mov    %eax,%ecx
  800d84:	89 d8                	mov    %ebx,%eax
  800d86:	89 cf                	mov    %ecx,%edi
  800d88:	f7 f5                	div    %ebp
  800d8a:	89 c3                	mov    %eax,%ebx
  800d8c:	89 d8                	mov    %ebx,%eax
  800d8e:	89 fa                	mov    %edi,%edx
  800d90:	83 c4 1c             	add    $0x1c,%esp
  800d93:	5b                   	pop    %ebx
  800d94:	5e                   	pop    %esi
  800d95:	5f                   	pop    %edi
  800d96:	5d                   	pop    %ebp
  800d97:	c3                   	ret    
  800d98:	90                   	nop
  800d99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800da0:	39 ce                	cmp    %ecx,%esi
  800da2:	77 74                	ja     800e18 <__udivdi3+0xd8>
  800da4:	0f bd fe             	bsr    %esi,%edi
  800da7:	83 f7 1f             	xor    $0x1f,%edi
  800daa:	0f 84 98 00 00 00    	je     800e48 <__udivdi3+0x108>
  800db0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800db5:	89 f9                	mov    %edi,%ecx
  800db7:	89 c5                	mov    %eax,%ebp
  800db9:	29 fb                	sub    %edi,%ebx
  800dbb:	d3 e6                	shl    %cl,%esi
  800dbd:	89 d9                	mov    %ebx,%ecx
  800dbf:	d3 ed                	shr    %cl,%ebp
  800dc1:	89 f9                	mov    %edi,%ecx
  800dc3:	d3 e0                	shl    %cl,%eax
  800dc5:	09 ee                	or     %ebp,%esi
  800dc7:	89 d9                	mov    %ebx,%ecx
  800dc9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800dcd:	89 d5                	mov    %edx,%ebp
  800dcf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800dd3:	d3 ed                	shr    %cl,%ebp
  800dd5:	89 f9                	mov    %edi,%ecx
  800dd7:	d3 e2                	shl    %cl,%edx
  800dd9:	89 d9                	mov    %ebx,%ecx
  800ddb:	d3 e8                	shr    %cl,%eax
  800ddd:	09 c2                	or     %eax,%edx
  800ddf:	89 d0                	mov    %edx,%eax
  800de1:	89 ea                	mov    %ebp,%edx
  800de3:	f7 f6                	div    %esi
  800de5:	89 d5                	mov    %edx,%ebp
  800de7:	89 c3                	mov    %eax,%ebx
  800de9:	f7 64 24 0c          	mull   0xc(%esp)
  800ded:	39 d5                	cmp    %edx,%ebp
  800def:	72 10                	jb     800e01 <__udivdi3+0xc1>
  800df1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800df5:	89 f9                	mov    %edi,%ecx
  800df7:	d3 e6                	shl    %cl,%esi
  800df9:	39 c6                	cmp    %eax,%esi
  800dfb:	73 07                	jae    800e04 <__udivdi3+0xc4>
  800dfd:	39 d5                	cmp    %edx,%ebp
  800dff:	75 03                	jne    800e04 <__udivdi3+0xc4>
  800e01:	83 eb 01             	sub    $0x1,%ebx
  800e04:	31 ff                	xor    %edi,%edi
  800e06:	89 d8                	mov    %ebx,%eax
  800e08:	89 fa                	mov    %edi,%edx
  800e0a:	83 c4 1c             	add    $0x1c,%esp
  800e0d:	5b                   	pop    %ebx
  800e0e:	5e                   	pop    %esi
  800e0f:	5f                   	pop    %edi
  800e10:	5d                   	pop    %ebp
  800e11:	c3                   	ret    
  800e12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e18:	31 ff                	xor    %edi,%edi
  800e1a:	31 db                	xor    %ebx,%ebx
  800e1c:	89 d8                	mov    %ebx,%eax
  800e1e:	89 fa                	mov    %edi,%edx
  800e20:	83 c4 1c             	add    $0x1c,%esp
  800e23:	5b                   	pop    %ebx
  800e24:	5e                   	pop    %esi
  800e25:	5f                   	pop    %edi
  800e26:	5d                   	pop    %ebp
  800e27:	c3                   	ret    
  800e28:	90                   	nop
  800e29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e30:	89 d8                	mov    %ebx,%eax
  800e32:	f7 f7                	div    %edi
  800e34:	31 ff                	xor    %edi,%edi
  800e36:	89 c3                	mov    %eax,%ebx
  800e38:	89 d8                	mov    %ebx,%eax
  800e3a:	89 fa                	mov    %edi,%edx
  800e3c:	83 c4 1c             	add    $0x1c,%esp
  800e3f:	5b                   	pop    %ebx
  800e40:	5e                   	pop    %esi
  800e41:	5f                   	pop    %edi
  800e42:	5d                   	pop    %ebp
  800e43:	c3                   	ret    
  800e44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e48:	39 ce                	cmp    %ecx,%esi
  800e4a:	72 0c                	jb     800e58 <__udivdi3+0x118>
  800e4c:	31 db                	xor    %ebx,%ebx
  800e4e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800e52:	0f 87 34 ff ff ff    	ja     800d8c <__udivdi3+0x4c>
  800e58:	bb 01 00 00 00       	mov    $0x1,%ebx
  800e5d:	e9 2a ff ff ff       	jmp    800d8c <__udivdi3+0x4c>
  800e62:	66 90                	xchg   %ax,%ax
  800e64:	66 90                	xchg   %ax,%ax
  800e66:	66 90                	xchg   %ax,%ax
  800e68:	66 90                	xchg   %ax,%ax
  800e6a:	66 90                	xchg   %ax,%ax
  800e6c:	66 90                	xchg   %ax,%ax
  800e6e:	66 90                	xchg   %ax,%ax

00800e70 <__umoddi3>:
  800e70:	55                   	push   %ebp
  800e71:	57                   	push   %edi
  800e72:	56                   	push   %esi
  800e73:	53                   	push   %ebx
  800e74:	83 ec 1c             	sub    $0x1c,%esp
  800e77:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800e7b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800e7f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800e83:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800e87:	85 d2                	test   %edx,%edx
  800e89:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800e8d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e91:	89 f3                	mov    %esi,%ebx
  800e93:	89 3c 24             	mov    %edi,(%esp)
  800e96:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e9a:	75 1c                	jne    800eb8 <__umoddi3+0x48>
  800e9c:	39 f7                	cmp    %esi,%edi
  800e9e:	76 50                	jbe    800ef0 <__umoddi3+0x80>
  800ea0:	89 c8                	mov    %ecx,%eax
  800ea2:	89 f2                	mov    %esi,%edx
  800ea4:	f7 f7                	div    %edi
  800ea6:	89 d0                	mov    %edx,%eax
  800ea8:	31 d2                	xor    %edx,%edx
  800eaa:	83 c4 1c             	add    $0x1c,%esp
  800ead:	5b                   	pop    %ebx
  800eae:	5e                   	pop    %esi
  800eaf:	5f                   	pop    %edi
  800eb0:	5d                   	pop    %ebp
  800eb1:	c3                   	ret    
  800eb2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800eb8:	39 f2                	cmp    %esi,%edx
  800eba:	89 d0                	mov    %edx,%eax
  800ebc:	77 52                	ja     800f10 <__umoddi3+0xa0>
  800ebe:	0f bd ea             	bsr    %edx,%ebp
  800ec1:	83 f5 1f             	xor    $0x1f,%ebp
  800ec4:	75 5a                	jne    800f20 <__umoddi3+0xb0>
  800ec6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800eca:	0f 82 e0 00 00 00    	jb     800fb0 <__umoddi3+0x140>
  800ed0:	39 0c 24             	cmp    %ecx,(%esp)
  800ed3:	0f 86 d7 00 00 00    	jbe    800fb0 <__umoddi3+0x140>
  800ed9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800edd:	8b 54 24 04          	mov    0x4(%esp),%edx
  800ee1:	83 c4 1c             	add    $0x1c,%esp
  800ee4:	5b                   	pop    %ebx
  800ee5:	5e                   	pop    %esi
  800ee6:	5f                   	pop    %edi
  800ee7:	5d                   	pop    %ebp
  800ee8:	c3                   	ret    
  800ee9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ef0:	85 ff                	test   %edi,%edi
  800ef2:	89 fd                	mov    %edi,%ebp
  800ef4:	75 0b                	jne    800f01 <__umoddi3+0x91>
  800ef6:	b8 01 00 00 00       	mov    $0x1,%eax
  800efb:	31 d2                	xor    %edx,%edx
  800efd:	f7 f7                	div    %edi
  800eff:	89 c5                	mov    %eax,%ebp
  800f01:	89 f0                	mov    %esi,%eax
  800f03:	31 d2                	xor    %edx,%edx
  800f05:	f7 f5                	div    %ebp
  800f07:	89 c8                	mov    %ecx,%eax
  800f09:	f7 f5                	div    %ebp
  800f0b:	89 d0                	mov    %edx,%eax
  800f0d:	eb 99                	jmp    800ea8 <__umoddi3+0x38>
  800f0f:	90                   	nop
  800f10:	89 c8                	mov    %ecx,%eax
  800f12:	89 f2                	mov    %esi,%edx
  800f14:	83 c4 1c             	add    $0x1c,%esp
  800f17:	5b                   	pop    %ebx
  800f18:	5e                   	pop    %esi
  800f19:	5f                   	pop    %edi
  800f1a:	5d                   	pop    %ebp
  800f1b:	c3                   	ret    
  800f1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f20:	8b 34 24             	mov    (%esp),%esi
  800f23:	bf 20 00 00 00       	mov    $0x20,%edi
  800f28:	89 e9                	mov    %ebp,%ecx
  800f2a:	29 ef                	sub    %ebp,%edi
  800f2c:	d3 e0                	shl    %cl,%eax
  800f2e:	89 f9                	mov    %edi,%ecx
  800f30:	89 f2                	mov    %esi,%edx
  800f32:	d3 ea                	shr    %cl,%edx
  800f34:	89 e9                	mov    %ebp,%ecx
  800f36:	09 c2                	or     %eax,%edx
  800f38:	89 d8                	mov    %ebx,%eax
  800f3a:	89 14 24             	mov    %edx,(%esp)
  800f3d:	89 f2                	mov    %esi,%edx
  800f3f:	d3 e2                	shl    %cl,%edx
  800f41:	89 f9                	mov    %edi,%ecx
  800f43:	89 54 24 04          	mov    %edx,0x4(%esp)
  800f47:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800f4b:	d3 e8                	shr    %cl,%eax
  800f4d:	89 e9                	mov    %ebp,%ecx
  800f4f:	89 c6                	mov    %eax,%esi
  800f51:	d3 e3                	shl    %cl,%ebx
  800f53:	89 f9                	mov    %edi,%ecx
  800f55:	89 d0                	mov    %edx,%eax
  800f57:	d3 e8                	shr    %cl,%eax
  800f59:	89 e9                	mov    %ebp,%ecx
  800f5b:	09 d8                	or     %ebx,%eax
  800f5d:	89 d3                	mov    %edx,%ebx
  800f5f:	89 f2                	mov    %esi,%edx
  800f61:	f7 34 24             	divl   (%esp)
  800f64:	89 d6                	mov    %edx,%esi
  800f66:	d3 e3                	shl    %cl,%ebx
  800f68:	f7 64 24 04          	mull   0x4(%esp)
  800f6c:	39 d6                	cmp    %edx,%esi
  800f6e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800f72:	89 d1                	mov    %edx,%ecx
  800f74:	89 c3                	mov    %eax,%ebx
  800f76:	72 08                	jb     800f80 <__umoddi3+0x110>
  800f78:	75 11                	jne    800f8b <__umoddi3+0x11b>
  800f7a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800f7e:	73 0b                	jae    800f8b <__umoddi3+0x11b>
  800f80:	2b 44 24 04          	sub    0x4(%esp),%eax
  800f84:	1b 14 24             	sbb    (%esp),%edx
  800f87:	89 d1                	mov    %edx,%ecx
  800f89:	89 c3                	mov    %eax,%ebx
  800f8b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800f8f:	29 da                	sub    %ebx,%edx
  800f91:	19 ce                	sbb    %ecx,%esi
  800f93:	89 f9                	mov    %edi,%ecx
  800f95:	89 f0                	mov    %esi,%eax
  800f97:	d3 e0                	shl    %cl,%eax
  800f99:	89 e9                	mov    %ebp,%ecx
  800f9b:	d3 ea                	shr    %cl,%edx
  800f9d:	89 e9                	mov    %ebp,%ecx
  800f9f:	d3 ee                	shr    %cl,%esi
  800fa1:	09 d0                	or     %edx,%eax
  800fa3:	89 f2                	mov    %esi,%edx
  800fa5:	83 c4 1c             	add    $0x1c,%esp
  800fa8:	5b                   	pop    %ebx
  800fa9:	5e                   	pop    %esi
  800faa:	5f                   	pop    %edi
  800fab:	5d                   	pop    %ebp
  800fac:	c3                   	ret    
  800fad:	8d 76 00             	lea    0x0(%esi),%esi
  800fb0:	29 f9                	sub    %edi,%ecx
  800fb2:	19 d6                	sbb    %edx,%esi
  800fb4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800fb8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800fbc:	e9 18 ff ff ff       	jmp    800ed9 <__umoddi3+0x69>
