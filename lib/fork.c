// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;
	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if((err&FEC_WR)==0||(uvpt[PGNUM(addr)]&PTE_COW)==0)
		panic("pgfault:It's not a write or non-COW page\n"); 
	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	uint32_t envid=sys_getenvid();
	if((r=sys_page_alloc(envid,PFTEMP,PTE_P|PTE_U|PTE_W))<0)
		panic("pgfault: error in PFTEMP\n");
	addr=ROUNDDOWN(addr,PGSIZE);
	memmove(PFTEMP,addr,PGSIZE); 
	if((r=sys_page_unmap(envid,addr))<0)
		panic("pgfault:unmap\n");
	if((r=sys_page_map(envid,PFTEMP,envid,addr,PTE_P|PTE_U|PTE_W))<0)
		panic("pgfault:map\n");
	if((r=sys_page_unmap(envid,PFTEMP))<0)
		panic("pgfault:unmap PFTEMP\n");
	//panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	uint32_t fenvid=sys_getenvid();
	int perm=PTE_P|PTE_U;
	// LAB 4: Your code here.
	uint32_t addr=pn*PGSIZE;
	if((uvpt[pn]&PTE_W)>0||(uvpt[pn]&PTE_COW)>0)
	{
		perm=perm|PTE_COW;

		if((r=sys_page_map(fenvid,(void *)addr,envid,(void *)addr,perm))<0)
			panic("duppage: sys_page_map error 1\n");
		if((r=sys_page_map(fenvid,(void *)addr,fenvid,(void *)addr,perm))<0)
			panic("duppage: sys_page_map error 2\n");
	}
	else
	{
		if((r=sys_page_map(fenvid,(void *)addr,envid,(void *)addr,perm))<0)
			panic("duppage: sys_page_map error 3\n"); 
	}	
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	set_pgfault_handler(pgfault);
	envid_t envid=sys_exofork();
	uint32_t addr;
	uint32_t fenvid=sys_getenvid();
	if(envid<0)
		panic("fork not implemented");
	else if(envid==0)
	{
		thisenv=&envs[ENVX(fenvid)];
		return 0;
	}
	for(addr=UTEXT;addr<USTACKTOP;addr+=PGSIZE)
	{
		if(((uvpd[PDX(addr)]&PTE_P)>0)&&((uvpt[PGNUM(addr)]&PTE_P)>0))
		{
			duppage(envid,PGNUM(addr));
	
		}
	}
	if(sys_page_alloc(envid,(void *)(UXSTACKTOP-PGSIZE),PTE_P|PTE_U|PTE_W)<0)
		panic("fork: page alloc\n");
	extern void _pgfault_upcall(void);
	if((sys_env_set_pgfault_upcall(envid, _pgfault_upcall))<0)
		panic("fork:set pgfault upcall\n");
	if((sys_env_set_status(envid,ENV_RUNNABLE))<0)
		panic("fork:set status\n");
	return envid;
		
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
