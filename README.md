# OS Lab2 实验报告

一、	实验准备

本次试验在Lab1基础上进行操作，在了解了内存管理的机制后，对本次试验进行了多次尝试，并结合网上内容，最终完成实验。

二、	实验过程

练习1:

在更改函数以前，我们先了解到，最重要的函数是mem_init()，作为整个内存管理的初始化函数，在内核刚开始运行时就会调用。
进入该函数后，先检测现在系统可用空间，我们知道JOS把物理内存分为了三个部分：
一个是从0x00000～0xA0000，这部分叫做basemem，是可以使用的；
紧接着是0xA0000～0x10000，这部分叫做IO hole，是不可以使用的，用来分配给外部设备；
最后就是0x10000，这部分叫做extmem，是可以使用的，这是最重要的内存区域。

随后进行调用boot_alloc()函数，并将返回值赋值给指向操作系统的页目录表的指针。

boot_alloc(uint32_t n):
对于该函数，通过阅读函数上方的注释，可以得知该函数只是在JOS设置其虚拟内存系统时用这个简单的物理内存分布器。已经给出了第一次调用该函数是语句，所以，只需要模仿，将存放着下一个可以使用的空闲内存空间的虚拟地址nextfree并在每次分配n字节的内存时候，更改这个变量的值。所以代码如下：
 
men_init(void):
随后，我们看下面的代码：
kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
这一条指令就是为页目录表添加第一个页目录表项，存放的就是操作系统的页表kern_pgdir，，并通过PADDR计算kern_pgdir所对应的真实物理地址。

下一条代码，需要我们添加，这条命令要完成的是分配一块内存，用来存放一个数组，数组每一个PageInfo代表内存中的一页，并通过这个数组来追踪所有内存页的使用情况。代码如下：
 
page_init(void):
随后，继续运行到下一个函数，page_init()，这个函数的功能由注释可知是初始化pages数组和pages_free_list链表，存放了所有空闲页的信息。并对pages初始化有了4个要求，为了实现这些要求，我们添加如下代码：
 
因为page 0是被使用的，所以从1到npages_basemem进行初始化ref为0，随后跳过IO hole部分，剩下的部分也进行初始化，所以分为两个循环进行初始化。

初始化关于所有物理内存页的相关数据结构后，进入check_page_free_list(1)函数，该函数检查page_free_list空闲页是否合法、空闲。随后又通过check_page_alloc(),检查page_alloc()，page_free()是否可以运行。
所以我们对这两个函数进行更改。
page_alloc(int alloc_flags):
关于该函数，注释告诉我们可以知道这个函数的功能是分配一个物理页，并返回这个物理页所对应的PageIndo结构体。
所以，该函数先从free_page_list中取出一个空闲页的PageInfo结构体，然后修改free_page_list的信息，然后取出空闲页PageInfo结构体信息，初始化该页的内存。代码如下：
 

page_free(struct PageInfo *pp):
根据注释，该函数就是把一个页的PageInfo结构体在返回给page_free_list空闲页链表，代表回收了这个页，通过完成以下几个步骤，修改回收的页PageIndo结构体的相应消息，把该结构体插入回page_free_list空闲链表中。代码如下：
 
练习2:

已经详细了解需要参考的知识。

练习3: 

可以发现，两种方式并没有什么区别，只是了解虚拟地址和物理地址的区别。

问题1:

假设以下 JOS 内核代码是正确的，变量 x 应该是什么类型？uintptr_t 还是 physaddr_t？
mystery_t x;
char * value = return_a_pointer（）;
* value = 10;
x =（mystery_t）value;
因为这里是用了*进行解析地址，所以x应该是uintptr_t类型。

练习4:

pgdir_walk():
根据阅读注释，我们可知，该函数功能是：给定一个页目录指针pgdir，该函数应该返回线性地址va所对应的页表项指针，并且根据参数create判断是否需要创建新的页表页。首先我们通过页目录表求的虚拟地址所在的页表页对于页目录项地址dic_entry_ptr，随后判断这个页目录对应的页表页是否在内存中，有过在，那么计算其基地址page_base，并且返回所对应页表项的地址&page_base[page_off]，如果不在，那么判断是否需要create，如果需要，那么就把这个页的信息添加到页目录里。代码如下：
 

boot_map_region():
该函数是为了把虚拟地址范围[va,va+size)映射到[pa,pa+size)的映射关系加入到页表中去，但只一部分的地址映射是静态的，并不会改变pp_ref的值，所以该函数只需要，在一个循环中，逐一进行映射即可，代码如下：
 
page_lookup():
该函数的功能为：返回虚拟地址va所映射的物理页PageInfo结构体的指针，如果pte_store参数不为0，则把这个物理页的页表项地址存放在pte_store中。我们只需要调用pgdir_walk函数获取这个va对应的页表项，然后判断这个页是否已经存在内存，如果在则返回这个页的PageInfo结构体指针，并存放到pte_store中，代码如下：
 

page_remove():
该函数功能就是删除虚拟地址va和物理页映射关系，并且需要减少物理页上的引用计数，如果已经减少到0，则应该是放物理页面没这个页对应的页表项应该被被置为0.代码如下：
 

page_insert():
该函数的目的是将物理页面pp映射到虚拟地址va，并且对于如果已有映射到va的页面，需要通过page_remove()进行删除，插入成功，更改pp_ref，如果页面以前为va，则TLB必须无效，对与TLB相关，需要参考网上相关知识，并对随后的代码都有了帮助。
TLB：处理器使用TLB（Translation Lookaside Buffer）来缓存线性地址到物理地址的映射关系。因此在世纪城的地址转换过程中，处理器首先更具线性地址查找TLB，如果未发现该线性地址到物理地址的映射关系（TLB miss），将根据页表中的映射关系填充TLB（TLB fill），然后进行地址转换。对于我们即将使用的tlb_invalidate(pde_t *pgdir, void *va)函数，目的就是取消va与物理页之间的关联，相当于刷新TLB，每次我们调整虚拟页和物理页之间映射关系的时候，都需要刷新TLB，调用这个函数。
所以对于insert函数的实现，主要通过pgdir_walk函数求出虚拟地址va所对应的页表项，并且修改pp_red的值，通过查看这个页表项，确定va是否已经被映射，如果被映射，则删除这个映射，把va和pp之间的映射关系加入到页表项，代码如下：
 

练习5:

映射UPAGES，KSTACK，KERNBASE等虚拟地址到物理内存。
mem_init():
有三个部分需要我们填充：
1、	要求是：Map 'pages' read-only by the user at linear address UPAGES，所以调用函数boot_map_region实现：
 
2、	要求是：kernek RW，user NONE，所以代码如下：
 
3、	要求是：kernel RW，user NONE，代码如下：
 
问题2:

大致制作了一个表：
1023	0xffc00000	Page table for top 4MB of phys memory
...	...	...
960	0xf0000000	Page table for bottom of phys memory
959	0xefc00000	
958	0xef800000	ULIM
957	0xef400000	UVPT
956	0xef000000	UPAGES
955	0xeec00000	UPOP
...	...	..
0	0x00000000	Empty memory

问题3：

因为页表可以设置权限，如果没有将PTE_U置为1，就可以使用户无权限读写。

问题4:

因为每个PageInfo占用8Byte，而UPAGES最大是4MB，所以总共最多可以有4MNB/8B=512K页，每页的容量是4KB，所以总共可以有512k*4KB=2GB。

问题5:

如果有2GB内存，就需要有512个物理页，每个PageInfo结构占用8Byte，所以是4MB。页目录需要512*8=4KB，此外还需要512k个页表项，所以还需要4MB存储，所以共消耗6MB+4KB。

问题6:

从jmp *%eax开始跳转，因为在entry.S中加载的事entry_pgdir，他将虚拟地址[0,4M)和[KERNBASE,KERNBASE+4M)都映射到了物理地址[0,4M)，而在新的kern_ogdir加载后，并没有映射地位的虚拟地址[0,4M)，所以是必要的。

挑战1:

上网寻找了一个解决方案是，通过注释掉先前的KERNBASE以上的boot_map_region()，由于需要要使用PDE的PS位，所以通过CR4的PSE位，然后每个PDE表项对应4MB内存，所以就不需要分配二级页表原本4KB的页面大小，所以本来需要64个PDE表项和64*1024个PTE表项，也就是大约256KB，现在4MB的页面大小，需要64个PDE表项，也就是256B。代码如下：
 
并且注释掉check_kern_pgdir()，防止检查二级目录，结果如下：
 

挑战2:

参考网上代码，增添了showmappings的函数，在kern/monitor中增添指令，并且添加了如下代码：
1.	int  
2.	mon_showmappings(int args, char **argv, struct Trapframe *tf)  
3.	{  
4.	    char flag[1 << 8] = {  
5.	        [0] = '-',  
6.	        [PTE_W] = 'W',  
7.	        [PTE_U] = 'U',  
8.	        [PTE_A] = 'A',  
9.	        [PTE_D] = 'D',  
10.	        [PTE_PS] = 'S'  
11.	    };  
12.	  
13.	    char *arg1 = argv[1];  
14.	    char *arg2 = argv[2];  
15.	    char *arg3 = argv[3];  
16.	    char *endptr;  
17.	    if (arg1 == NULL || arg2 == NULL || arg3) {  
18.	        cprintf("we need exactly two arguments!\n");  
19.	        return 0;  
20.	    }  
21.	    uintptr_t va_l = strtol(arg1, &endptr, 16);  
22.	    if (*endptr) {  
23.	        cprintf("argument's format error!\n");  
24.	        return 0;  
25.	    }  
26.	    uintptr_t va_r = strtol(arg2, &endptr, 16);  
27.	    if (*endptr) {  
28.	        cprintf("argument's format error!\n");  
29.	        return 0;  
30.	    }  
31.	    if (va_l > va_r) {  
32.	        cprintf("the first argument should not larger than the second argument!\n");  
33.	        return 0;  
34.	    }  
35.	  
36.	    pde_t *pgdir = (pde_t *) PGADDR(PDX(UVPT), PDX(UVPT), 0);   // 这里直接用 kern_pgdir 也可以  
37.	    cprintf("      va range         entry      flag           pa range      \n");  
38.	    cprintf("---------------------------------------------------------------\n");  
39.	    while (va_l <= va_r) {  
40.	        pde_t pde = pgdir[PDX(va_l)];  
41.	        if (pde & PTE_P) {  
42.	            char bit_w = flag[pde & PTE_W];  
43.	            char bit_u = flag[pde & PTE_U];  
44.	            char bit_a = flag[pde & PTE_A];  
45.	            char bit_d = flag[pde & PTE_D];  
46.	            char bit_s = flag[pde & PTE_PS];  
47.	            pde = PTE_ADDR(pde);  
48.	            if (va_l < KERNBASE) {  
49.	                cprintf("[%08x - %08x]", va_l, va_l + PTSIZE - 1);  
50.	                cprintf(" PDE[%03x] --%c%c%c--%c%cP\n", PDX(va_l), bit_s, bit_d, bit_a, bit_u, bit_w);  
51.	                pte_t *pte = (pte_t *) (pde + KERNBASE);  
52.	        size_t i;  
53.	                for (i = 0; i != 1024 && va_l <= va_r; va_l += PGSIZE, ++i) {  
54.	                    if (pte[i] & PTE_P) {  
55.	                        bit_w = flag[pte[i] & PTE_W];  
56.	                        bit_u = flag[pte[i] & PTE_U];  
57.	                        bit_a = flag[pte[i] & PTE_A];  
58.	                        bit_d = flag[pte[i] & PTE_D];  
59.	                        bit_s = flag[pte[i] & PTE_PS];  
60.	                        cprintf(" |-[%08x - %08x]", va_l, va_l + PGSIZE - 1);     
61.	                        cprintf(" PTE[%03x] --%c%c%c--%c%cP", i, bit_s, bit_d, bit_a, bit_u, bit_w);  
62.	                        cprintf(" [%08x - %08x]\n", PTE_ADDR(pte[i]), PTE_ADDR(pte[i]) + PGSIZE - 1);             
63.	                    }  
64.	                }  
65.	                continue;  
66.	            }  
67.	            cprintf("[%08x - %08x]", va_l, va_l + PTSIZE - 1, PDX(va_l));  
68.	            cprintf(" PDE[%03x] --%c%c%c--%c%cP", PDX(va_l), bit_s, bit_d, bit_a, bit_u, bit_w);  
69.	            cprintf(" [%08x - %08x]\n", pde, pde + PTSIZE - 1);  
70.	            if (va_l == 0xffc00000) {  
71.	                break;  
72.	            }  
73.	        }  
74.	        va_l += PTSIZE;  
75.	    }  
76.	    return 0;  
77.	}  
最后成功在qemu中调用了showmappings指令，结果如下：
 
三、	实验结果

最后通过make grade完成全部实验，结果如下：
 
通过本次试验加深了对内存管理的理解。也明白了，原来不能再for循环的要求里定义新的变量，而要先定义变量，再写循环。
