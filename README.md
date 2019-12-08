# OS Lab1 实验报告
（郑懿 1611361）

一、	实验准备

在本实验一开始，本人原本打算使用最新的Ubuntu19.04，但是发现gcc版本过新，又无法降级，尝试了多种方法，都无法找到对应版本的gcc。就改为较为旧的Ubuntu14.04。虽然gcc版本依旧过高，只能暂且进行尝试，如果以后有需求在更改。
二、	实验过程

练习1:

简单了解了一下x86汇编语言，并没有太大的困难。

练习2:

实验所用的qemu，只是简单的模拟了一下BIOS加载引导程序到内存中，然后启动系统。BIOS首先执行了一个跳转指令：ljmp $0xf000,$0xe05b，因为0xFFFF0到0x100000只有16字节，因此选跳转到第一个地方执行。通过上网查阅资料可以知道，BIOS如何判断从哪里加载Boot Loader。BIOS将所检查的磁盘的第一个扇区载入内存，放在0x0000:0x7c00处，如果该扇区最后两个字节是”55 AA”，那么就是一个引导扇区，否则继续检查下一个磁盘驱动器。

练习3:

Q1:处理器什么时候开始执行32位代码？如何完成的从16位到32位模式的切换？
在阅读boot/boot.S文件中，可以看到一行注释：
 
既然将CRO_PE_ON设置为flag，于是寻找，这个flag，可以发现boot,S有以下代码：
 
注释里也写了是从这里开始进入保护模式的，再通过gdb逐步查看，发现该段代码出现在0:7c26，所以实模式转化为保护模式是从0:7c26开始的。

Q2:引导加载程序Boot Loader执行的最后一个指令是什么，加载的内核的第一个指令是什么？
在阅读main.ck恶意看到，如果一切正常的话，最后一句是：
 
随后继续阅读boot.asm中，了解编译后的文件可知：
 
因为引导系统加载内核，所以内核的第一条代码应该就是引导的下一行代码，因为在此处，call 了0x10018，所以在0x10018寻找加载内核的第一条指令，
0x10000c:		movw	$0x1234,0x472

Q3:内核的第一条指令在哪里？

因为上一个问题已经找到了0x10000c，所以第一条指令就是0x10000c所对应的指令。

Q4:引导加载程序如何决定为了从磁盘获取整个内核必须读取多少扇区？在哪里可以找到这些信息？，

因为涉及了ELF相关知识，在上网了解过相关知识后，阅读main.c时候发现，一句代码：
 
注释告诉我们，就是这句代码分配了每个程序的扇区，所以主要是在main函数里制定了寻找的区域和读取的扇区的数量。

练习4:

由于已经学过相关知识，就大概了解了一下。

练习5:

根据指示，将0x7c00修改为0x8c00，随后用反汇编查看，发现.Text的VMA LMA都更改了地址。但随后调试的时候，由于连接器按照0x8c00的链接器起始位置对这些常量进行替换，但是BIOS还是把bootloader读到了0x7c00位置的，所以就产生冲突，在ljmp指令就报错了。是因为BIOS在出厂的时候就设置好了，把磁盘第一个扇区加载到了0x7c00。

练习6:

在代码进入到bootloader之前，可以发现0x10000都是0，之后加载到了内核，在此查看就发现0x10000有了内容，原因是内核被加载进来，所以会有了存储。同时也说明了，每次计算机都会自动清空0x10000的空间。

练习7:

通过gdb显示，在分页极致之后，两个地址只想了相同的地址：
 
而在我们注释掉了movl %eax， %cr0，由于无法开启分页机制，所以导致程序崩溃。

练习8:

对于打印八进制数字，只需要模仿十进制即可：
 

Q1:
通过阅读代码可以知道，console.c是负责提供cputchar函数给printf.c中的printf函数调用，printf中的函数负责分类解析各种各样的字符进行输出。

Q2:
这段代码通过阅读可以知道，是每次碰到每行写满，进行换行，将前面的行循环上移，再将光标达到屏幕最左端。

Q3:
cprintf函数中，fmt指向的是字符串，也就是“x %d, y%x, z%d，ap指的是参数的第一个，也就是x。随后每次ap都会每次想下移动多需要的类型位置。

Q4:
输出结果是HE110 Word，&i对应的序列从低位开始计算的72 6c 64 00正好是字符串rld。
如果变更高子节的，则只需要i改为0x726c6400，57616不需要更改。

Q5:
输出结果：
 
每次打印出来变量的值都是根据va_arg从ap指针不断向后取值，所以每次都会得到一个不固定的值，但在一段时间内是固定的。

Q6:
如果更改调用约定，压栈顺序正好相反，所以原来是加上去的地址，现在是减去。

Challenge：

首先，在cga_putc函数里找到了一句注释：
 
但并没有在该函数里找到如何更改颜色，在上网查阅资料后发现，应该如同汇编一样，高八位是颜色，所以在cprintf处更改，得出以下效果：
 

练习9:

在kernel中有几句代码：
 
由注释，我们可以知道，是对%ebp和%esp进行初始化，将%esp设置为栈顶部，往低地址伸长。

练习10:

在kern.asm中有多test_backtrace，参数从5减到了1，每一次递归调用，%ebp减去0x14，分配给栈。 

练习11:

通过阅读entry.S，我们可以知道%ebp是通过指向老%ebp，所以类似于链表的方式，就可以一调用整个链。由于每次都会清楚%ebp，所以当他为空时候，停止调用，可以用一个while循环来停止，代码如下：
 
回溯成功，所以方案是正确的。

练习12:

通过阅读kebug.c里的几个函数，可以发现stab_binsearch是利用地址符号进行二分搜索，所以补全debuginfo_eip函数，存储下具体行号，代码如下：
 
随后，在十一题基础上，调用这个函数，并按要求输出，代码如下：
 
就完成了要求。



三、	实验结果

使用qemu，测试回溯函数结果：
 
通过make grade，测试最后结果：
 
通过这次试验，加深了汇编以及硬件相关一些知识，也为操作系统的学习奠定了基础。

