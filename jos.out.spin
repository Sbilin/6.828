+ ld obj/kern/kernel
+ mk obj/kern/kernel.img
6828 decimal is XXX octal!
Physical memory: 131072K available, base = 640K, extended = 130432K
check_page_free_list() succeeded!
check_page_alloc() succeeded!
check_page() succeeded!
check_kern_pgdir() succeeded!
check_page_free_list() succeeded!
check_page_installed_pgdir() succeeded!
bda   f0000400
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
[00000000] new env 00001000
I am the parent.  Forking the child...
[00001000] new env 00001001
-0
eebfdf78:in the pg
done
I am the parent.  Running the child...
-0
eebfdf8c:in the pg
-0
00802004:in the pg
I am the child.  Spinning...
qemu: terminating on signal 15 from pid 13690
