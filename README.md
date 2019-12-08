# OS Lab3 实验报告

一、	实验准备

本次试验在Lab2基础上进行操作，在了解了用户进程相关知识后，对本次试验进行多次尝试，并结合网上内容，完成本次试验。
在实验准备阶段，不知道什么原因，在monitor.c和pmap.c中出现了很多head以及<<<<<之类的乱码，在随后百度过程中，可以得知，原来是本地代码与下拉代码差异所导致的，由于lab2做了一些挑战题，更改了部分本不需要更改的代码，具体结构如下图：
 
二、	实验过程

PART A

练习1:

首先，我们打开kern/pmap.c重的mem_init()，发现有一段注释写着：
LAB 3: Your code here.
要求是新建一个envs指针指向一个范围是NENV存放Env的数组，所以代码如下：
 
随后分配内存，要求envs数组要求用户只可读，根据lab2对于内存分配的知识可以写出如下代码：
 

练习2:

env_init():
作用是初始化envs数组，构建env_free_list链表，由于env[0]是链表头，所以从后往前循环，注释里也要求将envs置位free，envs_ids为0，所以代码如下：
 

env_setup_vm():
该函数有一个参数struct Env *e，初始化虚拟地址分布，如果返回值为0，代表成功，如果返回小于0，代表分配失败，失败可能包括没有足够地址分配。我们所写的代码只需要分配物理页作为页目录使用，并继承内核页目录，将UVPT映射到当前环境页目录物理地址e->env_pgdir处，因为新增关联所以ref需要加一，代码如下：
 

region_alloc():
该函数有三个参数：sturct Env *e需要操作的用户环境；void *va虚拟地址；size_t len长度。目的是操作e->env_pgdir，为[va,a+len]分配物理空间。还要求不可以初始化页表，要求可以被用户和内核写，并要panic如果分配失败。首先我们设置起点和终点，随后，分配一个物理页，如果分配失败，进行panic，如果分配成功，借用lab2函数page_insert将我们物理页添加进去，并且根据要求进行添加，如果添加失败，再次恐慌。代码如下：
 

load_icode():
该函数有两个参数：struct Env *e需要操作的用户环境；uint8_t *binary: 可执行用户代码的起始地址。目的是加载binary开始的ELF文件。通过上网了解，可以通过ELF_MAGIC来确定是否读取的事ELF文件，如果不是panic报错。随后检查可否打开该ELF文件，否则panic报错。然后通过ELFHDR->e_phoff获取程序头距离ELF文件的偏移，ph指向的就是程序头的起始位置，相当于一个数组，随后通过设置cr3寄存器切换到该进程的页目录env_pgdir。然后env_tf->tf_eip指向header的e_entry，即程序初始位置。随后通过region_alloc分配每个程序段的内存，并按segment将代码存入相应内存，加载完成后，再次将cr3设置回kern_pgdir地址。
根据注释，我们还能得知，只有ph->p_type==ELF_PROG_LOAD时候，才可以加载segments，他们虚拟地址和内存可以分别在ph->p_va和ph->p_memsz中找到，所以通过region_alloc分配。并且用memmove拷贝相关部分，清零剩余部分。如果memsz<filesz，恐慌报错。代码如下：
 
随后，设置一页作为程序初始在指定虚拟地址，代码如下：
 

env_create():
该函数有两个参数：unit8_t *binary将要加载的可执行文件起始部分；enum EnvType type用户环境类型。目的是从env_free_list链表取出一个Env结构，加载从binary地址开始处的ELF可执行文件的该Env结构。代码如下：
 

env_run():
该函数有一个参数：struct Env *e当前执行的用户环境。作用是执行当前用户环境。如果这是第一次调用该函数，curenv是NULL。第一步：先判断现在是否有当前环境，如果有将当前环境返回到ENV_RUNNABLE，把当前环境置位e，然后把当前环境状态设置为ENV_RUNNING，更新env_runs，然后把lcr3寄存器存储当前环境地址。第二步是用env_pop_tf()还原环境的寄存器并在环境中进入用户模式。代码如下：
 

当我们做完练习2后，调用qemu会有提示，如图所示：
 
根据上网查询可以知道，这是由于用户程序user/hello.c中调用cprintf输出hello world，会用到指令int 0x30。而此时由于没有中断向量表，当CPU收到系统调用中断，会发现没有处理程序，于是会报general protection异常，于是最后成为triple fault。然后会导致CPU不断重启，为了方便调试，增加了补丁，就会报错。

练习3:

学习异常和中断的理论知识。
IDT可以驻留在物理内存中的任何位置。 处理器通过IDT寄存（IDTR）定位IDT。
 
	IDT包含了三种描述子:任务门、中断门、陷阱门
 
每个entry为8bytes，有以下关键bit：
16~31：code segment selector
0~15 & 46-64：segment offset （根据以上两项可确定中断处理函数的地址）
Type （8-11）：区分中断门、陷阱门、任务门等
DPL：Descriptor Privilege Level， 访问特权级
P：该描述符是否在内存中

练习4:

为了完成中断向量表初始化以及异常/中断处理，阅读了inc/trap.h，发现了现在我们需要添加的有0-31号以及48号，其中9号和15号被保留，添加48号中断是为了方便系统调用，后面的题会用到，具体如图：
 
所以，我们在trap_init()中添加这些中断，代码如下：
 
随后，我们将这些中断对应相应trapframe结构，通过阅读trap.h中对结构trapframe了解，代码如下：
 
可以看出trapframe存储的是当前寄存器的值，然后存入相应IDT，GDT值已经对应中断名称，这里的SEGATA找到一下定义：
#define SETGATE(gate, istrap, sel, off, dpl)
其中参数：
istrap: 1 for a trap (= exception) gate, 0 for an interrupt gate.
sel: 代码段选择子 for interrupt/trap handler
off: 代码段偏移 for interrupt/trap handler
dpl: 描述符特权级
代码如下：
 
紧接着，在kern/trapentry.S补充_alltraps，首先将trap.c和trap.h中的通过TRAPHANDLE压入中断向量和错误码，然后在_alltraps中压入旧的DS,ES寄存次和通用寄存器的值，并将DS，ES的值设置为GD_KD，又因为DS，ES是段寄存器，不支持立即数，所以AX寄存器中转数据。随后将ESP里的值压入内核栈，最后调用trap（tf）函数。代码如下：
 
至此完成练习4，通过make grade确认完成divzero，softint，basegment。如图所示：
 

问题1:

•	对每一个中断/异常都分别给出中断处理函数的目的是什么？换句话说，如果所有的中断都交给同一个中断处理函数处理，现在我们实现的哪些功能就没办法实现了？
答：因为不同的中断和异常需要不同的处理，这么做为了方便区分不同中断异常，可以根据压入的中断向量和错误码，来确定如何对应相应的中断和异常。
•	你有没有额外做什么事情让 user/softint 这个程序按预期运行？打分脚本希望它产生一个一般保护错(陷阱 13)，可是 softint 的代码却发送的是 int $14。为什么 这个产生了中断向量 13 ？如果内核允许 softint 的 int $14 指令去调用内核中断向量 14 所对应的的缺页处理函数，会发生什么？
答：因为当前系统运行在用户状态下，特权级别为3，INT是系统指令，特权为0，会引起General Protection Exception。

PART B

练习5:

通过会看trapframe结构，我们可以发现有一个uint32_t tf_trapno，所以再看中断类型，所以如果对应的是中断向量14:T_PGFLT，那么调用page_fault_handler()，代码如下：
 
结果如下，完成faultread、faultreadkernal、faultwriet、 faultwritekernal,：
 

练习6:

类似于练习5，代码如下：
 
结果如下，完成breakpoint：
 

问题2:

•	断点那个测试样例可能会生成一个断点异常，或者生成一个一般保护错，这取决你是怎样在 IDT 中初始化它的入口的（换句话说，你是怎样在 trap_init 中调用 SETGATE 方法的）。为什么？你应该做什么才能让断点异常像上面所说的那样工作？怎样的错误配置会导致一般保护错？
答：我们在初始化时候，可以将DPL设置为3，也就是防止如果用户程序跳转去执行内核程序，为了避免一般保护错误，也就是为了能让程序跳转到所指向的程序那里继续执行，因此，我们要将DPL（规定访问该段的权限级别）设置为3，防止在CPL（当前进程的权限级别）值为3时候，DPL小于CPL产生一般保护错误。

•	你认为这样的机制意义是什么？尤其要想想测试程序 user/softint 的所作所为 / 尤其要考虑一下 user/softint 测试程序的行为。
DPL的设置可以限制用户对指令的使用。

练习7:

通过阅读lib/syscall.c，其中内联汇编部分，如图所示：
 
“volatile"表示编译器不要优化代码，后面的指令 保留原样，其中”=a"表示"ret"是输出操作数; “i”=立即数。最后一个子句告诉汇编器这可能会改变条件代码和任意内存位置。memory强制gcc编译器假设所有内存单元均被汇编指令修改，这样cpu中的registers和cache中已缓存的内存单元中的数据将作废。cpu将不得不在需要的时候重新读取内存中的数据。这就阻止了cpu又将registers，cache中的数据用于去优化指令，而避免去访问内存。

随后，对kern/trap.c进行编辑。在刚才的switch语句中再加一个T_SYSCALL的分支，代码如下：
 
随后，在kern/syscall.c中，根据阅读前面的函数以及联想lib/syscall.c中的函数，我们很容易写下代码，只需要找好对应参数个数即可，代码如下：
 
其实整个过程，就是用户调用lib/syscall.c中的各个函数，该函数会调用syscall()函数，随后会发生int 0x30系统调用中断，进入trap，并dispatch到了kern/syscall.c中，调用制定函数。所以大部分lib中函数并没有实际操作，而是通过系统调用进入内核进行操作。

所以当我们make run-hello后，果然报错，如图所示：
 
随后再次用make grade测试，发现完成testbss，如图所示：
 

练习8:

根据题目所说，我们又阅读user/hello.c代码，其中第二句，后面有一句：thisenv->env_id。发现以下：
 
我们应该修改libmain()用来初始化全局指针thisenv以指向envs[]中对应此时的环境。所以通过刚才实现的系统调用获得此环境对应的Env，代码如下：
 
实现结果如图示：
 
我们发现可以实现后面一句的输出，随后make grade测试，结果如图：
 

练习9:

首先，我们要在trap.c中实现panic，因为我们刚才在发生缺页情况下，调用page_fault_handler()函数，所以去修改一下该函数，因为如果在内核状态下CPL为0，所以增加代码如下：
 
随后，查看pmap.c增加user_mem_check内容，先阅读user_mem_assert()内容，并没有增添对函数了解，所以阅读关于check的注释内容，我们将要测试范围内所有页面和“len/PGSIZE”，“len/PGSIZE+1”或“len/PGSIZE+2”页面。如果该页面满足：1、该地址低于ULIM；2、页面表为其授予权限，则用户程序可以访问虚拟地址。如果有错误，请将“ user_mem_check_addr”变量设置为第一个错误的虚拟地址。所以代码如下：
 
随后，我们要在syscall.c调用user_mem_assert()，代码如图所示：
 
经过验证，结果如图所示：
 
随后，在kern/kdebug.c中加入语句，如图所示：
 
然后运行了breakpoint，但没办法在监视器里使用backtrace，没有添加过类似指令。

练习10:

运行后，确实没有引起panic，结果如图所示：
 
至此，所有实验结束。

三、	实验结果

最后通过make grade完成全部实验，结果如下：
 
通过本次试验加深了对用户进程的理解。加深了对中断和异常认识，并了解了操作系统如何对自己进行保护。
