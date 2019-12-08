// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "showmappings", "Display information about physical page mappings", mon_showmappings },
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_showmappings(int args, char **argv, struct Trapframe *tf)
{
    char flag[1 << 8] = {
        [0] = '-',
        [PTE_W] = 'W',
        [PTE_U] = 'U',
        [PTE_A] = 'A',
        [PTE_D] = 'D',
        [PTE_PS] = 'S'
    };

    char *arg1 = argv[1];
    char *arg2 = argv[2];
    char *arg3 = argv[3];
    char *endptr;
    if (arg1 == NULL || arg2 == NULL || arg3) {
        cprintf("we need exactly two arguments!\n");
        return 0;
    }
    uintptr_t va_l = strtol(arg1, &endptr, 16);
    if (*endptr) {
        cprintf("argument's format error!\n");
        return 0;
    }
    uintptr_t va_r = strtol(arg2, &endptr, 16);
    if (*endptr) {
        cprintf("argument's format error!\n");
        return 0;
    }
    if (va_l > va_r) {
        cprintf("the first argument should not larger than the second argument!\n");
        return 0;
    }

    pde_t *pgdir = (pde_t *) PGADDR(PDX(UVPT), PDX(UVPT), 0);   // 这里直接用 kern_pgdir 也可以
    cprintf("      va range         entry      flag           pa range      \n");
    cprintf("---------------------------------------------------------------\n");
    while (va_l <= va_r) {
        pde_t pde = pgdir[PDX(va_l)];
        if (pde & PTE_P) {
            char bit_w = flag[pde & PTE_W];
            char bit_u = flag[pde & PTE_U];
            char bit_a = flag[pde & PTE_A];
            char bit_d = flag[pde & PTE_D];
            char bit_s = flag[pde & PTE_PS];
            pde = PTE_ADDR(pde);
            if (va_l < KERNBASE) {
                cprintf("[%08x - %08x]", va_l, va_l + PTSIZE - 1);
                cprintf(" PDE[%03x] --%c%c%c--%c%cP\n", PDX(va_l), bit_s, bit_d, bit_a, bit_u, bit_w);
                pte_t *pte = (pte_t *) (pde + KERNBASE);
		size_t i;
                for (i = 0; i != 1024 && va_l <= va_r; va_l += PGSIZE, ++i) {
                    if (pte[i] & PTE_P) {
                        bit_w = flag[pte[i] & PTE_W];
                        bit_u = flag[pte[i] & PTE_U];
                        bit_a = flag[pte[i] & PTE_A];
                        bit_d = flag[pte[i] & PTE_D];
                        bit_s = flag[pte[i] & PTE_PS];
                        cprintf(" |-[%08x - %08x]", va_l, va_l + PGSIZE - 1);   
                        cprintf(" PTE[%03x] --%c%c%c--%c%cP", i, bit_s, bit_d, bit_a, bit_u, bit_w);
                        cprintf(" [%08x - %08x]\n", PTE_ADDR(pte[i]), PTE_ADDR(pte[i]) + PGSIZE - 1);           
                    }
                }
                continue;
            }
            cprintf("[%08x - %08x]", va_l, va_l + PTSIZE - 1, PDX(va_l));
            cprintf(" PDE[%03x] --%c%c%c--%c%cP", PDX(va_l), bit_s, bit_d, bit_a, bit_u, bit_w);
            cprintf(" [%08x - %08x]\n", pde, pde + PTSIZE - 1);
            if (va_l == 0xffc00000) {
                break;
            }
        }
        va_l += PTSIZE;
    }
    return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	int i;
	uint32_t eip;
	uint32_t* ebp = (uint32_t *)read_ebp();

	while (ebp) {
		eip = *(ebp + 1);
		cprintf("ebp %x eip %x args", ebp, eip);
		uint32_t *args = ebp + 2;
		for (i = 0; i < 5; i++) {
			uint32_t argi = args[i];
			cprintf(" %08x ", argi);
		}
		cprintf("\n");
		struct Eipdebuginfo debug_info;
		debuginfo_eip(eip, &debug_info);
		cprintf("\t%s:%d: %.*s+%d\n",
			debug_info.eip_file, 
			debug_info.eip_line, 				
			debug_info.eip_fn_namelen,
			debug_info.eip_fn_name, 
			eip - debug_info.eip_fn_addr);
		ebp = (uint32_t *) *ebp;
	}
	return 0;
}



/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;
	unsigned int i = 0x00646c72;
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");
	cprintf("\033[0;32;40m H%x Wo%s", 57616, &i);
	cprintf("x=%d y=%d", 3);
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
