
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 b0 ee 17 f0       	mov    $0xf017eeb0,%eax
f010004b:	2d 9d df 17 f0       	sub    $0xf017df9d,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 9d df 17 f0 	movl   $0xf017df9d,(%esp)
f0100063:	e8 6f 4e 00 00       	call   f0104ed7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 b2 04 00 00       	call   f010051f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 80 53 10 f0 	movl   $0xf0105380,(%esp)
f010007c:	e8 f8 38 00 00       	call   f0103979 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 c2 14 00 00       	call   f0101548 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 ab 32 00 00       	call   f0103336 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 68 39 00 00       	call   f01039fd <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 59 2c 13 f0 	movl   $0xf0132c59,(%esp)
f01000a4:	e8 6a 34 00 00       	call   f0103513 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 ec e1 17 f0       	mov    0xf017e1ec,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 e7 37 00 00       	call   f010389d <env_run>

f01000b6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b6:	55                   	push   %ebp
f01000b7:	89 e5                	mov    %esp,%ebp
f01000b9:	56                   	push   %esi
f01000ba:	53                   	push   %ebx
f01000bb:	83 ec 10             	sub    $0x10,%esp
f01000be:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c1:	83 3d a0 ee 17 f0 00 	cmpl   $0x0,0xf017eea0
f01000c8:	75 3d                	jne    f0100107 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000ca:	89 35 a0 ee 17 f0    	mov    %esi,0xf017eea0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000d0:	fa                   	cli    
f01000d1:	fc                   	cld    

	va_start(ap, fmt);
f01000d2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01000df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000e3:	c7 04 24 9b 53 10 f0 	movl   $0xf010539b,(%esp)
f01000ea:	e8 8a 38 00 00       	call   f0103979 <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 4b 38 00 00       	call   f0103946 <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 7d 64 10 f0 	movl   $0xf010647d,(%esp)
f0100102:	e8 72 38 00 00       	call   f0103979 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100107:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010010e:	e8 d2 0a 00 00       	call   f0100be5 <monitor>
f0100113:	eb f2                	jmp    f0100107 <_panic+0x51>

f0100115 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100115:	55                   	push   %ebp
f0100116:	89 e5                	mov    %esp,%ebp
f0100118:	53                   	push   %ebx
f0100119:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010011c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010011f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100126:	8b 45 08             	mov    0x8(%ebp),%eax
f0100129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012d:	c7 04 24 b3 53 10 f0 	movl   $0xf01053b3,(%esp)
f0100134:	e8 40 38 00 00       	call   f0103979 <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 fe 37 00 00       	call   f0103946 <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 7d 64 10 f0 	movl   $0xf010647d,(%esp)
f010014f:	e8 25 38 00 00       	call   f0103979 <cprintf>
	va_end(ap);
}
f0100154:	83 c4 14             	add    $0x14,%esp
f0100157:	5b                   	pop    %ebx
f0100158:	5d                   	pop    %ebp
f0100159:	c3                   	ret    
f010015a:	66 90                	xchg   %ax,%ax
f010015c:	66 90                	xchg   %ax,%ax
f010015e:	66 90                	xchg   %ax,%ax

f0100160 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100160:	55                   	push   %ebp
f0100161:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100163:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100168:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100169:	a8 01                	test   $0x1,%al
f010016b:	74 08                	je     f0100175 <serial_proc_data+0x15>
f010016d:	b2 f8                	mov    $0xf8,%dl
f010016f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100170:	0f b6 c0             	movzbl %al,%eax
f0100173:	eb 05                	jmp    f010017a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010017a:	5d                   	pop    %ebp
f010017b:	c3                   	ret    

f010017c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010017c:	55                   	push   %ebp
f010017d:	89 e5                	mov    %esp,%ebp
f010017f:	53                   	push   %ebx
f0100180:	83 ec 04             	sub    $0x4,%esp
f0100183:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100185:	eb 2a                	jmp    f01001b1 <cons_intr+0x35>
		if (c == 0)
f0100187:	85 d2                	test   %edx,%edx
f0100189:	74 26                	je     f01001b1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010018b:	a1 c4 e1 17 f0       	mov    0xf017e1c4,%eax
f0100190:	8d 48 01             	lea    0x1(%eax),%ecx
f0100193:	89 0d c4 e1 17 f0    	mov    %ecx,0xf017e1c4
f0100199:	88 90 c0 df 17 f0    	mov    %dl,-0xfe82040(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010019f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001a5:	75 0a                	jne    f01001b1 <cons_intr+0x35>
			cons.wpos = 0;
f01001a7:	c7 05 c4 e1 17 f0 00 	movl   $0x0,0xf017e1c4
f01001ae:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001b1:	ff d3                	call   *%ebx
f01001b3:	89 c2                	mov    %eax,%edx
f01001b5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001b8:	75 cd                	jne    f0100187 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001ba:	83 c4 04             	add    $0x4,%esp
f01001bd:	5b                   	pop    %ebx
f01001be:	5d                   	pop    %ebp
f01001bf:	c3                   	ret    

f01001c0 <kbd_proc_data>:
f01001c0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001c5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001c6:	a8 01                	test   $0x1,%al
f01001c8:	0f 84 ef 00 00 00    	je     f01002bd <kbd_proc_data+0xfd>
f01001ce:	b2 60                	mov    $0x60,%dl
f01001d0:	ec                   	in     (%dx),%al
f01001d1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001d3:	3c e0                	cmp    $0xe0,%al
f01001d5:	75 0d                	jne    f01001e4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001d7:	83 0d a0 df 17 f0 40 	orl    $0x40,0xf017dfa0
		return 0;
f01001de:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001e3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001e4:	55                   	push   %ebp
f01001e5:	89 e5                	mov    %esp,%ebp
f01001e7:	53                   	push   %ebx
f01001e8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001eb:	84 c0                	test   %al,%al
f01001ed:	79 37                	jns    f0100226 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001ef:	8b 0d a0 df 17 f0    	mov    0xf017dfa0,%ecx
f01001f5:	89 cb                	mov    %ecx,%ebx
f01001f7:	83 e3 40             	and    $0x40,%ebx
f01001fa:	83 e0 7f             	and    $0x7f,%eax
f01001fd:	85 db                	test   %ebx,%ebx
f01001ff:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100202:	0f b6 d2             	movzbl %dl,%edx
f0100205:	0f b6 82 20 55 10 f0 	movzbl -0xfefaae0(%edx),%eax
f010020c:	83 c8 40             	or     $0x40,%eax
f010020f:	0f b6 c0             	movzbl %al,%eax
f0100212:	f7 d0                	not    %eax
f0100214:	21 c1                	and    %eax,%ecx
f0100216:	89 0d a0 df 17 f0    	mov    %ecx,0xf017dfa0
		return 0;
f010021c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100221:	e9 9d 00 00 00       	jmp    f01002c3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100226:	8b 0d a0 df 17 f0    	mov    0xf017dfa0,%ecx
f010022c:	f6 c1 40             	test   $0x40,%cl
f010022f:	74 0e                	je     f010023f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100231:	83 c8 80             	or     $0xffffff80,%eax
f0100234:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100236:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100239:	89 0d a0 df 17 f0    	mov    %ecx,0xf017dfa0
	}

	shift |= shiftcode[data];
f010023f:	0f b6 d2             	movzbl %dl,%edx
f0100242:	0f b6 82 20 55 10 f0 	movzbl -0xfefaae0(%edx),%eax
f0100249:	0b 05 a0 df 17 f0    	or     0xf017dfa0,%eax
	shift ^= togglecode[data];
f010024f:	0f b6 8a 20 54 10 f0 	movzbl -0xfefabe0(%edx),%ecx
f0100256:	31 c8                	xor    %ecx,%eax
f0100258:	a3 a0 df 17 f0       	mov    %eax,0xf017dfa0

	c = charcode[shift & (CTL | SHIFT)][data];
f010025d:	89 c1                	mov    %eax,%ecx
f010025f:	83 e1 03             	and    $0x3,%ecx
f0100262:	8b 0c 8d 00 54 10 f0 	mov    -0xfefac00(,%ecx,4),%ecx
f0100269:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010026d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100270:	a8 08                	test   $0x8,%al
f0100272:	74 1b                	je     f010028f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100274:	89 da                	mov    %ebx,%edx
f0100276:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100279:	83 f9 19             	cmp    $0x19,%ecx
f010027c:	77 05                	ja     f0100283 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010027e:	83 eb 20             	sub    $0x20,%ebx
f0100281:	eb 0c                	jmp    f010028f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100283:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100286:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100289:	83 fa 19             	cmp    $0x19,%edx
f010028c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010028f:	f7 d0                	not    %eax
f0100291:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100293:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100295:	f6 c2 06             	test   $0x6,%dl
f0100298:	75 29                	jne    f01002c3 <kbd_proc_data+0x103>
f010029a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002a0:	75 21                	jne    f01002c3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002a2:	c7 04 24 cd 53 10 f0 	movl   $0xf01053cd,(%esp)
f01002a9:	e8 cb 36 00 00       	call   f0103979 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ae:	ba 92 00 00 00       	mov    $0x92,%edx
f01002b3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002b8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002b9:	89 d8                	mov    %ebx,%eax
f01002bb:	eb 06                	jmp    f01002c3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002c2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002c3:	83 c4 14             	add    $0x14,%esp
f01002c6:	5b                   	pop    %ebx
f01002c7:	5d                   	pop    %ebp
f01002c8:	c3                   	ret    

f01002c9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002c9:	55                   	push   %ebp
f01002ca:	89 e5                	mov    %esp,%ebp
f01002cc:	57                   	push   %edi
f01002cd:	56                   	push   %esi
f01002ce:	53                   	push   %ebx
f01002cf:	83 ec 1c             	sub    $0x1c,%esp
f01002d2:	89 c7                	mov    %eax,%edi
f01002d4:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002d9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002de:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e3:	eb 06                	jmp    f01002eb <cons_putc+0x22>
f01002e5:	89 ca                	mov    %ecx,%edx
f01002e7:	ec                   	in     (%dx),%al
f01002e8:	ec                   	in     (%dx),%al
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	89 f2                	mov    %esi,%edx
f01002ed:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ee:	a8 20                	test   $0x20,%al
f01002f0:	75 05                	jne    f01002f7 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002f2:	83 eb 01             	sub    $0x1,%ebx
f01002f5:	75 ee                	jne    f01002e5 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002f7:	89 f8                	mov    %edi,%eax
f01002f9:	0f b6 c0             	movzbl %al,%eax
f01002fc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100304:	ee                   	out    %al,(%dx)
f0100305:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030a:	be 79 03 00 00       	mov    $0x379,%esi
f010030f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100314:	eb 06                	jmp    f010031c <cons_putc+0x53>
f0100316:	89 ca                	mov    %ecx,%edx
f0100318:	ec                   	in     (%dx),%al
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	89 f2                	mov    %esi,%edx
f010031e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010031f:	84 c0                	test   %al,%al
f0100321:	78 05                	js     f0100328 <cons_putc+0x5f>
f0100323:	83 eb 01             	sub    $0x1,%ebx
f0100326:	75 ee                	jne    f0100316 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100328:	ba 78 03 00 00       	mov    $0x378,%edx
f010032d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100331:	ee                   	out    %al,(%dx)
f0100332:	b2 7a                	mov    $0x7a,%dl
f0100334:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100339:	ee                   	out    %al,(%dx)
f010033a:	b8 08 00 00 00       	mov    $0x8,%eax
f010033f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100340:	89 fa                	mov    %edi,%edx
f0100342:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100348:	89 f8                	mov    %edi,%eax
f010034a:	80 cc 07             	or     $0x7,%ah
f010034d:	85 d2                	test   %edx,%edx
f010034f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100352:	89 f8                	mov    %edi,%eax
f0100354:	0f b6 c0             	movzbl %al,%eax
f0100357:	83 f8 09             	cmp    $0x9,%eax
f010035a:	74 76                	je     f01003d2 <cons_putc+0x109>
f010035c:	83 f8 09             	cmp    $0x9,%eax
f010035f:	7f 0a                	jg     f010036b <cons_putc+0xa2>
f0100361:	83 f8 08             	cmp    $0x8,%eax
f0100364:	74 16                	je     f010037c <cons_putc+0xb3>
f0100366:	e9 9b 00 00 00       	jmp    f0100406 <cons_putc+0x13d>
f010036b:	83 f8 0a             	cmp    $0xa,%eax
f010036e:	66 90                	xchg   %ax,%ax
f0100370:	74 3a                	je     f01003ac <cons_putc+0xe3>
f0100372:	83 f8 0d             	cmp    $0xd,%eax
f0100375:	74 3d                	je     f01003b4 <cons_putc+0xeb>
f0100377:	e9 8a 00 00 00       	jmp    f0100406 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f010037c:	0f b7 05 c8 e1 17 f0 	movzwl 0xf017e1c8,%eax
f0100383:	66 85 c0             	test   %ax,%ax
f0100386:	0f 84 e5 00 00 00    	je     f0100471 <cons_putc+0x1a8>
			crt_pos--;
f010038c:	83 e8 01             	sub    $0x1,%eax
f010038f:	66 a3 c8 e1 17 f0    	mov    %ax,0xf017e1c8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100395:	0f b7 c0             	movzwl %ax,%eax
f0100398:	66 81 e7 00 ff       	and    $0xff00,%di
f010039d:	83 cf 20             	or     $0x20,%edi
f01003a0:	8b 15 cc e1 17 f0    	mov    0xf017e1cc,%edx
f01003a6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003aa:	eb 78                	jmp    f0100424 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ac:	66 83 05 c8 e1 17 f0 	addw   $0x50,0xf017e1c8
f01003b3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003b4:	0f b7 05 c8 e1 17 f0 	movzwl 0xf017e1c8,%eax
f01003bb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c1:	c1 e8 16             	shr    $0x16,%eax
f01003c4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003c7:	c1 e0 04             	shl    $0x4,%eax
f01003ca:	66 a3 c8 e1 17 f0    	mov    %ax,0xf017e1c8
f01003d0:	eb 52                	jmp    f0100424 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 ed fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003dc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e1:	e8 e3 fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003e6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003eb:	e8 d9 fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003f0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f5:	e8 cf fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003fa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ff:	e8 c5 fe ff ff       	call   f01002c9 <cons_putc>
f0100404:	eb 1e                	jmp    f0100424 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100406:	0f b7 05 c8 e1 17 f0 	movzwl 0xf017e1c8,%eax
f010040d:	8d 50 01             	lea    0x1(%eax),%edx
f0100410:	66 89 15 c8 e1 17 f0 	mov    %dx,0xf017e1c8
f0100417:	0f b7 c0             	movzwl %ax,%eax
f010041a:	8b 15 cc e1 17 f0    	mov    0xf017e1cc,%edx
f0100420:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100424:	66 81 3d c8 e1 17 f0 	cmpw   $0x7cf,0xf017e1c8
f010042b:	cf 07 
f010042d:	76 42                	jbe    f0100471 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010042f:	a1 cc e1 17 f0       	mov    0xf017e1cc,%eax
f0100434:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010043b:	00 
f010043c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100442:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100446:	89 04 24             	mov    %eax,(%esp)
f0100449:	e8 d6 4a 00 00       	call   f0104f24 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010044e:	8b 15 cc e1 17 f0    	mov    0xf017e1cc,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100454:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100459:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010045f:	83 c0 01             	add    $0x1,%eax
f0100462:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100467:	75 f0                	jne    f0100459 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100469:	66 83 2d c8 e1 17 f0 	subw   $0x50,0xf017e1c8
f0100470:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100471:	8b 0d d0 e1 17 f0    	mov    0xf017e1d0,%ecx
f0100477:	b8 0e 00 00 00       	mov    $0xe,%eax
f010047c:	89 ca                	mov    %ecx,%edx
f010047e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010047f:	0f b7 1d c8 e1 17 f0 	movzwl 0xf017e1c8,%ebx
f0100486:	8d 71 01             	lea    0x1(%ecx),%esi
f0100489:	89 d8                	mov    %ebx,%eax
f010048b:	66 c1 e8 08          	shr    $0x8,%ax
f010048f:	89 f2                	mov    %esi,%edx
f0100491:	ee                   	out    %al,(%dx)
f0100492:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100497:	89 ca                	mov    %ecx,%edx
f0100499:	ee                   	out    %al,(%dx)
f010049a:	89 d8                	mov    %ebx,%eax
f010049c:	89 f2                	mov    %esi,%edx
f010049e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010049f:	83 c4 1c             	add    $0x1c,%esp
f01004a2:	5b                   	pop    %ebx
f01004a3:	5e                   	pop    %esi
f01004a4:	5f                   	pop    %edi
f01004a5:	5d                   	pop    %ebp
f01004a6:	c3                   	ret    

f01004a7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004a7:	80 3d d4 e1 17 f0 00 	cmpb   $0x0,0xf017e1d4
f01004ae:	74 11                	je     f01004c1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004b0:	55                   	push   %ebp
f01004b1:	89 e5                	mov    %esp,%ebp
f01004b3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004b6:	b8 60 01 10 f0       	mov    $0xf0100160,%eax
f01004bb:	e8 bc fc ff ff       	call   f010017c <cons_intr>
}
f01004c0:	c9                   	leave  
f01004c1:	f3 c3                	repz ret 

f01004c3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004c9:	b8 c0 01 10 f0       	mov    $0xf01001c0,%eax
f01004ce:	e8 a9 fc ff ff       	call   f010017c <cons_intr>
}
f01004d3:	c9                   	leave  
f01004d4:	c3                   	ret    

f01004d5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004d5:	55                   	push   %ebp
f01004d6:	89 e5                	mov    %esp,%ebp
f01004d8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004db:	e8 c7 ff ff ff       	call   f01004a7 <serial_intr>
	kbd_intr();
f01004e0:	e8 de ff ff ff       	call   f01004c3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004e5:	a1 c0 e1 17 f0       	mov    0xf017e1c0,%eax
f01004ea:	3b 05 c4 e1 17 f0    	cmp    0xf017e1c4,%eax
f01004f0:	74 26                	je     f0100518 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004f2:	8d 50 01             	lea    0x1(%eax),%edx
f01004f5:	89 15 c0 e1 17 f0    	mov    %edx,0xf017e1c0
f01004fb:	0f b6 88 c0 df 17 f0 	movzbl -0xfe82040(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100502:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100504:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010050a:	75 11                	jne    f010051d <cons_getc+0x48>
			cons.rpos = 0;
f010050c:	c7 05 c0 e1 17 f0 00 	movl   $0x0,0xf017e1c0
f0100513:	00 00 00 
f0100516:	eb 05                	jmp    f010051d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100518:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010051d:	c9                   	leave  
f010051e:	c3                   	ret    

f010051f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010051f:	55                   	push   %ebp
f0100520:	89 e5                	mov    %esp,%ebp
f0100522:	57                   	push   %edi
f0100523:	56                   	push   %esi
f0100524:	53                   	push   %ebx
f0100525:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100528:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010052f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100536:	5a a5 
	if (*cp != 0xA55A) {
f0100538:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010053f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100543:	74 11                	je     f0100556 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100545:	c7 05 d0 e1 17 f0 b4 	movl   $0x3b4,0xf017e1d0
f010054c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010054f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100554:	eb 16                	jmp    f010056c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100556:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010055d:	c7 05 d0 e1 17 f0 d4 	movl   $0x3d4,0xf017e1d0
f0100564:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100567:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010056c:	8b 0d d0 e1 17 f0    	mov    0xf017e1d0,%ecx
f0100572:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100577:	89 ca                	mov    %ecx,%edx
f0100579:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010057a:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057d:	89 da                	mov    %ebx,%edx
f010057f:	ec                   	in     (%dx),%al
f0100580:	0f b6 f0             	movzbl %al,%esi
f0100583:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100586:	b8 0f 00 00 00       	mov    $0xf,%eax
f010058b:	89 ca                	mov    %ecx,%edx
f010058d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058e:	89 da                	mov    %ebx,%edx
f0100590:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100591:	89 3d cc e1 17 f0    	mov    %edi,0xf017e1cc

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100597:	0f b6 d8             	movzbl %al,%ebx
f010059a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010059c:	66 89 35 c8 e1 17 f0 	mov    %si,0xf017e1c8
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ad:	89 f2                	mov    %esi,%edx
f01005af:	ee                   	out    %al,(%dx)
f01005b0:	b2 fb                	mov    $0xfb,%dl
f01005b2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005b7:	ee                   	out    %al,(%dx)
f01005b8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005bd:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 f9                	mov    $0xf9,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 fb                	mov    $0xfb,%dl
f01005cf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	b2 fc                	mov    $0xfc,%dl
f01005d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005dc:	ee                   	out    %al,(%dx)
f01005dd:	b2 f9                	mov    $0xf9,%dl
f01005df:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e5:	b2 fd                	mov    $0xfd,%dl
f01005e7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e8:	3c ff                	cmp    $0xff,%al
f01005ea:	0f 95 c1             	setne  %cl
f01005ed:	88 0d d4 e1 17 f0    	mov    %cl,0xf017e1d4
f01005f3:	89 f2                	mov    %esi,%edx
f01005f5:	ec                   	in     (%dx),%al
f01005f6:	89 da                	mov    %ebx,%edx
f01005f8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f9:	84 c9                	test   %cl,%cl
f01005fb:	75 0c                	jne    f0100609 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005fd:	c7 04 24 d9 53 10 f0 	movl   $0xf01053d9,(%esp)
f0100604:	e8 70 33 00 00       	call   f0103979 <cprintf>
}
f0100609:	83 c4 1c             	add    $0x1c,%esp
f010060c:	5b                   	pop    %ebx
f010060d:	5e                   	pop    %esi
f010060e:	5f                   	pop    %edi
f010060f:	5d                   	pop    %ebp
f0100610:	c3                   	ret    

f0100611 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100617:	8b 45 08             	mov    0x8(%ebp),%eax
f010061a:	e8 aa fc ff ff       	call   f01002c9 <cons_putc>
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <getchar>:

int
getchar(void)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
f0100624:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100627:	e8 a9 fe ff ff       	call   f01004d5 <cons_getc>
f010062c:	85 c0                	test   %eax,%eax
f010062e:	74 f7                	je     f0100627 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100630:	c9                   	leave  
f0100631:	c3                   	ret    

f0100632 <iscons>:

int
iscons(int fdnum)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100635:	b8 01 00 00 00       	mov    $0x1,%eax
f010063a:	5d                   	pop    %ebp
f010063b:	c3                   	ret    
f010063c:	66 90                	xchg   %ax,%ax
f010063e:	66 90                	xchg   %ax,%ax

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	c7 44 24 08 20 56 10 	movl   $0xf0105620,0x8(%esp)
f010064d:	f0 
f010064e:	c7 44 24 04 3e 56 10 	movl   $0xf010563e,0x4(%esp)
f0100655:	f0 
f0100656:	c7 04 24 43 56 10 f0 	movl   $0xf0105643,(%esp)
f010065d:	e8 17 33 00 00       	call   f0103979 <cprintf>
f0100662:	c7 44 24 08 90 57 10 	movl   $0xf0105790,0x8(%esp)
f0100669:	f0 
f010066a:	c7 44 24 04 4c 56 10 	movl   $0xf010564c,0x4(%esp)
f0100671:	f0 
f0100672:	c7 04 24 43 56 10 f0 	movl   $0xf0105643,(%esp)
f0100679:	e8 fb 32 00 00       	call   f0103979 <cprintf>
f010067e:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f0100685:	f0 
f0100686:	c7 44 24 04 55 56 10 	movl   $0xf0105655,0x4(%esp)
f010068d:	f0 
f010068e:	c7 04 24 43 56 10 f0 	movl   $0xf0105643,(%esp)
f0100695:	e8 df 32 00 00       	call   f0103979 <cprintf>
	return 0;
}
f010069a:	b8 00 00 00 00       	mov    $0x0,%eax
f010069f:	c9                   	leave  
f01006a0:	c3                   	ret    

f01006a1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006a1:	55                   	push   %ebp
f01006a2:	89 e5                	mov    %esp,%ebp
f01006a4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006a7:	c7 04 24 62 56 10 f0 	movl   $0xf0105662,(%esp)
f01006ae:	e8 c6 32 00 00       	call   f0103979 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006b3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ba:	00 
f01006bb:	c7 04 24 ec 57 10 f0 	movl   $0xf01057ec,(%esp)
f01006c2:	e8 b2 32 00 00       	call   f0103979 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ce:	00 
f01006cf:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006d6:	f0 
f01006d7:	c7 04 24 14 58 10 f0 	movl   $0xf0105814,(%esp)
f01006de:	e8 96 32 00 00       	call   f0103979 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e3:	c7 44 24 08 67 53 10 	movl   $0x105367,0x8(%esp)
f01006ea:	00 
f01006eb:	c7 44 24 04 67 53 10 	movl   $0xf0105367,0x4(%esp)
f01006f2:	f0 
f01006f3:	c7 04 24 38 58 10 f0 	movl   $0xf0105838,(%esp)
f01006fa:	e8 7a 32 00 00       	call   f0103979 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ff:	c7 44 24 08 9d df 17 	movl   $0x17df9d,0x8(%esp)
f0100706:	00 
f0100707:	c7 44 24 04 9d df 17 	movl   $0xf017df9d,0x4(%esp)
f010070e:	f0 
f010070f:	c7 04 24 5c 58 10 f0 	movl   $0xf010585c,(%esp)
f0100716:	e8 5e 32 00 00       	call   f0103979 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010071b:	c7 44 24 08 b0 ee 17 	movl   $0x17eeb0,0x8(%esp)
f0100722:	00 
f0100723:	c7 44 24 04 b0 ee 17 	movl   $0xf017eeb0,0x4(%esp)
f010072a:	f0 
f010072b:	c7 04 24 80 58 10 f0 	movl   $0xf0105880,(%esp)
f0100732:	e8 42 32 00 00       	call   f0103979 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100737:	b8 af f2 17 f0       	mov    $0xf017f2af,%eax
f010073c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100741:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100746:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010074c:	85 c0                	test   %eax,%eax
f010074e:	0f 48 c2             	cmovs  %edx,%eax
f0100751:	c1 f8 0a             	sar    $0xa,%eax
f0100754:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100758:	c7 04 24 a4 58 10 f0 	movl   $0xf01058a4,(%esp)
f010075f:	e8 15 32 00 00       	call   f0103979 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100764:	b8 00 00 00 00       	mov    $0x0,%eax
f0100769:	c9                   	leave  
f010076a:	c3                   	ret    

f010076b <mon_showmappings>:

int
mon_showmappings(int args, char **argv, struct Trapframe *tf)
{
f010076b:	55                   	push   %ebp
f010076c:	89 e5                	mov    %esp,%ebp
f010076e:	57                   	push   %edi
f010076f:	56                   	push   %esi
f0100770:	53                   	push   %ebx
f0100771:	81 ec 4c 01 00 00    	sub    $0x14c,%esp
f0100777:	8b 55 0c             	mov    0xc(%ebp),%edx
    char flag[1 << 8] = {
f010077a:	8d bd e8 fe ff ff    	lea    -0x118(%ebp),%edi
f0100780:	b9 40 00 00 00       	mov    $0x40,%ecx
f0100785:	b8 00 00 00 00       	mov    $0x0,%eax
f010078a:	f3 ab                	rep stos %eax,%es:(%edi)
f010078c:	c6 85 e8 fe ff ff 2d 	movb   $0x2d,-0x118(%ebp)
f0100793:	c6 85 ea fe ff ff 57 	movb   $0x57,-0x116(%ebp)
f010079a:	c6 85 ec fe ff ff 55 	movb   $0x55,-0x114(%ebp)
f01007a1:	c6 85 08 ff ff ff 41 	movb   $0x41,-0xf8(%ebp)
f01007a8:	c6 85 28 ff ff ff 44 	movb   $0x44,-0xd8(%ebp)
f01007af:	c6 85 68 ff ff ff 53 	movb   $0x53,-0x98(%ebp)
        [PTE_A] = 'A',
        [PTE_D] = 'D',
        [PTE_PS] = 'S'
    };

    char *arg1 = argv[1];
f01007b6:	8b 42 04             	mov    0x4(%edx),%eax
    char *arg2 = argv[2];
f01007b9:	8b 72 08             	mov    0x8(%edx),%esi
    char *arg3 = argv[3];
f01007bc:	8b 52 0c             	mov    0xc(%edx),%edx
    char *endptr;
    if (arg1 == NULL || arg2 == NULL || arg3) {
f01007bf:	85 c0                	test   %eax,%eax
f01007c1:	74 08                	je     f01007cb <mon_showmappings+0x60>
f01007c3:	85 f6                	test   %esi,%esi
f01007c5:	74 04                	je     f01007cb <mon_showmappings+0x60>
f01007c7:	85 d2                	test   %edx,%edx
f01007c9:	74 11                	je     f01007dc <mon_showmappings+0x71>
        cprintf("we need exactly two arguments!\n");
f01007cb:	c7 04 24 d0 58 10 f0 	movl   $0xf01058d0,(%esp)
f01007d2:	e8 a2 31 00 00       	call   f0103979 <cprintf>
        return 0;
f01007d7:	e9 4a 03 00 00       	jmp    f0100b26 <mon_showmappings+0x3bb>
    }
    uintptr_t va_l = strtol(arg1, &endptr, 16);
f01007dc:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01007e3:	00 
f01007e4:	8d 95 e4 fe ff ff    	lea    -0x11c(%ebp),%edx
f01007ea:	89 54 24 04          	mov    %edx,0x4(%esp)
f01007ee:	89 04 24             	mov    %eax,(%esp)
f01007f1:	e8 0d 48 00 00       	call   f0105003 <strtol>
f01007f6:	89 c3                	mov    %eax,%ebx
    if (*endptr) {
f01007f8:	8b 85 e4 fe ff ff    	mov    -0x11c(%ebp),%eax
f01007fe:	80 38 00             	cmpb   $0x0,(%eax)
f0100801:	74 11                	je     f0100814 <mon_showmappings+0xa9>
        cprintf("argument's format error!\n");
f0100803:	c7 04 24 7b 56 10 f0 	movl   $0xf010567b,(%esp)
f010080a:	e8 6a 31 00 00       	call   f0103979 <cprintf>
        return 0;
f010080f:	e9 12 03 00 00       	jmp    f0100b26 <mon_showmappings+0x3bb>
    }
    uintptr_t va_r = strtol(arg2, &endptr, 16);
f0100814:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f010081b:	00 
f010081c:	8d 85 e4 fe ff ff    	lea    -0x11c(%ebp),%eax
f0100822:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100826:	89 34 24             	mov    %esi,(%esp)
f0100829:	e8 d5 47 00 00       	call   f0105003 <strtol>
f010082e:	89 85 d4 fe ff ff    	mov    %eax,-0x12c(%ebp)
    if (*endptr) {
f0100834:	8b 85 e4 fe ff ff    	mov    -0x11c(%ebp),%eax
f010083a:	80 38 00             	cmpb   $0x0,(%eax)
f010083d:	74 11                	je     f0100850 <mon_showmappings+0xe5>
        cprintf("argument's format error!\n");
f010083f:	c7 04 24 7b 56 10 f0 	movl   $0xf010567b,(%esp)
f0100846:	e8 2e 31 00 00       	call   f0103979 <cprintf>
        return 0;
f010084b:	e9 d6 02 00 00       	jmp    f0100b26 <mon_showmappings+0x3bb>
    }
    if (va_l > va_r) {
f0100850:	3b 9d d4 fe ff ff    	cmp    -0x12c(%ebp),%ebx
f0100856:	76 11                	jbe    f0100869 <mon_showmappings+0xfe>
        cprintf("the first argument should not larger than the second argument!\n");
f0100858:	c7 04 24 f0 58 10 f0 	movl   $0xf01058f0,(%esp)
f010085f:	e8 15 31 00 00       	call   f0103979 <cprintf>
        return 0;
f0100864:	e9 bd 02 00 00       	jmp    f0100b26 <mon_showmappings+0x3bb>
    }

    pde_t *pgdir = (pde_t *) PGADDR(PDX(UVPT), PDX(UVPT), 0);   // 这里直接用 kern_pgdir 也可以
    cprintf("      va range         entry      flag           pa range      \n");
f0100869:	c7 04 24 30 59 10 f0 	movl   $0xf0105930,(%esp)
f0100870:	e8 04 31 00 00       	call   f0103979 <cprintf>
    cprintf("---------------------------------------------------------------\n");
f0100875:	c7 04 24 74 59 10 f0 	movl   $0xf0105974,(%esp)
f010087c:	e8 f8 30 00 00       	call   f0103979 <cprintf>
f0100881:	89 de                	mov    %ebx,%esi
    while (va_l <= va_r) {
        pde_t pde = pgdir[PDX(va_l)];
f0100883:	89 f3                	mov    %esi,%ebx
f0100885:	c1 eb 16             	shr    $0x16,%ebx
f0100888:	8b 04 9d 00 d0 7b ef 	mov    -0x10843000(,%ebx,4),%eax
        if (pde & PTE_P) {
f010088f:	a8 01                	test   $0x1,%al
f0100891:	0f 84 7d 02 00 00    	je     f0100b14 <mon_showmappings+0x3a9>
            char bit_w = flag[pde & PTE_W];
f0100897:	89 c2                	mov    %eax,%edx
f0100899:	83 e2 02             	and    $0x2,%edx
f010089c:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f01008a3:	ff 
f01008a4:	88 8d d3 fe ff ff    	mov    %cl,-0x12d(%ebp)
            char bit_u = flag[pde & PTE_U];
f01008aa:	89 c2                	mov    %eax,%edx
f01008ac:	83 e2 04             	and    $0x4,%edx
f01008af:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f01008b6:	ff 
f01008b7:	88 8d d2 fe ff ff    	mov    %cl,-0x12e(%ebp)
            char bit_a = flag[pde & PTE_A];
f01008bd:	89 c2                	mov    %eax,%edx
f01008bf:	83 e2 20             	and    $0x20,%edx
f01008c2:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f01008c9:	ff 
f01008ca:	88 8d d1 fe ff ff    	mov    %cl,-0x12f(%ebp)
            char bit_d = flag[pde & PTE_D];
f01008d0:	89 c2                	mov    %eax,%edx
f01008d2:	83 e2 40             	and    $0x40,%edx
f01008d5:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f01008dc:	ff 
f01008dd:	88 8d d0 fe ff ff    	mov    %cl,-0x130(%ebp)
            char bit_s = flag[pde & PTE_PS];
f01008e3:	89 c2                	mov    %eax,%edx
f01008e5:	81 e2 80 00 00 00    	and    $0x80,%edx
f01008eb:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f01008f2:	ff 
f01008f3:	88 8d cf fe ff ff    	mov    %cl,-0x131(%ebp)
            pde = PTE_ADDR(pde);
f01008f9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008fe:	89 c7                	mov    %eax,%edi
            if (va_l < KERNBASE) {
f0100900:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0100906:	0f 87 81 01 00 00    	ja     f0100a8d <mon_showmappings+0x322>
                cprintf("[%08x - %08x]", va_l, va_l + PTSIZE - 1);
f010090c:	8d 86 ff ff 3f 00    	lea    0x3fffff(%esi),%eax
f0100912:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100916:	89 74 24 04          	mov    %esi,0x4(%esp)
f010091a:	c7 04 24 b4 56 10 f0 	movl   $0xf01056b4,(%esp)
f0100921:	e8 53 30 00 00       	call   f0103979 <cprintf>
                cprintf(" PDE[%03x] --%c%c%c--%c%cP\n", PDX(va_l), bit_s, bit_d, bit_a, bit_u, bit_w);
f0100926:	0f be 85 d3 fe ff ff 	movsbl -0x12d(%ebp),%eax
f010092d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100931:	0f be 85 d2 fe ff ff 	movsbl -0x12e(%ebp),%eax
f0100938:	89 44 24 14          	mov    %eax,0x14(%esp)
f010093c:	0f be 85 d1 fe ff ff 	movsbl -0x12f(%ebp),%eax
f0100943:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100947:	0f be 85 d0 fe ff ff 	movsbl -0x130(%ebp),%eax
f010094e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100952:	0f be 85 cf fe ff ff 	movsbl -0x131(%ebp),%eax
f0100959:	89 44 24 08          	mov    %eax,0x8(%esp)
f010095d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100961:	c7 04 24 95 56 10 f0 	movl   $0xf0105695,(%esp)
f0100968:	e8 0c 30 00 00       	call   f0103979 <cprintf>
                pte_t *pte = (pte_t *) (pde + KERNBASE);
		size_t i;
                for (i = 0; i != 1024 && va_l <= va_r; va_l += PGSIZE, ++i) {
f010096d:	bb 00 00 00 00       	mov    $0x0,%ebx
                    if (pte[i] & PTE_P) {
f0100972:	8b 84 9f 00 00 00 f0 	mov    -0x10000000(%edi,%ebx,4),%eax
f0100979:	a8 01                	test   $0x1,%al
f010097b:	0f 84 e6 00 00 00    	je     f0100a67 <mon_showmappings+0x2fc>
                        bit_w = flag[pte[i] & PTE_W];
f0100981:	89 c2                	mov    %eax,%edx
f0100983:	83 e2 02             	and    $0x2,%edx
f0100986:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f010098d:	ff 
f010098e:	88 8d d3 fe ff ff    	mov    %cl,-0x12d(%ebp)
                        bit_u = flag[pte[i] & PTE_U];
f0100994:	89 c2                	mov    %eax,%edx
f0100996:	83 e2 04             	and    $0x4,%edx
f0100999:	0f b6 94 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%edx
f01009a0:	ff 
f01009a1:	88 95 d2 fe ff ff    	mov    %dl,-0x12e(%ebp)
                        bit_a = flag[pte[i] & PTE_A];
f01009a7:	89 c2                	mov    %eax,%edx
f01009a9:	83 e2 20             	and    $0x20,%edx
f01009ac:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f01009b3:	ff 
f01009b4:	88 8d d1 fe ff ff    	mov    %cl,-0x12f(%ebp)
                        bit_d = flag[pte[i] & PTE_D];
f01009ba:	89 c2                	mov    %eax,%edx
f01009bc:	83 e2 40             	and    $0x40,%edx
f01009bf:	0f b6 94 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%edx
f01009c6:	ff 
f01009c7:	88 95 d0 fe ff ff    	mov    %dl,-0x130(%ebp)
                        bit_s = flag[pte[i] & PTE_PS];
f01009cd:	25 80 00 00 00       	and    $0x80,%eax
f01009d2:	0f b6 84 05 e8 fe ff 	movzbl -0x118(%ebp,%eax,1),%eax
f01009d9:	ff 
f01009da:	88 85 cf fe ff ff    	mov    %al,-0x131(%ebp)
f01009e0:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
                        cprintf(" |-[%08x - %08x]", va_l, va_l + PGSIZE - 1);   
f01009e6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009ea:	89 74 24 04          	mov    %esi,0x4(%esp)
f01009ee:	c7 04 24 b1 56 10 f0 	movl   $0xf01056b1,(%esp)
f01009f5:	e8 7f 2f 00 00       	call   f0103979 <cprintf>
                        cprintf(" PTE[%03x] --%c%c%c--%c%cP", i, bit_s, bit_d, bit_a, bit_u, bit_w);
f01009fa:	0f be 85 d3 fe ff ff 	movsbl -0x12d(%ebp),%eax
f0100a01:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100a05:	0f be 85 d2 fe ff ff 	movsbl -0x12e(%ebp),%eax
f0100a0c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100a10:	0f be 85 d1 fe ff ff 	movsbl -0x12f(%ebp),%eax
f0100a17:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100a1b:	0f be 85 d0 fe ff ff 	movsbl -0x130(%ebp),%eax
f0100a22:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a26:	0f be 85 cf fe ff ff 	movsbl -0x131(%ebp),%eax
f0100a2d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a31:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100a35:	c7 04 24 c2 56 10 f0 	movl   $0xf01056c2,(%esp)
f0100a3c:	e8 38 2f 00 00       	call   f0103979 <cprintf>
                        cprintf(" [%08x - %08x]\n", PTE_ADDR(pte[i]), PTE_ADDR(pte[i]) + PGSIZE - 1);           
f0100a41:	8b 84 9f 00 00 00 f0 	mov    -0x10000000(%edi,%ebx,4),%eax
f0100a48:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a4d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100a53:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a57:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a5b:	c7 04 24 dd 56 10 f0 	movl   $0xf01056dd,(%esp)
f0100a62:	e8 12 2f 00 00       	call   f0103979 <cprintf>
            if (va_l < KERNBASE) {
                cprintf("[%08x - %08x]", va_l, va_l + PTSIZE - 1);
                cprintf(" PDE[%03x] --%c%c%c--%c%cP\n", PDX(va_l), bit_s, bit_d, bit_a, bit_u, bit_w);
                pte_t *pte = (pte_t *) (pde + KERNBASE);
		size_t i;
                for (i = 0; i != 1024 && va_l <= va_r; va_l += PGSIZE, ++i) {
f0100a67:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100a6d:	83 c3 01             	add    $0x1,%ebx
f0100a70:	39 b5 d4 fe ff ff    	cmp    %esi,-0x12c(%ebp)
f0100a76:	0f 82 9e 00 00 00    	jb     f0100b1a <mon_showmappings+0x3af>
f0100a7c:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0100a82:	0f 85 ea fe ff ff    	jne    f0100972 <mon_showmappings+0x207>
f0100a88:	e9 8d 00 00 00       	jmp    f0100b1a <mon_showmappings+0x3af>
                        cprintf(" [%08x - %08x]\n", PTE_ADDR(pte[i]), PTE_ADDR(pte[i]) + PGSIZE - 1);           
                    }
                }
                continue;
            }
            cprintf("[%08x - %08x]", va_l, va_l + PTSIZE - 1, PDX(va_l));
f0100a8d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100a91:	8d 86 ff ff 3f 00    	lea    0x3fffff(%esi),%eax
f0100a97:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a9b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a9f:	c7 04 24 b4 56 10 f0 	movl   $0xf01056b4,(%esp)
f0100aa6:	e8 ce 2e 00 00       	call   f0103979 <cprintf>
            cprintf(" PDE[%03x] --%c%c%c--%c%cP", PDX(va_l), bit_s, bit_d, bit_a, bit_u, bit_w);
f0100aab:	0f be 85 d3 fe ff ff 	movsbl -0x12d(%ebp),%eax
f0100ab2:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100ab6:	0f be 85 d2 fe ff ff 	movsbl -0x12e(%ebp),%eax
f0100abd:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100ac1:	0f be 85 d1 fe ff ff 	movsbl -0x12f(%ebp),%eax
f0100ac8:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100acc:	0f be 85 d0 fe ff ff 	movsbl -0x130(%ebp),%eax
f0100ad3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ad7:	0f be 85 cf fe ff ff 	movsbl -0x131(%ebp),%eax
f0100ade:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ae2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ae6:	c7 04 24 ed 56 10 f0 	movl   $0xf01056ed,(%esp)
f0100aed:	e8 87 2e 00 00       	call   f0103979 <cprintf>
            cprintf(" [%08x - %08x]\n", pde, pde + PTSIZE - 1);
f0100af2:	8d 87 ff ff 3f 00    	lea    0x3fffff(%edi),%eax
f0100af8:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100afc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100b00:	c7 04 24 dd 56 10 f0 	movl   $0xf01056dd,(%esp)
f0100b07:	e8 6d 2e 00 00       	call   f0103979 <cprintf>
            if (va_l == 0xffc00000) {
f0100b0c:	81 fe 00 00 c0 ff    	cmp    $0xffc00000,%esi
f0100b12:	74 12                	je     f0100b26 <mon_showmappings+0x3bb>
                break;
            }
        }
        va_l += PTSIZE;
f0100b14:	81 c6 00 00 40 00    	add    $0x400000,%esi
    }

    pde_t *pgdir = (pde_t *) PGADDR(PDX(UVPT), PDX(UVPT), 0);   // 这里直接用 kern_pgdir 也可以
    cprintf("      va range         entry      flag           pa range      \n");
    cprintf("---------------------------------------------------------------\n");
    while (va_l <= va_r) {
f0100b1a:	39 b5 d4 fe ff ff    	cmp    %esi,-0x12c(%ebp)
f0100b20:	0f 83 5d fd ff ff    	jae    f0100883 <mon_showmappings+0x118>
            }
        }
        va_l += PTSIZE;
    }
    return 0;
}
f0100b26:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b2b:	81 c4 4c 01 00 00    	add    $0x14c,%esp
f0100b31:	5b                   	pop    %ebx
f0100b32:	5e                   	pop    %esi
f0100b33:	5f                   	pop    %edi
f0100b34:	5d                   	pop    %ebp
f0100b35:	c3                   	ret    

f0100b36 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100b36:	55                   	push   %ebp
f0100b37:	89 e5                	mov    %esp,%ebp
f0100b39:	57                   	push   %edi
f0100b3a:	56                   	push   %esi
f0100b3b:	53                   	push   %ebx
f0100b3c:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	int i;
	uint32_t eip;
	uint32_t* ebp = (uint32_t *)read_ebp();
f0100b3f:	89 ee                	mov    %ebp,%esi

	while (ebp) {
f0100b41:	e9 8a 00 00 00       	jmp    f0100bd0 <mon_backtrace+0x9a>
		eip = *(ebp + 1);
f0100b46:	8b 46 04             	mov    0x4(%esi),%eax
f0100b49:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		cprintf("ebp %x eip %x args", ebp, eip);
f0100b4c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100b50:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b54:	c7 04 24 08 57 10 f0 	movl   $0xf0105708,(%esp)
f0100b5b:	e8 19 2e 00 00       	call   f0103979 <cprintf>
		uint32_t *args = ebp + 2;
f0100b60:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100b63:	8d 7e 1c             	lea    0x1c(%esi),%edi
		for (i = 0; i < 5; i++) {
			uint32_t argi = args[i];
			cprintf(" %08x ", argi);
f0100b66:	8b 03                	mov    (%ebx),%eax
f0100b68:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b6c:	c7 04 24 1b 57 10 f0 	movl   $0xf010571b,(%esp)
f0100b73:	e8 01 2e 00 00       	call   f0103979 <cprintf>
f0100b78:	83 c3 04             	add    $0x4,%ebx

	while (ebp) {
		eip = *(ebp + 1);
		cprintf("ebp %x eip %x args", ebp, eip);
		uint32_t *args = ebp + 2;
		for (i = 0; i < 5; i++) {
f0100b7b:	39 fb                	cmp    %edi,%ebx
f0100b7d:	75 e7                	jne    f0100b66 <mon_backtrace+0x30>
			uint32_t argi = args[i];
			cprintf(" %08x ", argi);
		}
		cprintf("\n");
f0100b7f:	c7 04 24 7d 64 10 f0 	movl   $0xf010647d,(%esp)
f0100b86:	e8 ee 2d 00 00       	call   f0103979 <cprintf>
		struct Eipdebuginfo debug_info;
		debuginfo_eip(eip, &debug_info);
f0100b8b:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100b8e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b92:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b95:	89 3c 24             	mov    %edi,(%esp)
f0100b98:	e8 15 38 00 00       	call   f01043b2 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",
f0100b9d:	89 f8                	mov    %edi,%eax
f0100b9f:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100ba2:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100ba6:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ba9:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100bad:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bb0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bb4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100bb7:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100bbb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100bbe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bc2:	c7 04 24 22 57 10 f0 	movl   $0xf0105722,(%esp)
f0100bc9:	e8 ab 2d 00 00       	call   f0103979 <cprintf>
			debug_info.eip_file, 
			debug_info.eip_line, 				
			debug_info.eip_fn_namelen,
			debug_info.eip_fn_name, 
			eip - debug_info.eip_fn_addr);
		ebp = (uint32_t *) *ebp;
f0100bce:	8b 36                	mov    (%esi),%esi
	// Your code here.
	int i;
	uint32_t eip;
	uint32_t* ebp = (uint32_t *)read_ebp();

	while (ebp) {
f0100bd0:	85 f6                	test   %esi,%esi
f0100bd2:	0f 85 6e ff ff ff    	jne    f0100b46 <mon_backtrace+0x10>
			debug_info.eip_fn_name, 
			eip - debug_info.eip_fn_addr);
		ebp = (uint32_t *) *ebp;
	}
	return 0;
}
f0100bd8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bdd:	83 c4 4c             	add    $0x4c,%esp
f0100be0:	5b                   	pop    %ebx
f0100be1:	5e                   	pop    %esi
f0100be2:	5f                   	pop    %edi
f0100be3:	5d                   	pop    %ebp
f0100be4:	c3                   	ret    

f0100be5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100be5:	55                   	push   %ebp
f0100be6:	89 e5                	mov    %esp,%ebp
f0100be8:	57                   	push   %edi
f0100be9:	56                   	push   %esi
f0100bea:	53                   	push   %ebx
f0100beb:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;
	unsigned int i = 0x00646c72;
f0100bee:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
	cprintf("Welcome to the JOS kernel monitor!\n");
f0100bf5:	c7 04 24 b8 59 10 f0 	movl   $0xf01059b8,(%esp)
f0100bfc:	e8 78 2d 00 00       	call   f0103979 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100c01:	c7 04 24 dc 59 10 f0 	movl   $0xf01059dc,(%esp)
f0100c08:	e8 6c 2d 00 00       	call   f0103979 <cprintf>


	if (tf != NULL)
f0100c0d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100c11:	74 0b                	je     f0100c1e <monitor+0x39>
		print_trapframe(tf);
f0100c13:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c16:	89 04 24             	mov    %eax,(%esp)
f0100c19:	e8 c1 31 00 00       	call   f0103ddf <print_trapframe>


	cprintf("\033[0;32;40m H%x Wo%s", 57616, &i);
f0100c1e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100c21:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c25:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f0100c2c:	00 
f0100c2d:	c7 04 24 33 57 10 f0 	movl   $0xf0105733,(%esp)
f0100c34:	e8 40 2d 00 00       	call   f0103979 <cprintf>
	cprintf("x=%d y=%d", 3);
f0100c39:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0100c40:	00 
f0100c41:	c7 04 24 47 57 10 f0 	movl   $0xf0105747,(%esp)
f0100c48:	e8 2c 2d 00 00       	call   f0103979 <cprintf>

	while (1) {
		buf = readline("K> ");
f0100c4d:	c7 04 24 51 57 10 f0 	movl   $0xf0105751,(%esp)
f0100c54:	e8 27 40 00 00       	call   f0104c80 <readline>
f0100c59:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100c5b:	85 c0                	test   %eax,%eax
f0100c5d:	74 ee                	je     f0100c4d <monitor+0x68>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100c5f:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100c66:	be 00 00 00 00       	mov    $0x0,%esi
f0100c6b:	eb 0a                	jmp    f0100c77 <monitor+0x92>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100c6d:	c6 03 00             	movb   $0x0,(%ebx)
f0100c70:	89 f7                	mov    %esi,%edi
f0100c72:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100c75:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100c77:	0f b6 03             	movzbl (%ebx),%eax
f0100c7a:	84 c0                	test   %al,%al
f0100c7c:	74 66                	je     f0100ce4 <monitor+0xff>
f0100c7e:	0f be c0             	movsbl %al,%eax
f0100c81:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c85:	c7 04 24 55 57 10 f0 	movl   $0xf0105755,(%esp)
f0100c8c:	e8 09 42 00 00       	call   f0104e9a <strchr>
f0100c91:	85 c0                	test   %eax,%eax
f0100c93:	75 d8                	jne    f0100c6d <monitor+0x88>
			*buf++ = 0;
		if (*buf == 0)
f0100c95:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100c98:	74 4a                	je     f0100ce4 <monitor+0xff>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100c9a:	83 fe 0f             	cmp    $0xf,%esi
f0100c9d:	8d 76 00             	lea    0x0(%esi),%esi
f0100ca0:	75 16                	jne    f0100cb8 <monitor+0xd3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100ca2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100ca9:	00 
f0100caa:	c7 04 24 5a 57 10 f0 	movl   $0xf010575a,(%esp)
f0100cb1:	e8 c3 2c 00 00       	call   f0103979 <cprintf>
f0100cb6:	eb 95                	jmp    f0100c4d <monitor+0x68>
			return 0;
		}
		argv[argc++] = buf;
f0100cb8:	8d 7e 01             	lea    0x1(%esi),%edi
f0100cbb:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f0100cbf:	eb 03                	jmp    f0100cc4 <monitor+0xdf>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100cc1:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100cc4:	0f b6 03             	movzbl (%ebx),%eax
f0100cc7:	84 c0                	test   %al,%al
f0100cc9:	74 aa                	je     f0100c75 <monitor+0x90>
f0100ccb:	0f be c0             	movsbl %al,%eax
f0100cce:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cd2:	c7 04 24 55 57 10 f0 	movl   $0xf0105755,(%esp)
f0100cd9:	e8 bc 41 00 00       	call   f0104e9a <strchr>
f0100cde:	85 c0                	test   %eax,%eax
f0100ce0:	74 df                	je     f0100cc1 <monitor+0xdc>
f0100ce2:	eb 91                	jmp    f0100c75 <monitor+0x90>
			buf++;
	}
	argv[argc] = 0;
f0100ce4:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f0100ceb:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100cec:	85 f6                	test   %esi,%esi
f0100cee:	0f 84 59 ff ff ff    	je     f0100c4d <monitor+0x68>
f0100cf4:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cf9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100cfc:	8b 04 85 20 5a 10 f0 	mov    -0xfefa5e0(,%eax,4),%eax
f0100d03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d07:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100d0a:	89 04 24             	mov    %eax,(%esp)
f0100d0d:	e8 2a 41 00 00       	call   f0104e3c <strcmp>
f0100d12:	85 c0                	test   %eax,%eax
f0100d14:	75 24                	jne    f0100d3a <monitor+0x155>
			return commands[i].func(argc, argv, tf);
f0100d16:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100d19:	8b 55 08             	mov    0x8(%ebp),%edx
f0100d1c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d20:	8d 4d a4             	lea    -0x5c(%ebp),%ecx
f0100d23:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100d27:	89 34 24             	mov    %esi,(%esp)
f0100d2a:	ff 14 85 28 5a 10 f0 	call   *-0xfefa5d8(,%eax,4)
	cprintf("x=%d y=%d", 3);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100d31:	85 c0                	test   %eax,%eax
f0100d33:	78 25                	js     f0100d5a <monitor+0x175>
f0100d35:	e9 13 ff ff ff       	jmp    f0100c4d <monitor+0x68>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100d3a:	83 c3 01             	add    $0x1,%ebx
f0100d3d:	83 fb 03             	cmp    $0x3,%ebx
f0100d40:	75 b7                	jne    f0100cf9 <monitor+0x114>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100d42:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100d45:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d49:	c7 04 24 77 57 10 f0 	movl   $0xf0105777,(%esp)
f0100d50:	e8 24 2c 00 00       	call   f0103979 <cprintf>
f0100d55:	e9 f3 fe ff ff       	jmp    f0100c4d <monitor+0x68>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100d5a:	83 c4 6c             	add    $0x6c,%esp
f0100d5d:	5b                   	pop    %ebx
f0100d5e:	5e                   	pop    %esi
f0100d5f:	5f                   	pop    %edi
f0100d60:	5d                   	pop    %ebp
f0100d61:	c3                   	ret    
f0100d62:	66 90                	xchg   %ax,%ax
f0100d64:	66 90                	xchg   %ax,%ax
f0100d66:	66 90                	xchg   %ax,%ax
f0100d68:	66 90                	xchg   %ax,%ax
f0100d6a:	66 90                	xchg   %ax,%ax
f0100d6c:	66 90                	xchg   %ax,%ax
f0100d6e:	66 90                	xchg   %ax,%ax

f0100d70 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100d70:	55                   	push   %ebp
f0100d71:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100d73:	83 3d d8 e1 17 f0 00 	cmpl   $0x0,0xf017e1d8
f0100d7a:	75 11                	jne    f0100d8d <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100d7c:	ba af fe 17 f0       	mov    $0xf017feaf,%edx
f0100d81:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100d87:	89 15 d8 e1 17 f0    	mov    %edx,0xf017e1d8
	
	if (n != 0) {
		char *next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
		return next;
	} else return nextfree;
f0100d8d:	8b 15 d8 e1 17 f0    	mov    0xf017e1d8,%edx
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	
	if (n != 0) {
f0100d93:	85 c0                	test   %eax,%eax
f0100d95:	74 11                	je     f0100da8 <boot_alloc+0x38>
		char *next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
f0100d97:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100d9e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100da3:	a3 d8 e1 17 f0       	mov    %eax,0xf017e1d8
		return next;
	} else return nextfree;

	return NULL;
}
f0100da8:	89 d0                	mov    %edx,%eax
f0100daa:	5d                   	pop    %ebp
f0100dab:	c3                   	ret    

f0100dac <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dac:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f0100db2:	c1 f8 03             	sar    $0x3,%eax
f0100db5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100db8:	89 c2                	mov    %eax,%edx
f0100dba:	c1 ea 0c             	shr    $0xc,%edx
f0100dbd:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f0100dc3:	72 26                	jb     f0100deb <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100dc5:	55                   	push   %ebp
f0100dc6:	89 e5                	mov    %esp,%ebp
f0100dc8:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dcb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dcf:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f0100dd6:	f0 
f0100dd7:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100dde:	00 
f0100ddf:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f0100de6:	e8 cb f2 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100deb:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100df0:	c3                   	ret    

f0100df1 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100df1:	89 d1                	mov    %edx,%ecx
f0100df3:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100df6:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100df9:	a8 01                	test   $0x1,%al
f0100dfb:	74 5d                	je     f0100e5a <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100dfd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e02:	89 c1                	mov    %eax,%ecx
f0100e04:	c1 e9 0c             	shr    $0xc,%ecx
f0100e07:	3b 0d a4 ee 17 f0    	cmp    0xf017eea4,%ecx
f0100e0d:	72 26                	jb     f0100e35 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100e0f:	55                   	push   %ebp
f0100e10:	89 e5                	mov    %esp,%ebp
f0100e12:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e15:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e19:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f0100e20:	f0 
f0100e21:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0100e28:	00 
f0100e29:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0100e30:	e8 81 f2 ff ff       	call   f01000b6 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100e35:	c1 ea 0c             	shr    $0xc,%edx
f0100e38:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100e3e:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100e45:	89 c2                	mov    %eax,%edx
f0100e47:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100e4a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100e4f:	85 d2                	test   %edx,%edx
f0100e51:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100e56:	0f 44 c2             	cmove  %edx,%eax
f0100e59:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100e5a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100e5f:	c3                   	ret    

f0100e60 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100e60:	55                   	push   %ebp
f0100e61:	89 e5                	mov    %esp,%ebp
f0100e63:	57                   	push   %edi
f0100e64:	56                   	push   %esi
f0100e65:	53                   	push   %ebx
f0100e66:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e69:	84 c0                	test   %al,%al
f0100e6b:	0f 85 15 03 00 00    	jne    f0101186 <check_page_free_list+0x326>
f0100e71:	e9 22 03 00 00       	jmp    f0101198 <check_page_free_list+0x338>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100e76:	c7 44 24 08 68 5a 10 	movl   $0xf0105a68,0x8(%esp)
f0100e7d:	f0 
f0100e7e:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f0100e85:	00 
f0100e86:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0100e8d:	e8 24 f2 ff ff       	call   f01000b6 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e92:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e95:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e98:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e9b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e9e:	89 c2                	mov    %eax,%edx
f0100ea0:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ea6:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100eac:	0f 95 c2             	setne  %dl
f0100eaf:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100eb2:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100eb6:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100eb8:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ebc:	8b 00                	mov    (%eax),%eax
f0100ebe:	85 c0                	test   %eax,%eax
f0100ec0:	75 dc                	jne    f0100e9e <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ec2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ec5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ecb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ece:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ed1:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ed3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ed6:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100edb:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ee0:	8b 1d e0 e1 17 f0    	mov    0xf017e1e0,%ebx
f0100ee6:	eb 63                	jmp    f0100f4b <check_page_free_list+0xeb>
f0100ee8:	89 d8                	mov    %ebx,%eax
f0100eea:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f0100ef0:	c1 f8 03             	sar    $0x3,%eax
f0100ef3:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ef6:	89 c2                	mov    %eax,%edx
f0100ef8:	c1 ea 16             	shr    $0x16,%edx
f0100efb:	39 f2                	cmp    %esi,%edx
f0100efd:	73 4a                	jae    f0100f49 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eff:	89 c2                	mov    %eax,%edx
f0100f01:	c1 ea 0c             	shr    $0xc,%edx
f0100f04:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f0100f0a:	72 20                	jb     f0100f2c <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f0c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f10:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f0100f17:	f0 
f0100f18:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f1f:	00 
f0100f20:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f0100f27:	e8 8a f1 ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100f2c:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100f33:	00 
f0100f34:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100f3b:	00 
	return (void *)(pa + KERNBASE);
f0100f3c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f41:	89 04 24             	mov    %eax,(%esp)
f0100f44:	e8 8e 3f 00 00       	call   f0104ed7 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f49:	8b 1b                	mov    (%ebx),%ebx
f0100f4b:	85 db                	test   %ebx,%ebx
f0100f4d:	75 99                	jne    f0100ee8 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100f4f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f54:	e8 17 fe ff ff       	call   f0100d70 <boot_alloc>
f0100f59:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f5c:	8b 15 e0 e1 17 f0    	mov    0xf017e1e0,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f62:	8b 0d ac ee 17 f0    	mov    0xf017eeac,%ecx
		assert(pp < pages + npages);
f0100f68:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f0100f6d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100f70:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100f73:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f76:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100f79:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f7e:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f81:	e9 97 01 00 00       	jmp    f010111d <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f86:	39 ca                	cmp    %ecx,%edx
f0100f88:	73 24                	jae    f0100fae <check_page_free_list+0x14e>
f0100f8a:	c7 44 24 0c 07 62 10 	movl   $0xf0106207,0xc(%esp)
f0100f91:	f0 
f0100f92:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0100f99:	f0 
f0100f9a:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0100fa1:	00 
f0100fa2:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0100fa9:	e8 08 f1 ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f0100fae:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100fb1:	72 24                	jb     f0100fd7 <check_page_free_list+0x177>
f0100fb3:	c7 44 24 0c 28 62 10 	movl   $0xf0106228,0xc(%esp)
f0100fba:	f0 
f0100fbb:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0100fc2:	f0 
f0100fc3:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f0100fca:	00 
f0100fcb:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0100fd2:	e8 df f0 ff ff       	call   f01000b6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100fd7:	89 d0                	mov    %edx,%eax
f0100fd9:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100fdc:	a8 07                	test   $0x7,%al
f0100fde:	74 24                	je     f0101004 <check_page_free_list+0x1a4>
f0100fe0:	c7 44 24 0c 8c 5a 10 	movl   $0xf0105a8c,0xc(%esp)
f0100fe7:	f0 
f0100fe8:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0100fef:	f0 
f0100ff0:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f0100ff7:	00 
f0100ff8:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0100fff:	e8 b2 f0 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101004:	c1 f8 03             	sar    $0x3,%eax
f0101007:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f010100a:	85 c0                	test   %eax,%eax
f010100c:	75 24                	jne    f0101032 <check_page_free_list+0x1d2>
f010100e:	c7 44 24 0c 3c 62 10 	movl   $0xf010623c,0xc(%esp)
f0101015:	f0 
f0101016:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010101d:	f0 
f010101e:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
f0101025:	00 
f0101026:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010102d:	e8 84 f0 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101032:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101037:	75 24                	jne    f010105d <check_page_free_list+0x1fd>
f0101039:	c7 44 24 0c 4d 62 10 	movl   $0xf010624d,0xc(%esp)
f0101040:	f0 
f0101041:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101048:	f0 
f0101049:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f0101050:	00 
f0101051:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101058:	e8 59 f0 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010105d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101062:	75 24                	jne    f0101088 <check_page_free_list+0x228>
f0101064:	c7 44 24 0c c0 5a 10 	movl   $0xf0105ac0,0xc(%esp)
f010106b:	f0 
f010106c:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101073:	f0 
f0101074:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f010107b:	00 
f010107c:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101083:	e8 2e f0 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101088:	3d 00 00 10 00       	cmp    $0x100000,%eax
f010108d:	75 24                	jne    f01010b3 <check_page_free_list+0x253>
f010108f:	c7 44 24 0c 66 62 10 	movl   $0xf0106266,0xc(%esp)
f0101096:	f0 
f0101097:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010109e:	f0 
f010109f:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f01010a6:	00 
f01010a7:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01010ae:	e8 03 f0 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01010b3:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f01010b8:	76 58                	jbe    f0101112 <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010ba:	89 c3                	mov    %eax,%ebx
f01010bc:	c1 eb 0c             	shr    $0xc,%ebx
f01010bf:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f01010c2:	77 20                	ja     f01010e4 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010c8:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f01010cf:	f0 
f01010d0:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01010d7:	00 
f01010d8:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f01010df:	e8 d2 ef ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f01010e4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010e9:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f01010ec:	76 2a                	jbe    f0101118 <check_page_free_list+0x2b8>
f01010ee:	c7 44 24 0c e4 5a 10 	movl   $0xf0105ae4,0xc(%esp)
f01010f5:	f0 
f01010f6:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01010fd:	f0 
f01010fe:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f0101105:	00 
f0101106:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010110d:	e8 a4 ef ff ff       	call   f01000b6 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0101112:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0101116:	eb 03                	jmp    f010111b <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0101118:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f010111b:	8b 12                	mov    (%edx),%edx
f010111d:	85 d2                	test   %edx,%edx
f010111f:	0f 85 61 fe ff ff    	jne    f0100f86 <check_page_free_list+0x126>
f0101125:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0101128:	85 db                	test   %ebx,%ebx
f010112a:	7f 24                	jg     f0101150 <check_page_free_list+0x2f0>
f010112c:	c7 44 24 0c 80 62 10 	movl   $0xf0106280,0xc(%esp)
f0101133:	f0 
f0101134:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010113b:	f0 
f010113c:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0101143:	00 
f0101144:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010114b:	e8 66 ef ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0101150:	85 ff                	test   %edi,%edi
f0101152:	7f 24                	jg     f0101178 <check_page_free_list+0x318>
f0101154:	c7 44 24 0c 92 62 10 	movl   $0xf0106292,0xc(%esp)
f010115b:	f0 
f010115c:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101163:	f0 
f0101164:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f010116b:	00 
f010116c:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101173:	e8 3e ef ff ff       	call   f01000b6 <_panic>
	cprintf("check_page_free_list() succeeded!\n");
f0101178:	c7 04 24 2c 5b 10 f0 	movl   $0xf0105b2c,(%esp)
f010117f:	e8 f5 27 00 00       	call   f0103979 <cprintf>
f0101184:	eb 29                	jmp    f01011af <check_page_free_list+0x34f>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101186:	a1 e0 e1 17 f0       	mov    0xf017e1e0,%eax
f010118b:	85 c0                	test   %eax,%eax
f010118d:	0f 85 ff fc ff ff    	jne    f0100e92 <check_page_free_list+0x32>
f0101193:	e9 de fc ff ff       	jmp    f0100e76 <check_page_free_list+0x16>
f0101198:	83 3d e0 e1 17 f0 00 	cmpl   $0x0,0xf017e1e0
f010119f:	0f 84 d1 fc ff ff    	je     f0100e76 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01011a5:	be 00 04 00 00       	mov    $0x400,%esi
f01011aa:	e9 31 fd ff ff       	jmp    f0100ee0 <check_page_free_list+0x80>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list() succeeded!\n");
}
f01011af:	83 c4 4c             	add    $0x4c,%esp
f01011b2:	5b                   	pop    %ebx
f01011b3:	5e                   	pop    %esi
f01011b4:	5f                   	pop    %edi
f01011b5:	5d                   	pop    %ebp
f01011b6:	c3                   	ret    

f01011b7 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01011b7:	55                   	push   %ebp
f01011b8:	89 e5                	mov    %esp,%ebp
f01011ba:	57                   	push   %edi
f01011bb:	56                   	push   %esi
f01011bc:	53                   	push   %ebx
	// 
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
f01011bd:	c7 05 e0 e1 17 f0 00 	movl   $0x0,0xf017e1e0
f01011c4:	00 00 00 
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    
f01011c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01011cc:	e8 9f fb ff ff       	call   f0100d70 <boot_alloc>
	int num_iohole = 96;
	for (i = 0; i < npages; i++) {
		if(i == 0){      
			pages[i].pp_ref = 1;
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f01011d1:	8b 35 e4 e1 17 f0    	mov    0xf017e1e4,%esi
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    
f01011d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01011dc:	c1 e8 0c             	shr    $0xc,%eax
	int num_iohole = 96;
	for (i = 0; i < npages; i++) {
		if(i == 0){      
			pages[i].pp_ref = 1;
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f01011df:	8d 7c 06 60          	lea    0x60(%esi,%eax,1),%edi
f01011e3:	8b 1d e0 e1 17 f0    	mov    0xf017e1e0,%ebx
	// free pages!
	size_t i;
	page_free_list = NULL;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    
	int num_iohole = 96;
	for (i = 0; i < npages; i++) {
f01011e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ee:	eb 4b                	jmp    f010123b <page_init+0x84>
		if(i == 0){      
f01011f0:	85 c0                	test   %eax,%eax
f01011f2:	75 0e                	jne    f0101202 <page_init+0x4b>
			pages[i].pp_ref = 1;
f01011f4:	8b 15 ac ee 17 f0    	mov    0xf017eeac,%edx
f01011fa:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
f0101200:	eb 36                	jmp    f0101238 <page_init+0x81>
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f0101202:	39 f0                	cmp    %esi,%eax
f0101204:	72 13                	jb     f0101219 <page_init+0x62>
f0101206:	39 f8                	cmp    %edi,%eax
f0101208:	73 0f                	jae    f0101219 <page_init+0x62>
			pages[i].pp_ref = 1;
f010120a:	8b 15 ac ee 17 f0    	mov    0xf017eeac,%edx
f0101210:	66 c7 44 c2 04 01 00 	movw   $0x1,0x4(%edx,%eax,8)
f0101217:	eb 1f                	jmp    f0101238 <page_init+0x81>
f0101219:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		}
		else {
			pages[i].pp_ref = 0;
f0101220:	89 d1                	mov    %edx,%ecx
f0101222:	03 0d ac ee 17 f0    	add    0xf017eeac,%ecx
f0101228:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f010122e:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f0101230:	89 d3                	mov    %edx,%ebx
f0101232:	03 1d ac ee 17 f0    	add    0xf017eeac,%ebx
	// free pages!
	size_t i;
	page_free_list = NULL;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    
	int num_iohole = 96;
	for (i = 0; i < npages; i++) {
f0101238:	83 c0 01             	add    $0x1,%eax
f010123b:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f0101241:	72 ad                	jb     f01011f0 <page_init+0x39>
f0101243:	89 1d e0 e1 17 f0    	mov    %ebx,0xf017e1e0
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0101249:	5b                   	pop    %ebx
f010124a:	5e                   	pop    %esi
f010124b:	5f                   	pop    %edi
f010124c:	5d                   	pop    %ebp
f010124d:	c3                   	ret    

f010124e <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f010124e:	55                   	push   %ebp
f010124f:	89 e5                	mov    %esp,%ebp
f0101251:	53                   	push   %ebx
f0101252:	83 ec 14             	sub    $0x14,%esp
	if (page_free_list) {
f0101255:	8b 1d e0 e1 17 f0    	mov    0xf017e1e0,%ebx
f010125b:	85 db                	test   %ebx,%ebx
f010125d:	74 6f                	je     f01012ce <page_alloc+0x80>
		struct PageInfo *result = page_free_list;
		page_free_list = page_free_list->pp_link;
f010125f:	8b 03                	mov    (%ebx),%eax
f0101261:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0
		result->pp_link = NULL;
f0101266:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if (alloc_flags & ALLOC_ZERO) 
			memset(page2kva(result), 0, PGSIZE);
		return result;
f010126c:	89 d8                	mov    %ebx,%eax
{
	if (page_free_list) {
		struct PageInfo *result = page_free_list;
		page_free_list = page_free_list->pp_link;
		result->pp_link = NULL;
		if (alloc_flags & ALLOC_ZERO) 
f010126e:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101272:	74 5f                	je     f01012d3 <page_alloc+0x85>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101274:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f010127a:	c1 f8 03             	sar    $0x3,%eax
f010127d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101280:	89 c2                	mov    %eax,%edx
f0101282:	c1 ea 0c             	shr    $0xc,%edx
f0101285:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f010128b:	72 20                	jb     f01012ad <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010128d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101291:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f0101298:	f0 
f0101299:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01012a0:	00 
f01012a1:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f01012a8:	e8 09 ee ff ff       	call   f01000b6 <_panic>
			memset(page2kva(result), 0, PGSIZE);
f01012ad:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012b4:	00 
f01012b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012bc:	00 
	return (void *)(pa + KERNBASE);
f01012bd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012c2:	89 04 24             	mov    %eax,(%esp)
f01012c5:	e8 0d 3c 00 00       	call   f0104ed7 <memset>
		return result;
f01012ca:	89 d8                	mov    %ebx,%eax
f01012cc:	eb 05                	jmp    f01012d3 <page_alloc+0x85>
	}
	return NULL;
f01012ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012d3:	83 c4 14             	add    $0x14,%esp
f01012d6:	5b                   	pop    %ebx
f01012d7:	5d                   	pop    %ebp
f01012d8:	c3                   	ret    

f01012d9 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f01012d9:	55                   	push   %ebp
f01012da:	89 e5                	mov    %esp,%ebp
f01012dc:	8b 45 08             	mov    0x8(%ebp),%eax
	pp->pp_link = page_free_list;
f01012df:	8b 15 e0 e1 17 f0    	mov    0xf017e1e0,%edx
f01012e5:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01012e7:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0
}
f01012ec:	5d                   	pop    %ebp
f01012ed:	c3                   	ret    

f01012ee <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01012ee:	55                   	push   %ebp
f01012ef:	89 e5                	mov    %esp,%ebp
f01012f1:	83 ec 04             	sub    $0x4,%esp
f01012f4:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01012f7:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01012fb:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01012fe:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101302:	66 85 d2             	test   %dx,%dx
f0101305:	75 08                	jne    f010130f <page_decref+0x21>
		page_free(pp);
f0101307:	89 04 24             	mov    %eax,(%esp)
f010130a:	e8 ca ff ff ff       	call   f01012d9 <page_free>
}
f010130f:	c9                   	leave  
f0101310:	c3                   	ret    

f0101311 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101311:	55                   	push   %ebp
f0101312:	89 e5                	mov    %esp,%ebp
f0101314:	56                   	push   %esi
f0101315:	53                   	push   %ebx
f0101316:	83 ec 10             	sub    $0x10,%esp
f0101319:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int page_off;
      	pte_t * page_base = NULL;
      	struct PageInfo* new_page = NULL;
      
      	unsigned int dic_off = PDX(va);
f010131c:	89 f3                	mov    %esi,%ebx
f010131e:	c1 eb 16             	shr    $0x16,%ebx
      	pde_t * dic_entry_ptr = pgdir + dic_off;
f0101321:	c1 e3 02             	shl    $0x2,%ebx
f0101324:	03 5d 08             	add    0x8(%ebp),%ebx

      	if(!(*dic_entry_ptr & PTE_P))
f0101327:	f6 03 01             	testb  $0x1,(%ebx)
f010132a:	75 2c                	jne    f0101358 <pgdir_walk+0x47>
      	{
      	      if(create)
f010132c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101330:	74 6c                	je     f010139e <pgdir_walk+0x8d>
      	      {
      	             new_page = page_alloc(1);
f0101332:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101339:	e8 10 ff ff ff       	call   f010124e <page_alloc>
      	             if(new_page == NULL) return NULL;
f010133e:	85 c0                	test   %eax,%eax
f0101340:	74 63                	je     f01013a5 <pgdir_walk+0x94>
      	             new_page->pp_ref++;
f0101342:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101347:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f010134d:	c1 f8 03             	sar    $0x3,%eax
f0101350:	c1 e0 0c             	shl    $0xc,%eax
      	             *dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
f0101353:	83 c8 07             	or     $0x7,%eax
f0101356:	89 03                	mov    %eax,(%ebx)
      	      }
      	     else
      	         return NULL;      
      	}  
   
      	page_off = PTX(va);
f0101358:	c1 ee 0c             	shr    $0xc,%esi
f010135b:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
      	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f0101361:	8b 03                	mov    (%ebx),%eax
f0101363:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101368:	89 c2                	mov    %eax,%edx
f010136a:	c1 ea 0c             	shr    $0xc,%edx
f010136d:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f0101373:	72 20                	jb     f0101395 <pgdir_walk+0x84>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101375:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101379:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f0101380:	f0 
f0101381:	c7 44 24 04 90 01 00 	movl   $0x190,0x4(%esp)
f0101388:	00 
f0101389:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101390:	e8 21 ed ff ff       	call   f01000b6 <_panic>
      	return &page_base[page_off];
f0101395:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f010139c:	eb 0c                	jmp    f01013aa <pgdir_walk+0x99>
      	             if(new_page == NULL) return NULL;
      	             new_page->pp_ref++;
      	             *dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
      	      }
      	     else
      	         return NULL;      
f010139e:	b8 00 00 00 00       	mov    $0x0,%eax
f01013a3:	eb 05                	jmp    f01013aa <pgdir_walk+0x99>
      	if(!(*dic_entry_ptr & PTE_P))
      	{
      	      if(create)
      	      {
      	             new_page = page_alloc(1);
      	             if(new_page == NULL) return NULL;
f01013a5:	b8 00 00 00 00       	mov    $0x0,%eax
      	}  
   
      	page_off = PTX(va);
      	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
      	return &page_base[page_off];
}	
f01013aa:	83 c4 10             	add    $0x10,%esp
f01013ad:	5b                   	pop    %ebx
f01013ae:	5e                   	pop    %esi
f01013af:	5d                   	pop    %ebp
f01013b0:	c3                   	ret    

f01013b1 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01013b1:	55                   	push   %ebp
f01013b2:	89 e5                	mov    %esp,%ebp
f01013b4:	57                   	push   %edi
f01013b5:	56                   	push   %esi
f01013b6:	53                   	push   %ebx
f01013b7:	83 ec 2c             	sub    $0x2c,%esp
f01013ba:	89 c7                	mov    %eax,%edi
f01013bc:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01013bf:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    int nadd;
    pte_t *entry = NULL;
    for(nadd = 0; nadd < size; nadd += PGSIZE)
f01013c2:	bb 00 00 00 00       	mov    $0x0,%ebx
    {
        entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
        *entry = (pa | perm | PTE_P);
f01013c7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013ca:	83 c8 01             	or     $0x1,%eax
f01013cd:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
    int nadd;
    pte_t *entry = NULL;
    for(nadd = 0; nadd < size; nadd += PGSIZE)
f01013d0:	eb 24                	jmp    f01013f6 <boot_map_region+0x45>
    {
        entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
f01013d2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01013d9:	00 
f01013da:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01013dd:	01 d8                	add    %ebx,%eax
f01013df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013e3:	89 3c 24             	mov    %edi,(%esp)
f01013e6:	e8 26 ff ff ff       	call   f0101311 <pgdir_walk>
        *entry = (pa | perm | PTE_P);
f01013eb:	0b 75 dc             	or     -0x24(%ebp),%esi
f01013ee:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
    int nadd;
    pte_t *entry = NULL;
    for(nadd = 0; nadd < size; nadd += PGSIZE)
f01013f0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01013f6:	89 de                	mov    %ebx,%esi
f01013f8:	03 75 08             	add    0x8(%ebp),%esi
f01013fb:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01013fe:	77 d2                	ja     f01013d2 <boot_map_region+0x21>
        
        pa += PGSIZE;
        va += PGSIZE;
        
    }
}
f0101400:	83 c4 2c             	add    $0x2c,%esp
f0101403:	5b                   	pop    %ebx
f0101404:	5e                   	pop    %esi
f0101405:	5f                   	pop    %edi
f0101406:	5d                   	pop    %ebp
f0101407:	c3                   	ret    

f0101408 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101408:	55                   	push   %ebp
f0101409:	89 e5                	mov    %esp,%ebp
f010140b:	53                   	push   %ebx
f010140c:	83 ec 14             	sub    $0x14,%esp
f010140f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *entry = NULL;
	struct PageInfo *result = NULL;

        entry = pgdir_walk(pgdir, va, 0);
f0101412:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101419:	00 
f010141a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010141d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101421:	8b 45 08             	mov    0x8(%ebp),%eax
f0101424:	89 04 24             	mov    %eax,(%esp)
f0101427:	e8 e5 fe ff ff       	call   f0101311 <pgdir_walk>
f010142c:	89 c2                	mov    %eax,%edx
	if(entry == NULL)
f010142e:	85 c0                	test   %eax,%eax
f0101430:	74 3e                	je     f0101470 <page_lookup+0x68>
		return NULL;
        if(!(*entry & PTE_P))
f0101432:	8b 00                	mov    (%eax),%eax
f0101434:	a8 01                	test   $0x1,%al
f0101436:	74 3f                	je     f0101477 <page_lookup+0x6f>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101438:	c1 e8 0c             	shr    $0xc,%eax
f010143b:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f0101441:	72 1c                	jb     f010145f <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0101443:	c7 44 24 08 50 5b 10 	movl   $0xf0105b50,0x8(%esp)
f010144a:	f0 
f010144b:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0101452:	00 
f0101453:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f010145a:	e8 57 ec ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f010145f:	8b 0d ac ee 17 f0    	mov    0xf017eeac,%ecx
f0101465:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
                return NULL;
    
        result = pa2page(PTE_ADDR(*entry));
        if(pte_store != NULL)
f0101468:	85 db                	test   %ebx,%ebx
f010146a:	74 10                	je     f010147c <page_lookup+0x74>
        {
               *pte_store = entry;
f010146c:	89 13                	mov    %edx,(%ebx)
f010146e:	eb 0c                	jmp    f010147c <page_lookup+0x74>
	pte_t *entry = NULL;
	struct PageInfo *result = NULL;

        entry = pgdir_walk(pgdir, va, 0);
	if(entry == NULL)
		return NULL;
f0101470:	b8 00 00 00 00       	mov    $0x0,%eax
f0101475:	eb 05                	jmp    f010147c <page_lookup+0x74>
        if(!(*entry & PTE_P))
                return NULL;
f0101477:	b8 00 00 00 00       	mov    $0x0,%eax
        if(pte_store != NULL)
        {
               *pte_store = entry;
        }
        return result;	
}
f010147c:	83 c4 14             	add    $0x14,%esp
f010147f:	5b                   	pop    %ebx
f0101480:	5d                   	pop    %ebp
f0101481:	c3                   	ret    

f0101482 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101482:	55                   	push   %ebp
f0101483:	89 e5                	mov    %esp,%ebp
f0101485:	53                   	push   %ebx
f0101486:	83 ec 24             	sub    $0x24,%esp
f0101489:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte = NULL;    
f010148c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &pte);    
f0101493:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101496:	89 44 24 08          	mov    %eax,0x8(%esp)
f010149a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010149e:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a1:	89 04 24             	mov    %eax,(%esp)
f01014a4:	e8 5f ff ff ff       	call   f0101408 <page_lookup>
	if(page == NULL) return ;    
f01014a9:	85 c0                	test   %eax,%eax
f01014ab:	74 14                	je     f01014c1 <page_remove+0x3f>
        page_decref(page);
f01014ad:	89 04 24             	mov    %eax,(%esp)
f01014b0:	e8 39 fe ff ff       	call   f01012ee <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01014b5:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
	*pte = 0;
f01014b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014bb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f01014c1:	83 c4 24             	add    $0x24,%esp
f01014c4:	5b                   	pop    %ebx
f01014c5:	5d                   	pop    %ebp
f01014c6:	c3                   	ret    

f01014c7 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01014c7:	55                   	push   %ebp
f01014c8:	89 e5                	mov    %esp,%ebp
f01014ca:	57                   	push   %edi
f01014cb:	56                   	push   %esi
f01014cc:	53                   	push   %ebx
f01014cd:	83 ec 1c             	sub    $0x1c,%esp
f01014d0:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014d3:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *entry = NULL;
    	entry =  pgdir_walk(pgdir, va, 1);   
f01014d6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01014dd:	00 
f01014de:	8b 45 10             	mov    0x10(%ebp),%eax
f01014e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014e5:	89 1c 24             	mov    %ebx,(%esp)
f01014e8:	e8 24 fe ff ff       	call   f0101311 <pgdir_walk>
f01014ed:	89 c6                	mov    %eax,%esi
    	if(entry == NULL) return -E_NO_MEM;
f01014ef:	85 c0                	test   %eax,%eax
f01014f1:	74 48                	je     f010153b <page_insert+0x74>

    	pp->pp_ref++;
f01014f3:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
    	if((*entry) & PTE_P)            
f01014f8:	f6 00 01             	testb  $0x1,(%eax)
f01014fb:	74 15                	je     f0101512 <page_insert+0x4b>
f01014fd:	8b 45 10             	mov    0x10(%ebp),%eax
f0101500:	0f 01 38             	invlpg (%eax)
    	{
    	    tlb_invalidate(pgdir, va);
    	    page_remove(pgdir, va);
f0101503:	8b 45 10             	mov    0x10(%ebp),%eax
f0101506:	89 44 24 04          	mov    %eax,0x4(%esp)
f010150a:	89 1c 24             	mov    %ebx,(%esp)
f010150d:	e8 70 ff ff ff       	call   f0101482 <page_remove>
    	}
    	*entry = (page2pa(pp) | perm | PTE_P);
f0101512:	8b 45 14             	mov    0x14(%ebp),%eax
f0101515:	83 c8 01             	or     $0x1,%eax
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101518:	2b 3d ac ee 17 f0    	sub    0xf017eeac,%edi
f010151e:	c1 ff 03             	sar    $0x3,%edi
f0101521:	c1 e7 0c             	shl    $0xc,%edi
f0101524:	09 c7                	or     %eax,%edi
f0101526:	89 3e                	mov    %edi,(%esi)
    	pgdir[PDX(va)] |= perm;                 
f0101528:	8b 45 10             	mov    0x10(%ebp),%eax
f010152b:	c1 e8 16             	shr    $0x16,%eax
f010152e:	8b 55 14             	mov    0x14(%ebp),%edx
f0101531:	09 14 83             	or     %edx,(%ebx,%eax,4)
        
    	return 0;
f0101534:	b8 00 00 00 00       	mov    $0x0,%eax
f0101539:	eb 05                	jmp    f0101540 <page_insert+0x79>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *entry = NULL;
    	entry =  pgdir_walk(pgdir, va, 1);   
    	if(entry == NULL) return -E_NO_MEM;
f010153b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    	}
    	*entry = (page2pa(pp) | perm | PTE_P);
    	pgdir[PDX(va)] |= perm;                 
        
    	return 0;
}
f0101540:	83 c4 1c             	add    $0x1c,%esp
f0101543:	5b                   	pop    %ebx
f0101544:	5e                   	pop    %esi
f0101545:	5f                   	pop    %edi
f0101546:	5d                   	pop    %ebp
f0101547:	c3                   	ret    

f0101548 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101548:	55                   	push   %ebp
f0101549:	89 e5                	mov    %esp,%ebp
f010154b:	57                   	push   %edi
f010154c:	56                   	push   %esi
f010154d:	53                   	push   %ebx
f010154e:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101551:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0101558:	e8 ac 23 00 00       	call   f0103909 <mc146818_read>
f010155d:	89 c3                	mov    %eax,%ebx
f010155f:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101566:	e8 9e 23 00 00       	call   f0103909 <mc146818_read>
f010156b:	c1 e0 08             	shl    $0x8,%eax
f010156e:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101570:	89 d8                	mov    %ebx,%eax
f0101572:	c1 e0 0a             	shl    $0xa,%eax
f0101575:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010157b:	85 c0                	test   %eax,%eax
f010157d:	0f 48 c2             	cmovs  %edx,%eax
f0101580:	c1 f8 0c             	sar    $0xc,%eax
f0101583:	a3 e4 e1 17 f0       	mov    %eax,0xf017e1e4
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101588:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010158f:	e8 75 23 00 00       	call   f0103909 <mc146818_read>
f0101594:	89 c3                	mov    %eax,%ebx
f0101596:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010159d:	e8 67 23 00 00       	call   f0103909 <mc146818_read>
f01015a2:	c1 e0 08             	shl    $0x8,%eax
f01015a5:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01015a7:	89 d8                	mov    %ebx,%eax
f01015a9:	c1 e0 0a             	shl    $0xa,%eax
f01015ac:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01015b2:	85 c0                	test   %eax,%eax
f01015b4:	0f 48 c2             	cmovs  %edx,%eax
f01015b7:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01015ba:	85 c0                	test   %eax,%eax
f01015bc:	74 0e                	je     f01015cc <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01015be:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01015c4:	89 15 a4 ee 17 f0    	mov    %edx,0xf017eea4
f01015ca:	eb 0c                	jmp    f01015d8 <mem_init+0x90>
	else
		npages = npages_basemem;
f01015cc:	8b 15 e4 e1 17 f0    	mov    0xf017e1e4,%edx
f01015d2:	89 15 a4 ee 17 f0    	mov    %edx,0xf017eea4

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01015d8:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01015db:	c1 e8 0a             	shr    $0xa,%eax
f01015de:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01015e2:	a1 e4 e1 17 f0       	mov    0xf017e1e4,%eax
f01015e7:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01015ea:	c1 e8 0a             	shr    $0xa,%eax
f01015ed:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01015f1:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f01015f6:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01015f9:	c1 e8 0a             	shr    $0xa,%eax
f01015fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101600:	c7 04 24 70 5b 10 f0 	movl   $0xf0105b70,(%esp)
f0101607:	e8 6d 23 00 00       	call   f0103979 <cprintf>
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010160c:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101611:	e8 5a f7 ff ff       	call   f0100d70 <boot_alloc>
f0101616:	a3 a8 ee 17 f0       	mov    %eax,0xf017eea8
	memset(kern_pgdir, 0, PGSIZE);
f010161b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101622:	00 
f0101623:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010162a:	00 
f010162b:	89 04 24             	mov    %eax,(%esp)
f010162e:	e8 a4 38 00 00       	call   f0104ed7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101633:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101638:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010163d:	77 20                	ja     f010165f <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010163f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101643:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f010164a:	f0 
f010164b:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0101652:	00 
f0101653:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010165a:	e8 57 ea ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010165f:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101665:	83 ca 05             	or     $0x5,%edx
f0101668:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo) * npages);
f010166e:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f0101673:	c1 e0 03             	shl    $0x3,%eax
f0101676:	e8 f5 f6 ff ff       	call   f0100d70 <boot_alloc>
f010167b:	a3 ac ee 17 f0       	mov    %eax,0xf017eeac

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f0101680:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101685:	e8 e6 f6 ff ff       	call   f0100d70 <boot_alloc>
f010168a:	a3 ec e1 17 f0       	mov    %eax,0xf017e1ec
	memset(envs, 0, NENV * sizeof(struct Env));
f010168f:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f0101696:	00 
f0101697:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010169e:	00 
f010169f:	89 04 24             	mov    %eax,(%esp)
f01016a2:	e8 30 38 00 00       	call   f0104ed7 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01016a7:	e8 0b fb ff ff       	call   f01011b7 <page_init>

	check_page_free_list(1);
f01016ac:	b8 01 00 00 00       	mov    $0x1,%eax
f01016b1:	e8 aa f7 ff ff       	call   f0100e60 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01016b6:	83 3d ac ee 17 f0 00 	cmpl   $0x0,0xf017eeac
f01016bd:	75 1c                	jne    f01016db <mem_init+0x193>
		panic("'pages' is a null pointer!");
f01016bf:	c7 44 24 08 a3 62 10 	movl   $0xf01062a3,0x8(%esp)
f01016c6:	f0 
f01016c7:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f01016ce:	00 
f01016cf:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01016d6:	e8 db e9 ff ff       	call   f01000b6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01016db:	a1 e0 e1 17 f0       	mov    0xf017e1e0,%eax
f01016e0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016e5:	eb 05                	jmp    f01016ec <mem_init+0x1a4>
		++nfree;
f01016e7:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01016ea:	8b 00                	mov    (%eax),%eax
f01016ec:	85 c0                	test   %eax,%eax
f01016ee:	75 f7                	jne    f01016e7 <mem_init+0x19f>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016f7:	e8 52 fb ff ff       	call   f010124e <page_alloc>
f01016fc:	89 c7                	mov    %eax,%edi
f01016fe:	85 c0                	test   %eax,%eax
f0101700:	75 24                	jne    f0101726 <mem_init+0x1de>
f0101702:	c7 44 24 0c be 62 10 	movl   $0xf01062be,0xc(%esp)
f0101709:	f0 
f010170a:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101711:	f0 
f0101712:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
f0101719:	00 
f010171a:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101721:	e8 90 e9 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101726:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010172d:	e8 1c fb ff ff       	call   f010124e <page_alloc>
f0101732:	89 c6                	mov    %eax,%esi
f0101734:	85 c0                	test   %eax,%eax
f0101736:	75 24                	jne    f010175c <mem_init+0x214>
f0101738:	c7 44 24 0c d4 62 10 	movl   $0xf01062d4,0xc(%esp)
f010173f:	f0 
f0101740:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101747:	f0 
f0101748:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
f010174f:	00 
f0101750:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101757:	e8 5a e9 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f010175c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101763:	e8 e6 fa ff ff       	call   f010124e <page_alloc>
f0101768:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010176b:	85 c0                	test   %eax,%eax
f010176d:	75 24                	jne    f0101793 <mem_init+0x24b>
f010176f:	c7 44 24 0c ea 62 10 	movl   $0xf01062ea,0xc(%esp)
f0101776:	f0 
f0101777:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010177e:	f0 
f010177f:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0101786:	00 
f0101787:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010178e:	e8 23 e9 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101793:	39 f7                	cmp    %esi,%edi
f0101795:	75 24                	jne    f01017bb <mem_init+0x273>
f0101797:	c7 44 24 0c 00 63 10 	movl   $0xf0106300,0xc(%esp)
f010179e:	f0 
f010179f:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01017a6:	f0 
f01017a7:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f01017ae:	00 
f01017af:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01017b6:	e8 fb e8 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017bb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017be:	39 c6                	cmp    %eax,%esi
f01017c0:	74 04                	je     f01017c6 <mem_init+0x27e>
f01017c2:	39 c7                	cmp    %eax,%edi
f01017c4:	75 24                	jne    f01017ea <mem_init+0x2a2>
f01017c6:	c7 44 24 0c d0 5b 10 	movl   $0xf0105bd0,0xc(%esp)
f01017cd:	f0 
f01017ce:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01017d5:	f0 
f01017d6:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f01017dd:	00 
f01017de:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01017e5:	e8 cc e8 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017ea:	8b 15 ac ee 17 f0    	mov    0xf017eeac,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01017f0:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f01017f5:	c1 e0 0c             	shl    $0xc,%eax
f01017f8:	89 f9                	mov    %edi,%ecx
f01017fa:	29 d1                	sub    %edx,%ecx
f01017fc:	c1 f9 03             	sar    $0x3,%ecx
f01017ff:	c1 e1 0c             	shl    $0xc,%ecx
f0101802:	39 c1                	cmp    %eax,%ecx
f0101804:	72 24                	jb     f010182a <mem_init+0x2e2>
f0101806:	c7 44 24 0c 12 63 10 	movl   $0xf0106312,0xc(%esp)
f010180d:	f0 
f010180e:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101815:	f0 
f0101816:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f010181d:	00 
f010181e:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101825:	e8 8c e8 ff ff       	call   f01000b6 <_panic>
f010182a:	89 f1                	mov    %esi,%ecx
f010182c:	29 d1                	sub    %edx,%ecx
f010182e:	c1 f9 03             	sar    $0x3,%ecx
f0101831:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101834:	39 c8                	cmp    %ecx,%eax
f0101836:	77 24                	ja     f010185c <mem_init+0x314>
f0101838:	c7 44 24 0c 2f 63 10 	movl   $0xf010632f,0xc(%esp)
f010183f:	f0 
f0101840:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101847:	f0 
f0101848:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f010184f:	00 
f0101850:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101857:	e8 5a e8 ff ff       	call   f01000b6 <_panic>
f010185c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010185f:	29 d1                	sub    %edx,%ecx
f0101861:	89 ca                	mov    %ecx,%edx
f0101863:	c1 fa 03             	sar    $0x3,%edx
f0101866:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101869:	39 d0                	cmp    %edx,%eax
f010186b:	77 24                	ja     f0101891 <mem_init+0x349>
f010186d:	c7 44 24 0c 4c 63 10 	movl   $0xf010634c,0xc(%esp)
f0101874:	f0 
f0101875:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010187c:	f0 
f010187d:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
f0101884:	00 
f0101885:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010188c:	e8 25 e8 ff ff       	call   f01000b6 <_panic>


	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101891:	a1 e0 e1 17 f0       	mov    0xf017e1e0,%eax
f0101896:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101899:	c7 05 e0 e1 17 f0 00 	movl   $0x0,0xf017e1e0
f01018a0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018a3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018aa:	e8 9f f9 ff ff       	call   f010124e <page_alloc>
f01018af:	85 c0                	test   %eax,%eax
f01018b1:	74 24                	je     f01018d7 <mem_init+0x38f>
f01018b3:	c7 44 24 0c 69 63 10 	movl   $0xf0106369,0xc(%esp)
f01018ba:	f0 
f01018bb:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01018c2:	f0 
f01018c3:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f01018ca:	00 
f01018cb:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01018d2:	e8 df e7 ff ff       	call   f01000b6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01018d7:	89 3c 24             	mov    %edi,(%esp)
f01018da:	e8 fa f9 ff ff       	call   f01012d9 <page_free>
	page_free(pp1);
f01018df:	89 34 24             	mov    %esi,(%esp)
f01018e2:	e8 f2 f9 ff ff       	call   f01012d9 <page_free>
	page_free(pp2);
f01018e7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018ea:	89 04 24             	mov    %eax,(%esp)
f01018ed:	e8 e7 f9 ff ff       	call   f01012d9 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018f9:	e8 50 f9 ff ff       	call   f010124e <page_alloc>
f01018fe:	89 c6                	mov    %eax,%esi
f0101900:	85 c0                	test   %eax,%eax
f0101902:	75 24                	jne    f0101928 <mem_init+0x3e0>
f0101904:	c7 44 24 0c be 62 10 	movl   $0xf01062be,0xc(%esp)
f010190b:	f0 
f010190c:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101913:	f0 
f0101914:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f010191b:	00 
f010191c:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101923:	e8 8e e7 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101928:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010192f:	e8 1a f9 ff ff       	call   f010124e <page_alloc>
f0101934:	89 c7                	mov    %eax,%edi
f0101936:	85 c0                	test   %eax,%eax
f0101938:	75 24                	jne    f010195e <mem_init+0x416>
f010193a:	c7 44 24 0c d4 62 10 	movl   $0xf01062d4,0xc(%esp)
f0101941:	f0 
f0101942:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101949:	f0 
f010194a:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101951:	00 
f0101952:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101959:	e8 58 e7 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f010195e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101965:	e8 e4 f8 ff ff       	call   f010124e <page_alloc>
f010196a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010196d:	85 c0                	test   %eax,%eax
f010196f:	75 24                	jne    f0101995 <mem_init+0x44d>
f0101971:	c7 44 24 0c ea 62 10 	movl   $0xf01062ea,0xc(%esp)
f0101978:	f0 
f0101979:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101980:	f0 
f0101981:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f0101988:	00 
f0101989:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101990:	e8 21 e7 ff ff       	call   f01000b6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101995:	39 fe                	cmp    %edi,%esi
f0101997:	75 24                	jne    f01019bd <mem_init+0x475>
f0101999:	c7 44 24 0c 00 63 10 	movl   $0xf0106300,0xc(%esp)
f01019a0:	f0 
f01019a1:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01019a8:	f0 
f01019a9:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f01019b0:	00 
f01019b1:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01019b8:	e8 f9 e6 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019c0:	39 c7                	cmp    %eax,%edi
f01019c2:	74 04                	je     f01019c8 <mem_init+0x480>
f01019c4:	39 c6                	cmp    %eax,%esi
f01019c6:	75 24                	jne    f01019ec <mem_init+0x4a4>
f01019c8:	c7 44 24 0c d0 5b 10 	movl   $0xf0105bd0,0xc(%esp)
f01019cf:	f0 
f01019d0:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01019d7:	f0 
f01019d8:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f01019df:	00 
f01019e0:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01019e7:	e8 ca e6 ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f01019ec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019f3:	e8 56 f8 ff ff       	call   f010124e <page_alloc>
f01019f8:	85 c0                	test   %eax,%eax
f01019fa:	74 24                	je     f0101a20 <mem_init+0x4d8>
f01019fc:	c7 44 24 0c 69 63 10 	movl   $0xf0106369,0xc(%esp)
f0101a03:	f0 
f0101a04:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101a0b:	f0 
f0101a0c:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f0101a13:	00 
f0101a14:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101a1b:	e8 96 e6 ff ff       	call   f01000b6 <_panic>
f0101a20:	89 f0                	mov    %esi,%eax
f0101a22:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f0101a28:	c1 f8 03             	sar    $0x3,%eax
f0101a2b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a2e:	89 c2                	mov    %eax,%edx
f0101a30:	c1 ea 0c             	shr    $0xc,%edx
f0101a33:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f0101a39:	72 20                	jb     f0101a5b <mem_init+0x513>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a3b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101a3f:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f0101a46:	f0 
f0101a47:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101a4e:	00 
f0101a4f:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f0101a56:	e8 5b e6 ff ff       	call   f01000b6 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101a5b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101a62:	00 
f0101a63:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101a6a:	00 
	return (void *)(pa + KERNBASE);
f0101a6b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a70:	89 04 24             	mov    %eax,(%esp)
f0101a73:	e8 5f 34 00 00       	call   f0104ed7 <memset>
	page_free(pp0);
f0101a78:	89 34 24             	mov    %esi,(%esp)
f0101a7b:	e8 59 f8 ff ff       	call   f01012d9 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101a80:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101a87:	e8 c2 f7 ff ff       	call   f010124e <page_alloc>
f0101a8c:	85 c0                	test   %eax,%eax
f0101a8e:	75 24                	jne    f0101ab4 <mem_init+0x56c>
f0101a90:	c7 44 24 0c 78 63 10 	movl   $0xf0106378,0xc(%esp)
f0101a97:	f0 
f0101a98:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101a9f:	f0 
f0101aa0:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0101aa7:	00 
f0101aa8:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101aaf:	e8 02 e6 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f0101ab4:	39 c6                	cmp    %eax,%esi
f0101ab6:	74 24                	je     f0101adc <mem_init+0x594>
f0101ab8:	c7 44 24 0c 96 63 10 	movl   $0xf0106396,0xc(%esp)
f0101abf:	f0 
f0101ac0:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101ac7:	f0 
f0101ac8:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
f0101acf:	00 
f0101ad0:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101ad7:	e8 da e5 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101adc:	89 f0                	mov    %esi,%eax
f0101ade:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f0101ae4:	c1 f8 03             	sar    $0x3,%eax
f0101ae7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101aea:	89 c2                	mov    %eax,%edx
f0101aec:	c1 ea 0c             	shr    $0xc,%edx
f0101aef:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f0101af5:	72 20                	jb     f0101b17 <mem_init+0x5cf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101af7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101afb:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f0101b02:	f0 
f0101b03:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101b0a:	00 
f0101b0b:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f0101b12:	e8 9f e5 ff ff       	call   f01000b6 <_panic>
f0101b17:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101b1d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101b23:	80 38 00             	cmpb   $0x0,(%eax)
f0101b26:	74 24                	je     f0101b4c <mem_init+0x604>
f0101b28:	c7 44 24 0c a6 63 10 	movl   $0xf01063a6,0xc(%esp)
f0101b2f:	f0 
f0101b30:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101b37:	f0 
f0101b38:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f0101b3f:	00 
f0101b40:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101b47:	e8 6a e5 ff ff       	call   f01000b6 <_panic>
f0101b4c:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101b4f:	39 d0                	cmp    %edx,%eax
f0101b51:	75 d0                	jne    f0101b23 <mem_init+0x5db>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101b53:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b56:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0

	// free the pages we took
	page_free(pp0);
f0101b5b:	89 34 24             	mov    %esi,(%esp)
f0101b5e:	e8 76 f7 ff ff       	call   f01012d9 <page_free>
	page_free(pp1);
f0101b63:	89 3c 24             	mov    %edi,(%esp)
f0101b66:	e8 6e f7 ff ff       	call   f01012d9 <page_free>
	page_free(pp2);
f0101b6b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b6e:	89 04 24             	mov    %eax,(%esp)
f0101b71:	e8 63 f7 ff ff       	call   f01012d9 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101b76:	a1 e0 e1 17 f0       	mov    0xf017e1e0,%eax
f0101b7b:	eb 05                	jmp    f0101b82 <mem_init+0x63a>
		--nfree;
f0101b7d:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101b80:	8b 00                	mov    (%eax),%eax
f0101b82:	85 c0                	test   %eax,%eax
f0101b84:	75 f7                	jne    f0101b7d <mem_init+0x635>
		--nfree;
	assert(nfree == 0);
f0101b86:	85 db                	test   %ebx,%ebx
f0101b88:	74 24                	je     f0101bae <mem_init+0x666>
f0101b8a:	c7 44 24 0c b0 63 10 	movl   $0xf01063b0,0xc(%esp)
f0101b91:	f0 
f0101b92:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101b99:	f0 
f0101b9a:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f0101ba1:	00 
f0101ba2:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101ba9:	e8 08 e5 ff ff       	call   f01000b6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101bae:	c7 04 24 f0 5b 10 f0 	movl   $0xf0105bf0,(%esp)
f0101bb5:	e8 bf 1d 00 00       	call   f0103979 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101bba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bc1:	e8 88 f6 ff ff       	call   f010124e <page_alloc>
f0101bc6:	89 c6                	mov    %eax,%esi
f0101bc8:	85 c0                	test   %eax,%eax
f0101bca:	75 24                	jne    f0101bf0 <mem_init+0x6a8>
f0101bcc:	c7 44 24 0c be 62 10 	movl   $0xf01062be,0xc(%esp)
f0101bd3:	f0 
f0101bd4:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101bdb:	f0 
f0101bdc:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101be3:	00 
f0101be4:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101beb:	e8 c6 e4 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101bf0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bf7:	e8 52 f6 ff ff       	call   f010124e <page_alloc>
f0101bfc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101bff:	85 c0                	test   %eax,%eax
f0101c01:	75 24                	jne    f0101c27 <mem_init+0x6df>
f0101c03:	c7 44 24 0c d4 62 10 	movl   $0xf01062d4,0xc(%esp)
f0101c0a:	f0 
f0101c0b:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101c12:	f0 
f0101c13:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101c1a:	00 
f0101c1b:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101c22:	e8 8f e4 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101c27:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c2e:	e8 1b f6 ff ff       	call   f010124e <page_alloc>
f0101c33:	89 c3                	mov    %eax,%ebx
f0101c35:	85 c0                	test   %eax,%eax
f0101c37:	75 24                	jne    f0101c5d <mem_init+0x715>
f0101c39:	c7 44 24 0c ea 62 10 	movl   $0xf01062ea,0xc(%esp)
f0101c40:	f0 
f0101c41:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101c48:	f0 
f0101c49:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101c50:	00 
f0101c51:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101c58:	e8 59 e4 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101c5d:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101c60:	75 24                	jne    f0101c86 <mem_init+0x73e>
f0101c62:	c7 44 24 0c 00 63 10 	movl   $0xf0106300,0xc(%esp)
f0101c69:	f0 
f0101c6a:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101c71:	f0 
f0101c72:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101c79:	00 
f0101c7a:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101c81:	e8 30 e4 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c86:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101c89:	74 04                	je     f0101c8f <mem_init+0x747>
f0101c8b:	39 c6                	cmp    %eax,%esi
f0101c8d:	75 24                	jne    f0101cb3 <mem_init+0x76b>
f0101c8f:	c7 44 24 0c d0 5b 10 	movl   $0xf0105bd0,0xc(%esp)
f0101c96:	f0 
f0101c97:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101c9e:	f0 
f0101c9f:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0101ca6:	00 
f0101ca7:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101cae:	e8 03 e4 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101cb3:	a1 e0 e1 17 f0       	mov    0xf017e1e0,%eax
f0101cb8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101cbb:	c7 05 e0 e1 17 f0 00 	movl   $0x0,0xf017e1e0
f0101cc2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101cc5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ccc:	e8 7d f5 ff ff       	call   f010124e <page_alloc>
f0101cd1:	85 c0                	test   %eax,%eax
f0101cd3:	74 24                	je     f0101cf9 <mem_init+0x7b1>
f0101cd5:	c7 44 24 0c 69 63 10 	movl   $0xf0106369,0xc(%esp)
f0101cdc:	f0 
f0101cdd:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101ce4:	f0 
f0101ce5:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0101cec:	00 
f0101ced:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101cf4:	e8 bd e3 ff ff       	call   f01000b6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101cf9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101cfc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101d00:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101d07:	00 
f0101d08:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101d0d:	89 04 24             	mov    %eax,(%esp)
f0101d10:	e8 f3 f6 ff ff       	call   f0101408 <page_lookup>
f0101d15:	85 c0                	test   %eax,%eax
f0101d17:	74 24                	je     f0101d3d <mem_init+0x7f5>
f0101d19:	c7 44 24 0c 10 5c 10 	movl   $0xf0105c10,0xc(%esp)
f0101d20:	f0 
f0101d21:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101d28:	f0 
f0101d29:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101d30:	00 
f0101d31:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101d38:	e8 79 e3 ff ff       	call   f01000b6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101d3d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d44:	00 
f0101d45:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d4c:	00 
f0101d4d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d50:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101d54:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101d59:	89 04 24             	mov    %eax,(%esp)
f0101d5c:	e8 66 f7 ff ff       	call   f01014c7 <page_insert>
f0101d61:	85 c0                	test   %eax,%eax
f0101d63:	78 24                	js     f0101d89 <mem_init+0x841>
f0101d65:	c7 44 24 0c 48 5c 10 	movl   $0xf0105c48,0xc(%esp)
f0101d6c:	f0 
f0101d6d:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101d74:	f0 
f0101d75:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101d7c:	00 
f0101d7d:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101d84:	e8 2d e3 ff ff       	call   f01000b6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101d89:	89 34 24             	mov    %esi,(%esp)
f0101d8c:	e8 48 f5 ff ff       	call   f01012d9 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101d91:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d98:	00 
f0101d99:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101da0:	00 
f0101da1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101da4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101da8:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101dad:	89 04 24             	mov    %eax,(%esp)
f0101db0:	e8 12 f7 ff ff       	call   f01014c7 <page_insert>
f0101db5:	85 c0                	test   %eax,%eax
f0101db7:	74 24                	je     f0101ddd <mem_init+0x895>
f0101db9:	c7 44 24 0c 78 5c 10 	movl   $0xf0105c78,0xc(%esp)
f0101dc0:	f0 
f0101dc1:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101dc8:	f0 
f0101dc9:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0101dd0:	00 
f0101dd1:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101dd8:	e8 d9 e2 ff ff       	call   f01000b6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ddd:	8b 3d a8 ee 17 f0    	mov    0xf017eea8,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101de3:	a1 ac ee 17 f0       	mov    0xf017eeac,%eax
f0101de8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101deb:	8b 17                	mov    (%edi),%edx
f0101ded:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101df3:	89 f1                	mov    %esi,%ecx
f0101df5:	29 c1                	sub    %eax,%ecx
f0101df7:	89 c8                	mov    %ecx,%eax
f0101df9:	c1 f8 03             	sar    $0x3,%eax
f0101dfc:	c1 e0 0c             	shl    $0xc,%eax
f0101dff:	39 c2                	cmp    %eax,%edx
f0101e01:	74 24                	je     f0101e27 <mem_init+0x8df>
f0101e03:	c7 44 24 0c a8 5c 10 	movl   $0xf0105ca8,0xc(%esp)
f0101e0a:	f0 
f0101e0b:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101e12:	f0 
f0101e13:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101e1a:	00 
f0101e1b:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101e22:	e8 8f e2 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101e27:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e2c:	89 f8                	mov    %edi,%eax
f0101e2e:	e8 be ef ff ff       	call   f0100df1 <check_va2pa>
f0101e33:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101e36:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101e39:	c1 fa 03             	sar    $0x3,%edx
f0101e3c:	c1 e2 0c             	shl    $0xc,%edx
f0101e3f:	39 d0                	cmp    %edx,%eax
f0101e41:	74 24                	je     f0101e67 <mem_init+0x91f>
f0101e43:	c7 44 24 0c d0 5c 10 	movl   $0xf0105cd0,0xc(%esp)
f0101e4a:	f0 
f0101e4b:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101e52:	f0 
f0101e53:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0101e5a:	00 
f0101e5b:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101e62:	e8 4f e2 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0101e67:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e6a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e6f:	74 24                	je     f0101e95 <mem_init+0x94d>
f0101e71:	c7 44 24 0c bb 63 10 	movl   $0xf01063bb,0xc(%esp)
f0101e78:	f0 
f0101e79:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101e80:	f0 
f0101e81:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0101e88:	00 
f0101e89:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101e90:	e8 21 e2 ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0101e95:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e9a:	74 24                	je     f0101ec0 <mem_init+0x978>
f0101e9c:	c7 44 24 0c cc 63 10 	movl   $0xf01063cc,0xc(%esp)
f0101ea3:	f0 
f0101ea4:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101eab:	f0 
f0101eac:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f0101eb3:	00 
f0101eb4:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101ebb:	e8 f6 e1 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ec0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ec7:	00 
f0101ec8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ecf:	00 
f0101ed0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ed4:	89 3c 24             	mov    %edi,(%esp)
f0101ed7:	e8 eb f5 ff ff       	call   f01014c7 <page_insert>
f0101edc:	85 c0                	test   %eax,%eax
f0101ede:	74 24                	je     f0101f04 <mem_init+0x9bc>
f0101ee0:	c7 44 24 0c 00 5d 10 	movl   $0xf0105d00,0xc(%esp)
f0101ee7:	f0 
f0101ee8:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101eef:	f0 
f0101ef0:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0101ef7:	00 
f0101ef8:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101eff:	e8 b2 e1 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f04:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f09:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101f0e:	e8 de ee ff ff       	call   f0100df1 <check_va2pa>
f0101f13:	89 da                	mov    %ebx,%edx
f0101f15:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f0101f1b:	c1 fa 03             	sar    $0x3,%edx
f0101f1e:	c1 e2 0c             	shl    $0xc,%edx
f0101f21:	39 d0                	cmp    %edx,%eax
f0101f23:	74 24                	je     f0101f49 <mem_init+0xa01>
f0101f25:	c7 44 24 0c 3c 5d 10 	movl   $0xf0105d3c,0xc(%esp)
f0101f2c:	f0 
f0101f2d:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101f34:	f0 
f0101f35:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0101f3c:	00 
f0101f3d:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101f44:	e8 6d e1 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101f49:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f4e:	74 24                	je     f0101f74 <mem_init+0xa2c>
f0101f50:	c7 44 24 0c dd 63 10 	movl   $0xf01063dd,0xc(%esp)
f0101f57:	f0 
f0101f58:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101f5f:	f0 
f0101f60:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0101f67:	00 
f0101f68:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101f6f:	e8 42 e1 ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f74:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f7b:	e8 ce f2 ff ff       	call   f010124e <page_alloc>
f0101f80:	85 c0                	test   %eax,%eax
f0101f82:	74 24                	je     f0101fa8 <mem_init+0xa60>
f0101f84:	c7 44 24 0c 69 63 10 	movl   $0xf0106369,0xc(%esp)
f0101f8b:	f0 
f0101f8c:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101f93:	f0 
f0101f94:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f0101f9b:	00 
f0101f9c:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101fa3:	e8 0e e1 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101fa8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101faf:	00 
f0101fb0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fb7:	00 
f0101fb8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101fbc:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101fc1:	89 04 24             	mov    %eax,(%esp)
f0101fc4:	e8 fe f4 ff ff       	call   f01014c7 <page_insert>
f0101fc9:	85 c0                	test   %eax,%eax
f0101fcb:	74 24                	je     f0101ff1 <mem_init+0xaa9>
f0101fcd:	c7 44 24 0c 00 5d 10 	movl   $0xf0105d00,0xc(%esp)
f0101fd4:	f0 
f0101fd5:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0101fdc:	f0 
f0101fdd:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0101fe4:	00 
f0101fe5:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0101fec:	e8 c5 e0 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ff1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ff6:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101ffb:	e8 f1 ed ff ff       	call   f0100df1 <check_va2pa>
f0102000:	89 da                	mov    %ebx,%edx
f0102002:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f0102008:	c1 fa 03             	sar    $0x3,%edx
f010200b:	c1 e2 0c             	shl    $0xc,%edx
f010200e:	39 d0                	cmp    %edx,%eax
f0102010:	74 24                	je     f0102036 <mem_init+0xaee>
f0102012:	c7 44 24 0c 3c 5d 10 	movl   $0xf0105d3c,0xc(%esp)
f0102019:	f0 
f010201a:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102021:	f0 
f0102022:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0102029:	00 
f010202a:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102031:	e8 80 e0 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102036:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010203b:	74 24                	je     f0102061 <mem_init+0xb19>
f010203d:	c7 44 24 0c dd 63 10 	movl   $0xf01063dd,0xc(%esp)
f0102044:	f0 
f0102045:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010204c:	f0 
f010204d:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0102054:	00 
f0102055:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010205c:	e8 55 e0 ff ff       	call   f01000b6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0102061:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102068:	e8 e1 f1 ff ff       	call   f010124e <page_alloc>
f010206d:	85 c0                	test   %eax,%eax
f010206f:	74 24                	je     f0102095 <mem_init+0xb4d>
f0102071:	c7 44 24 0c 69 63 10 	movl   $0xf0106369,0xc(%esp)
f0102078:	f0 
f0102079:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102080:	f0 
f0102081:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f0102088:	00 
f0102089:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102090:	e8 21 e0 ff ff       	call   f01000b6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0102095:	8b 15 a8 ee 17 f0    	mov    0xf017eea8,%edx
f010209b:	8b 02                	mov    (%edx),%eax
f010209d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020a2:	89 c1                	mov    %eax,%ecx
f01020a4:	c1 e9 0c             	shr    $0xc,%ecx
f01020a7:	3b 0d a4 ee 17 f0    	cmp    0xf017eea4,%ecx
f01020ad:	72 20                	jb     f01020cf <mem_init+0xb87>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020af:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01020b3:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f01020ba:	f0 
f01020bb:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f01020c2:	00 
f01020c3:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01020ca:	e8 e7 df ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f01020cf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020d4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01020d7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020de:	00 
f01020df:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020e6:	00 
f01020e7:	89 14 24             	mov    %edx,(%esp)
f01020ea:	e8 22 f2 ff ff       	call   f0101311 <pgdir_walk>
f01020ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01020f2:	8d 57 04             	lea    0x4(%edi),%edx
f01020f5:	39 d0                	cmp    %edx,%eax
f01020f7:	74 24                	je     f010211d <mem_init+0xbd5>
f01020f9:	c7 44 24 0c 6c 5d 10 	movl   $0xf0105d6c,0xc(%esp)
f0102100:	f0 
f0102101:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102108:	f0 
f0102109:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0102110:	00 
f0102111:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102118:	e8 99 df ff ff       	call   f01000b6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010211d:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102124:	00 
f0102125:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010212c:	00 
f010212d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102131:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102136:	89 04 24             	mov    %eax,(%esp)
f0102139:	e8 89 f3 ff ff       	call   f01014c7 <page_insert>
f010213e:	85 c0                	test   %eax,%eax
f0102140:	74 24                	je     f0102166 <mem_init+0xc1e>
f0102142:	c7 44 24 0c ac 5d 10 	movl   $0xf0105dac,0xc(%esp)
f0102149:	f0 
f010214a:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102151:	f0 
f0102152:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0102159:	00 
f010215a:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102161:	e8 50 df ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102166:	8b 3d a8 ee 17 f0    	mov    0xf017eea8,%edi
f010216c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102171:	89 f8                	mov    %edi,%eax
f0102173:	e8 79 ec ff ff       	call   f0100df1 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102178:	89 da                	mov    %ebx,%edx
f010217a:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f0102180:	c1 fa 03             	sar    $0x3,%edx
f0102183:	c1 e2 0c             	shl    $0xc,%edx
f0102186:	39 d0                	cmp    %edx,%eax
f0102188:	74 24                	je     f01021ae <mem_init+0xc66>
f010218a:	c7 44 24 0c 3c 5d 10 	movl   $0xf0105d3c,0xc(%esp)
f0102191:	f0 
f0102192:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102199:	f0 
f010219a:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f01021a1:	00 
f01021a2:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01021a9:	e8 08 df ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f01021ae:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01021b3:	74 24                	je     f01021d9 <mem_init+0xc91>
f01021b5:	c7 44 24 0c dd 63 10 	movl   $0xf01063dd,0xc(%esp)
f01021bc:	f0 
f01021bd:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01021c4:	f0 
f01021c5:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f01021cc:	00 
f01021cd:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01021d4:	e8 dd de ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01021d9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021e0:	00 
f01021e1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021e8:	00 
f01021e9:	89 3c 24             	mov    %edi,(%esp)
f01021ec:	e8 20 f1 ff ff       	call   f0101311 <pgdir_walk>
f01021f1:	f6 00 04             	testb  $0x4,(%eax)
f01021f4:	75 24                	jne    f010221a <mem_init+0xcd2>
f01021f6:	c7 44 24 0c ec 5d 10 	movl   $0xf0105dec,0xc(%esp)
f01021fd:	f0 
f01021fe:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102205:	f0 
f0102206:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f010220d:	00 
f010220e:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102215:	e8 9c de ff ff       	call   f01000b6 <_panic>
	//cprintf("pp2 %x\n", pp2);
	//cprintf("kern_pgdir %x\n", kern_pgdir);
	//cprintf("kern_pgdir[0] is %x\n", kern_pgdir[0]);
	assert(kern_pgdir[0] & PTE_U);
f010221a:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f010221f:	f6 00 04             	testb  $0x4,(%eax)
f0102222:	75 24                	jne    f0102248 <mem_init+0xd00>
f0102224:	c7 44 24 0c ee 63 10 	movl   $0xf01063ee,0xc(%esp)
f010222b:	f0 
f010222c:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102233:	f0 
f0102234:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f010223b:	00 
f010223c:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102243:	e8 6e de ff ff       	call   f01000b6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102248:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010224f:	00 
f0102250:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102257:	00 
f0102258:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010225c:	89 04 24             	mov    %eax,(%esp)
f010225f:	e8 63 f2 ff ff       	call   f01014c7 <page_insert>
f0102264:	85 c0                	test   %eax,%eax
f0102266:	74 24                	je     f010228c <mem_init+0xd44>
f0102268:	c7 44 24 0c 00 5d 10 	movl   $0xf0105d00,0xc(%esp)
f010226f:	f0 
f0102270:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102277:	f0 
f0102278:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f010227f:	00 
f0102280:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102287:	e8 2a de ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010228c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102293:	00 
f0102294:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010229b:	00 
f010229c:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01022a1:	89 04 24             	mov    %eax,(%esp)
f01022a4:	e8 68 f0 ff ff       	call   f0101311 <pgdir_walk>
f01022a9:	f6 00 02             	testb  $0x2,(%eax)
f01022ac:	75 24                	jne    f01022d2 <mem_init+0xd8a>
f01022ae:	c7 44 24 0c 20 5e 10 	movl   $0xf0105e20,0xc(%esp)
f01022b5:	f0 
f01022b6:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01022bd:	f0 
f01022be:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f01022c5:	00 
f01022c6:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01022cd:	e8 e4 dd ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01022d2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01022d9:	00 
f01022da:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022e1:	00 
f01022e2:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01022e7:	89 04 24             	mov    %eax,(%esp)
f01022ea:	e8 22 f0 ff ff       	call   f0101311 <pgdir_walk>
f01022ef:	f6 00 04             	testb  $0x4,(%eax)
f01022f2:	74 24                	je     f0102318 <mem_init+0xdd0>
f01022f4:	c7 44 24 0c 54 5e 10 	movl   $0xf0105e54,0xc(%esp)
f01022fb:	f0 
f01022fc:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102303:	f0 
f0102304:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f010230b:	00 
f010230c:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102313:	e8 9e dd ff ff       	call   f01000b6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102318:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010231f:	00 
f0102320:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102327:	00 
f0102328:	89 74 24 04          	mov    %esi,0x4(%esp)
f010232c:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102331:	89 04 24             	mov    %eax,(%esp)
f0102334:	e8 8e f1 ff ff       	call   f01014c7 <page_insert>
f0102339:	85 c0                	test   %eax,%eax
f010233b:	78 24                	js     f0102361 <mem_init+0xe19>
f010233d:	c7 44 24 0c 8c 5e 10 	movl   $0xf0105e8c,0xc(%esp)
f0102344:	f0 
f0102345:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010234c:	f0 
f010234d:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0102354:	00 
f0102355:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010235c:	e8 55 dd ff ff       	call   f01000b6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102361:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102368:	00 
f0102369:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102370:	00 
f0102371:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102374:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102378:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f010237d:	89 04 24             	mov    %eax,(%esp)
f0102380:	e8 42 f1 ff ff       	call   f01014c7 <page_insert>
f0102385:	85 c0                	test   %eax,%eax
f0102387:	74 24                	je     f01023ad <mem_init+0xe65>
f0102389:	c7 44 24 0c c4 5e 10 	movl   $0xf0105ec4,0xc(%esp)
f0102390:	f0 
f0102391:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102398:	f0 
f0102399:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f01023a0:	00 
f01023a1:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01023a8:	e8 09 dd ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01023ad:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01023b4:	00 
f01023b5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01023bc:	00 
f01023bd:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01023c2:	89 04 24             	mov    %eax,(%esp)
f01023c5:	e8 47 ef ff ff       	call   f0101311 <pgdir_walk>
f01023ca:	f6 00 04             	testb  $0x4,(%eax)
f01023cd:	74 24                	je     f01023f3 <mem_init+0xeab>
f01023cf:	c7 44 24 0c 54 5e 10 	movl   $0xf0105e54,0xc(%esp)
f01023d6:	f0 
f01023d7:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01023de:	f0 
f01023df:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f01023e6:	00 
f01023e7:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01023ee:	e8 c3 dc ff ff       	call   f01000b6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01023f3:	8b 3d a8 ee 17 f0    	mov    0xf017eea8,%edi
f01023f9:	ba 00 00 00 00       	mov    $0x0,%edx
f01023fe:	89 f8                	mov    %edi,%eax
f0102400:	e8 ec e9 ff ff       	call   f0100df1 <check_va2pa>
f0102405:	89 c1                	mov    %eax,%ecx
f0102407:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010240a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010240d:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f0102413:	c1 f8 03             	sar    $0x3,%eax
f0102416:	c1 e0 0c             	shl    $0xc,%eax
f0102419:	39 c1                	cmp    %eax,%ecx
f010241b:	74 24                	je     f0102441 <mem_init+0xef9>
f010241d:	c7 44 24 0c 00 5f 10 	movl   $0xf0105f00,0xc(%esp)
f0102424:	f0 
f0102425:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010242c:	f0 
f010242d:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f0102434:	00 
f0102435:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010243c:	e8 75 dc ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102441:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102446:	89 f8                	mov    %edi,%eax
f0102448:	e8 a4 e9 ff ff       	call   f0100df1 <check_va2pa>
f010244d:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0102450:	74 24                	je     f0102476 <mem_init+0xf2e>
f0102452:	c7 44 24 0c 2c 5f 10 	movl   $0xf0105f2c,0xc(%esp)
f0102459:	f0 
f010245a:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102461:	f0 
f0102462:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102469:	00 
f010246a:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102471:	e8 40 dc ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102476:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102479:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f010247e:	74 24                	je     f01024a4 <mem_init+0xf5c>
f0102480:	c7 44 24 0c 04 64 10 	movl   $0xf0106404,0xc(%esp)
f0102487:	f0 
f0102488:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010248f:	f0 
f0102490:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0102497:	00 
f0102498:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010249f:	e8 12 dc ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01024a4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01024a9:	74 24                	je     f01024cf <mem_init+0xf87>
f01024ab:	c7 44 24 0c 15 64 10 	movl   $0xf0106415,0xc(%esp)
f01024b2:	f0 
f01024b3:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01024ba:	f0 
f01024bb:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f01024c2:	00 
f01024c3:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01024ca:	e8 e7 db ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01024cf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01024d6:	e8 73 ed ff ff       	call   f010124e <page_alloc>
f01024db:	85 c0                	test   %eax,%eax
f01024dd:	74 04                	je     f01024e3 <mem_init+0xf9b>
f01024df:	39 c3                	cmp    %eax,%ebx
f01024e1:	74 24                	je     f0102507 <mem_init+0xfbf>
f01024e3:	c7 44 24 0c 5c 5f 10 	movl   $0xf0105f5c,0xc(%esp)
f01024ea:	f0 
f01024eb:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01024f2:	f0 
f01024f3:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f01024fa:	00 
f01024fb:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102502:	e8 af db ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102507:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010250e:	00 
f010250f:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102514:	89 04 24             	mov    %eax,(%esp)
f0102517:	e8 66 ef ff ff       	call   f0101482 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010251c:	8b 3d a8 ee 17 f0    	mov    0xf017eea8,%edi
f0102522:	ba 00 00 00 00       	mov    $0x0,%edx
f0102527:	89 f8                	mov    %edi,%eax
f0102529:	e8 c3 e8 ff ff       	call   f0100df1 <check_va2pa>
f010252e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102531:	74 24                	je     f0102557 <mem_init+0x100f>
f0102533:	c7 44 24 0c 80 5f 10 	movl   $0xf0105f80,0xc(%esp)
f010253a:	f0 
f010253b:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102542:	f0 
f0102543:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f010254a:	00 
f010254b:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102552:	e8 5f db ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102557:	ba 00 10 00 00       	mov    $0x1000,%edx
f010255c:	89 f8                	mov    %edi,%eax
f010255e:	e8 8e e8 ff ff       	call   f0100df1 <check_va2pa>
f0102563:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102566:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f010256c:	c1 fa 03             	sar    $0x3,%edx
f010256f:	c1 e2 0c             	shl    $0xc,%edx
f0102572:	39 d0                	cmp    %edx,%eax
f0102574:	74 24                	je     f010259a <mem_init+0x1052>
f0102576:	c7 44 24 0c 2c 5f 10 	movl   $0xf0105f2c,0xc(%esp)
f010257d:	f0 
f010257e:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102585:	f0 
f0102586:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f010258d:	00 
f010258e:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102595:	e8 1c db ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f010259a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010259d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01025a2:	74 24                	je     f01025c8 <mem_init+0x1080>
f01025a4:	c7 44 24 0c bb 63 10 	movl   $0xf01063bb,0xc(%esp)
f01025ab:	f0 
f01025ac:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01025b3:	f0 
f01025b4:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f01025bb:	00 
f01025bc:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01025c3:	e8 ee da ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01025c8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01025cd:	74 24                	je     f01025f3 <mem_init+0x10ab>
f01025cf:	c7 44 24 0c 15 64 10 	movl   $0xf0106415,0xc(%esp)
f01025d6:	f0 
f01025d7:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01025de:	f0 
f01025df:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f01025e6:	00 
f01025e7:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01025ee:	e8 c3 da ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025f3:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01025fa:	00 
f01025fb:	89 3c 24             	mov    %edi,(%esp)
f01025fe:	e8 7f ee ff ff       	call   f0101482 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102603:	8b 3d a8 ee 17 f0    	mov    0xf017eea8,%edi
f0102609:	ba 00 00 00 00       	mov    $0x0,%edx
f010260e:	89 f8                	mov    %edi,%eax
f0102610:	e8 dc e7 ff ff       	call   f0100df1 <check_va2pa>
f0102615:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102618:	74 24                	je     f010263e <mem_init+0x10f6>
f010261a:	c7 44 24 0c 80 5f 10 	movl   $0xf0105f80,0xc(%esp)
f0102621:	f0 
f0102622:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102629:	f0 
f010262a:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f0102631:	00 
f0102632:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102639:	e8 78 da ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010263e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102643:	89 f8                	mov    %edi,%eax
f0102645:	e8 a7 e7 ff ff       	call   f0100df1 <check_va2pa>
f010264a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010264d:	74 24                	je     f0102673 <mem_init+0x112b>
f010264f:	c7 44 24 0c a4 5f 10 	movl   $0xf0105fa4,0xc(%esp)
f0102656:	f0 
f0102657:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010265e:	f0 
f010265f:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102666:	00 
f0102667:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010266e:	e8 43 da ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102673:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102676:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010267b:	74 24                	je     f01026a1 <mem_init+0x1159>
f010267d:	c7 44 24 0c 26 64 10 	movl   $0xf0106426,0xc(%esp)
f0102684:	f0 
f0102685:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010268c:	f0 
f010268d:	c7 44 24 04 9b 03 00 	movl   $0x39b,0x4(%esp)
f0102694:	00 
f0102695:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010269c:	e8 15 da ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01026a1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01026a6:	74 24                	je     f01026cc <mem_init+0x1184>
f01026a8:	c7 44 24 0c 15 64 10 	movl   $0xf0106415,0xc(%esp)
f01026af:	f0 
f01026b0:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01026b7:	f0 
f01026b8:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f01026bf:	00 
f01026c0:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01026c7:	e8 ea d9 ff ff       	call   f01000b6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01026cc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026d3:	e8 76 eb ff ff       	call   f010124e <page_alloc>
f01026d8:	85 c0                	test   %eax,%eax
f01026da:	74 05                	je     f01026e1 <mem_init+0x1199>
f01026dc:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01026df:	74 24                	je     f0102705 <mem_init+0x11bd>
f01026e1:	c7 44 24 0c cc 5f 10 	movl   $0xf0105fcc,0xc(%esp)
f01026e8:	f0 
f01026e9:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01026f0:	f0 
f01026f1:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f01026f8:	00 
f01026f9:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102700:	e8 b1 d9 ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102705:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010270c:	e8 3d eb ff ff       	call   f010124e <page_alloc>
f0102711:	85 c0                	test   %eax,%eax
f0102713:	74 24                	je     f0102739 <mem_init+0x11f1>
f0102715:	c7 44 24 0c 69 63 10 	movl   $0xf0106369,0xc(%esp)
f010271c:	f0 
f010271d:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102724:	f0 
f0102725:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f010272c:	00 
f010272d:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102734:	e8 7d d9 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102739:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f010273e:	8b 08                	mov    (%eax),%ecx
f0102740:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102746:	89 f2                	mov    %esi,%edx
f0102748:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f010274e:	c1 fa 03             	sar    $0x3,%edx
f0102751:	c1 e2 0c             	shl    $0xc,%edx
f0102754:	39 d1                	cmp    %edx,%ecx
f0102756:	74 24                	je     f010277c <mem_init+0x1234>
f0102758:	c7 44 24 0c a8 5c 10 	movl   $0xf0105ca8,0xc(%esp)
f010275f:	f0 
f0102760:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102767:	f0 
f0102768:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f010276f:	00 
f0102770:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102777:	e8 3a d9 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f010277c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102782:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102787:	74 24                	je     f01027ad <mem_init+0x1265>
f0102789:	c7 44 24 0c cc 63 10 	movl   $0xf01063cc,0xc(%esp)
f0102790:	f0 
f0102791:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102798:	f0 
f0102799:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f01027a0:	00 
f01027a1:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01027a8:	e8 09 d9 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f01027ad:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01027b3:	89 34 24             	mov    %esi,(%esp)
f01027b6:	e8 1e eb ff ff       	call   f01012d9 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01027bb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01027c2:	00 
f01027c3:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01027ca:	00 
f01027cb:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01027d0:	89 04 24             	mov    %eax,(%esp)
f01027d3:	e8 39 eb ff ff       	call   f0101311 <pgdir_walk>
f01027d8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01027db:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01027de:	8b 15 a8 ee 17 f0    	mov    0xf017eea8,%edx
f01027e4:	8b 7a 04             	mov    0x4(%edx),%edi
f01027e7:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027ed:	8b 0d a4 ee 17 f0    	mov    0xf017eea4,%ecx
f01027f3:	89 f8                	mov    %edi,%eax
f01027f5:	c1 e8 0c             	shr    $0xc,%eax
f01027f8:	39 c8                	cmp    %ecx,%eax
f01027fa:	72 20                	jb     f010281c <mem_init+0x12d4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027fc:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102800:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f0102807:	f0 
f0102808:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f010280f:	00 
f0102810:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102817:	e8 9a d8 ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010281c:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102822:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102825:	74 24                	je     f010284b <mem_init+0x1303>
f0102827:	c7 44 24 0c 37 64 10 	movl   $0xf0106437,0xc(%esp)
f010282e:	f0 
f010282f:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102836:	f0 
f0102837:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f010283e:	00 
f010283f:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102846:	e8 6b d8 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010284b:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102852:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102858:	89 f0                	mov    %esi,%eax
f010285a:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f0102860:	c1 f8 03             	sar    $0x3,%eax
f0102863:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102866:	89 c2                	mov    %eax,%edx
f0102868:	c1 ea 0c             	shr    $0xc,%edx
f010286b:	39 d1                	cmp    %edx,%ecx
f010286d:	77 20                	ja     f010288f <mem_init+0x1347>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010286f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102873:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f010287a:	f0 
f010287b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102882:	00 
f0102883:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f010288a:	e8 27 d8 ff ff       	call   f01000b6 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010288f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102896:	00 
f0102897:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010289e:	00 
	return (void *)(pa + KERNBASE);
f010289f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01028a4:	89 04 24             	mov    %eax,(%esp)
f01028a7:	e8 2b 26 00 00       	call   f0104ed7 <memset>
	page_free(pp0);
f01028ac:	89 34 24             	mov    %esi,(%esp)
f01028af:	e8 25 ea ff ff       	call   f01012d9 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01028b4:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01028bb:	00 
f01028bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01028c3:	00 
f01028c4:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01028c9:	89 04 24             	mov    %eax,(%esp)
f01028cc:	e8 40 ea ff ff       	call   f0101311 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01028d1:	89 f2                	mov    %esi,%edx
f01028d3:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f01028d9:	c1 fa 03             	sar    $0x3,%edx
f01028dc:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01028df:	89 d0                	mov    %edx,%eax
f01028e1:	c1 e8 0c             	shr    $0xc,%eax
f01028e4:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f01028ea:	72 20                	jb     f010290c <mem_init+0x13c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028ec:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01028f0:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f01028f7:	f0 
f01028f8:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01028ff:	00 
f0102900:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f0102907:	e8 aa d7 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010290c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102912:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102915:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010291b:	f6 00 01             	testb  $0x1,(%eax)
f010291e:	74 24                	je     f0102944 <mem_init+0x13fc>
f0102920:	c7 44 24 0c 4f 64 10 	movl   $0xf010644f,0xc(%esp)
f0102927:	f0 
f0102928:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010292f:	f0 
f0102930:	c7 44 24 04 b9 03 00 	movl   $0x3b9,0x4(%esp)
f0102937:	00 
f0102938:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010293f:	e8 72 d7 ff ff       	call   f01000b6 <_panic>
f0102944:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102947:	39 d0                	cmp    %edx,%eax
f0102949:	75 d0                	jne    f010291b <mem_init+0x13d3>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010294b:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102950:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102956:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f010295c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010295f:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0

	// free the pages we took
	page_free(pp0);
f0102964:	89 34 24             	mov    %esi,(%esp)
f0102967:	e8 6d e9 ff ff       	call   f01012d9 <page_free>
	page_free(pp1);
f010296c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010296f:	89 04 24             	mov    %eax,(%esp)
f0102972:	e8 62 e9 ff ff       	call   f01012d9 <page_free>
	page_free(pp2);
f0102977:	89 1c 24             	mov    %ebx,(%esp)
f010297a:	e8 5a e9 ff ff       	call   f01012d9 <page_free>

	cprintf("check_page() succeeded!\n");
f010297f:	c7 04 24 66 64 10 f0 	movl   $0xf0106466,(%esp)
f0102986:	e8 ee 0f 00 00       	call   f0103979 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, 
f010298b:	a1 ac ee 17 f0       	mov    0xf017eeac,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102990:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102995:	77 20                	ja     f01029b7 <mem_init+0x146f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102997:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010299b:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f01029a2:	f0 
f01029a3:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
f01029aa:	00 
f01029ab:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01029b2:	e8 ff d6 ff ff       	call   f01000b6 <_panic>
f01029b7:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f01029be:	00 
	return (physaddr_t)kva - KERNBASE;
f01029bf:	05 00 00 00 10       	add    $0x10000000,%eax
f01029c4:	89 04 24             	mov    %eax,(%esp)
f01029c7:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01029cc:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01029d1:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01029d6:	e8 d6 e9 ff ff       	call   f01013b1 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, 
f01029db:	a1 ec e1 17 f0       	mov    0xf017e1ec,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029e0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029e5:	77 20                	ja     f0102a07 <mem_init+0x14bf>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029e7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029eb:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f01029f2:	f0 
f01029f3:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
f01029fa:	00 
f01029fb:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102a02:	e8 af d6 ff ff       	call   f01000b6 <_panic>
f0102a07:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102a0e:	00 
	return (physaddr_t)kva - KERNBASE;
f0102a0f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a14:	89 04 24             	mov    %eax,(%esp)
f0102a17:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102a1c:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102a21:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102a26:	e8 86 e9 ff ff       	call   f01013b1 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a2b:	bb 00 20 11 f0       	mov    $0xf0112000,%ebx
f0102a30:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102a36:	77 20                	ja     f0102a58 <mem_init+0x1510>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a38:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102a3c:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f0102a43:	f0 
f0102a44:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
f0102a4b:	00 
f0102a4c:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102a53:	e8 5e d6 ff ff       	call   f01000b6 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, 
f0102a58:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a5f:	00 
f0102a60:	c7 04 24 00 20 11 00 	movl   $0x112000,(%esp)
f0102a67:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102a6c:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102a71:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102a76:	e8 36 e9 ff ff       	call   f01013b1 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, 
f0102a7b:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a82:	00 
f0102a83:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a8a:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102a8f:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102a94:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102a99:	e8 13 e9 ff ff       	call   f01013b1 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102a9e:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102aa3:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102aa6:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f0102aab:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102aae:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102ab5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102aba:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102abd:	8b 3d ac ee 17 f0    	mov    0xf017eeac,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ac3:	89 7d c8             	mov    %edi,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102ac6:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0102acc:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102acf:	be 00 00 00 00       	mov    $0x0,%esi
f0102ad4:	eb 6b                	jmp    f0102b41 <mem_init+0x15f9>
f0102ad6:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102adc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102adf:	e8 0d e3 ff ff       	call   f0100df1 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ae4:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102aeb:	77 20                	ja     f0102b0d <mem_init+0x15c5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102aed:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102af1:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f0102af8:	f0 
f0102af9:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0102b00:	00 
f0102b01:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102b08:	e8 a9 d5 ff ff       	call   f01000b6 <_panic>
f0102b0d:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102b10:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102b13:	39 d0                	cmp    %edx,%eax
f0102b15:	74 24                	je     f0102b3b <mem_init+0x15f3>
f0102b17:	c7 44 24 0c f0 5f 10 	movl   $0xf0105ff0,0xc(%esp)
f0102b1e:	f0 
f0102b1f:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102b26:	f0 
f0102b27:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0102b2e:	00 
f0102b2f:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102b36:	e8 7b d5 ff ff       	call   f01000b6 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102b3b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102b41:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0102b44:	77 90                	ja     f0102ad6 <mem_init+0x158e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102b46:	8b 35 ec e1 17 f0    	mov    0xf017e1ec,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b4c:	89 f7                	mov    %esi,%edi
f0102b4e:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102b53:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b56:	e8 96 e2 ff ff       	call   f0100df1 <check_va2pa>
f0102b5b:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102b61:	77 20                	ja     f0102b83 <mem_init+0x163b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b63:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102b67:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f0102b6e:	f0 
f0102b6f:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0102b76:	00 
f0102b77:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102b7e:	e8 33 d5 ff ff       	call   f01000b6 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b83:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102b88:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f0102b8e:	8d 14 37             	lea    (%edi,%esi,1),%edx
f0102b91:	39 c2                	cmp    %eax,%edx
f0102b93:	74 24                	je     f0102bb9 <mem_init+0x1671>
f0102b95:	c7 44 24 0c 24 60 10 	movl   $0xf0106024,0xc(%esp)
f0102b9c:	f0 
f0102b9d:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102ba4:	f0 
f0102ba5:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0102bac:	00 
f0102bad:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102bb4:	e8 fd d4 ff ff       	call   f01000b6 <_panic>
f0102bb9:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102bbf:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102bc5:	0f 85 26 05 00 00    	jne    f01030f1 <mem_init+0x1ba9>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102bcb:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102bce:	c1 e7 0c             	shl    $0xc,%edi
f0102bd1:	be 00 00 00 00       	mov    $0x0,%esi
f0102bd6:	eb 3c                	jmp    f0102c14 <mem_init+0x16cc>
f0102bd8:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102bde:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102be1:	e8 0b e2 ff ff       	call   f0100df1 <check_va2pa>
f0102be6:	39 c6                	cmp    %eax,%esi
f0102be8:	74 24                	je     f0102c0e <mem_init+0x16c6>
f0102bea:	c7 44 24 0c 58 60 10 	movl   $0xf0106058,0xc(%esp)
f0102bf1:	f0 
f0102bf2:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102bf9:	f0 
f0102bfa:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f0102c01:	00 
f0102c02:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102c09:	e8 a8 d4 ff ff       	call   f01000b6 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102c0e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102c14:	39 fe                	cmp    %edi,%esi
f0102c16:	72 c0                	jb     f0102bd8 <mem_init+0x1690>
f0102c18:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102c1d:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c23:	89 f2                	mov    %esi,%edx
f0102c25:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c28:	e8 c4 e1 ff ff       	call   f0100df1 <check_va2pa>
f0102c2d:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102c30:	39 d0                	cmp    %edx,%eax
f0102c32:	74 24                	je     f0102c58 <mem_init+0x1710>
f0102c34:	c7 44 24 0c 80 60 10 	movl   $0xf0106080,0xc(%esp)
f0102c3b:	f0 
f0102c3c:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102c43:	f0 
f0102c44:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0102c4b:	00 
f0102c4c:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102c53:	e8 5e d4 ff ff       	call   f01000b6 <_panic>
f0102c58:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102c5e:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102c64:	75 bd                	jne    f0102c23 <mem_init+0x16db>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c66:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102c6b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c6e:	89 f8                	mov    %edi,%eax
f0102c70:	e8 7c e1 ff ff       	call   f0100df1 <check_va2pa>
f0102c75:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c78:	75 0c                	jne    f0102c86 <mem_init+0x173e>
f0102c7a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c7f:	89 fa                	mov    %edi,%edx
f0102c81:	e9 f0 00 00 00       	jmp    f0102d76 <mem_init+0x182e>
f0102c86:	c7 44 24 0c c8 60 10 	movl   $0xf01060c8,0xc(%esp)
f0102c8d:	f0 
f0102c8e:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102c95:	f0 
f0102c96:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0102c9d:	00 
f0102c9e:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102ca5:	e8 0c d4 ff ff       	call   f01000b6 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102caa:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102caf:	72 3c                	jb     f0102ced <mem_init+0x17a5>
f0102cb1:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102cb6:	76 07                	jbe    f0102cbf <mem_init+0x1777>
f0102cb8:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102cbd:	75 2e                	jne    f0102ced <mem_init+0x17a5>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102cbf:	f6 04 82 01          	testb  $0x1,(%edx,%eax,4)
f0102cc3:	0f 85 aa 00 00 00    	jne    f0102d73 <mem_init+0x182b>
f0102cc9:	c7 44 24 0c 7f 64 10 	movl   $0xf010647f,0xc(%esp)
f0102cd0:	f0 
f0102cd1:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102cd8:	f0 
f0102cd9:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0102ce0:	00 
f0102ce1:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102ce8:	e8 c9 d3 ff ff       	call   f01000b6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102ced:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102cf2:	76 55                	jbe    f0102d49 <mem_init+0x1801>
				assert(pgdir[i] & PTE_P);
f0102cf4:	8b 0c 82             	mov    (%edx,%eax,4),%ecx
f0102cf7:	f6 c1 01             	test   $0x1,%cl
f0102cfa:	75 24                	jne    f0102d20 <mem_init+0x17d8>
f0102cfc:	c7 44 24 0c 7f 64 10 	movl   $0xf010647f,0xc(%esp)
f0102d03:	f0 
f0102d04:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102d0b:	f0 
f0102d0c:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0102d13:	00 
f0102d14:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102d1b:	e8 96 d3 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0102d20:	f6 c1 02             	test   $0x2,%cl
f0102d23:	75 4e                	jne    f0102d73 <mem_init+0x182b>
f0102d25:	c7 44 24 0c 90 64 10 	movl   $0xf0106490,0xc(%esp)
f0102d2c:	f0 
f0102d2d:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102d34:	f0 
f0102d35:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0102d3c:	00 
f0102d3d:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102d44:	e8 6d d3 ff ff       	call   f01000b6 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102d49:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f0102d4d:	74 24                	je     f0102d73 <mem_init+0x182b>
f0102d4f:	c7 44 24 0c a1 64 10 	movl   $0xf01064a1,0xc(%esp)
f0102d56:	f0 
f0102d57:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102d5e:	f0 
f0102d5f:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0102d66:	00 
f0102d67:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102d6e:	e8 43 d3 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102d73:	83 c0 01             	add    $0x1,%eax
f0102d76:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102d7b:	0f 85 29 ff ff ff    	jne    f0102caa <mem_init+0x1762>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102d81:	c7 04 24 f8 60 10 f0 	movl   $0xf01060f8,(%esp)
f0102d88:	e8 ec 0b 00 00       	call   f0103979 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102d8d:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102d92:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d97:	77 20                	ja     f0102db9 <mem_init+0x1871>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d99:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d9d:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f0102da4:	f0 
f0102da5:	c7 44 24 04 f3 00 00 	movl   $0xf3,0x4(%esp)
f0102dac:	00 
f0102dad:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102db4:	e8 fd d2 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102db9:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102dbe:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102dc1:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dc6:	e8 95 e0 ff ff       	call   f0100e60 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102dcb:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102dce:	83 e0 f3             	and    $0xfffffff3,%eax
f0102dd1:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102dd6:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102dd9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102de0:	e8 69 e4 ff ff       	call   f010124e <page_alloc>
f0102de5:	89 c3                	mov    %eax,%ebx
f0102de7:	85 c0                	test   %eax,%eax
f0102de9:	75 24                	jne    f0102e0f <mem_init+0x18c7>
f0102deb:	c7 44 24 0c be 62 10 	movl   $0xf01062be,0xc(%esp)
f0102df2:	f0 
f0102df3:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102dfa:	f0 
f0102dfb:	c7 44 24 04 d4 03 00 	movl   $0x3d4,0x4(%esp)
f0102e02:	00 
f0102e03:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102e0a:	e8 a7 d2 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e0f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e16:	e8 33 e4 ff ff       	call   f010124e <page_alloc>
f0102e1b:	89 c7                	mov    %eax,%edi
f0102e1d:	85 c0                	test   %eax,%eax
f0102e1f:	75 24                	jne    f0102e45 <mem_init+0x18fd>
f0102e21:	c7 44 24 0c d4 62 10 	movl   $0xf01062d4,0xc(%esp)
f0102e28:	f0 
f0102e29:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102e30:	f0 
f0102e31:	c7 44 24 04 d5 03 00 	movl   $0x3d5,0x4(%esp)
f0102e38:	00 
f0102e39:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102e40:	e8 71 d2 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0102e45:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e4c:	e8 fd e3 ff ff       	call   f010124e <page_alloc>
f0102e51:	89 c6                	mov    %eax,%esi
f0102e53:	85 c0                	test   %eax,%eax
f0102e55:	75 24                	jne    f0102e7b <mem_init+0x1933>
f0102e57:	c7 44 24 0c ea 62 10 	movl   $0xf01062ea,0xc(%esp)
f0102e5e:	f0 
f0102e5f:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102e66:	f0 
f0102e67:	c7 44 24 04 d6 03 00 	movl   $0x3d6,0x4(%esp)
f0102e6e:	00 
f0102e6f:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102e76:	e8 3b d2 ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f0102e7b:	89 1c 24             	mov    %ebx,(%esp)
f0102e7e:	e8 56 e4 ff ff       	call   f01012d9 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102e83:	89 f8                	mov    %edi,%eax
f0102e85:	e8 22 df ff ff       	call   f0100dac <page2kva>
f0102e8a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102e91:	00 
f0102e92:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102e99:	00 
f0102e9a:	89 04 24             	mov    %eax,(%esp)
f0102e9d:	e8 35 20 00 00       	call   f0104ed7 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102ea2:	89 f0                	mov    %esi,%eax
f0102ea4:	e8 03 df ff ff       	call   f0100dac <page2kva>
f0102ea9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102eb0:	00 
f0102eb1:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102eb8:	00 
f0102eb9:	89 04 24             	mov    %eax,(%esp)
f0102ebc:	e8 16 20 00 00       	call   f0104ed7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102ec1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102ec8:	00 
f0102ec9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ed0:	00 
f0102ed1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102ed5:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102eda:	89 04 24             	mov    %eax,(%esp)
f0102edd:	e8 e5 e5 ff ff       	call   f01014c7 <page_insert>
	assert(pp1->pp_ref == 1);
f0102ee2:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102ee7:	74 24                	je     f0102f0d <mem_init+0x19c5>
f0102ee9:	c7 44 24 0c bb 63 10 	movl   $0xf01063bb,0xc(%esp)
f0102ef0:	f0 
f0102ef1:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102ef8:	f0 
f0102ef9:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f0102f00:	00 
f0102f01:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102f08:	e8 a9 d1 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f0d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102f14:	01 01 01 
f0102f17:	74 24                	je     f0102f3d <mem_init+0x19f5>
f0102f19:	c7 44 24 0c 18 61 10 	movl   $0xf0106118,0xc(%esp)
f0102f20:	f0 
f0102f21:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102f28:	f0 
f0102f29:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0102f30:	00 
f0102f31:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102f38:	e8 79 d1 ff ff       	call   f01000b6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102f3d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102f44:	00 
f0102f45:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102f4c:	00 
f0102f4d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f51:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102f56:	89 04 24             	mov    %eax,(%esp)
f0102f59:	e8 69 e5 ff ff       	call   f01014c7 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f5e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102f65:	02 02 02 
f0102f68:	74 24                	je     f0102f8e <mem_init+0x1a46>
f0102f6a:	c7 44 24 0c 3c 61 10 	movl   $0xf010613c,0xc(%esp)
f0102f71:	f0 
f0102f72:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102f79:	f0 
f0102f7a:	c7 44 24 04 de 03 00 	movl   $0x3de,0x4(%esp)
f0102f81:	00 
f0102f82:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102f89:	e8 28 d1 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102f8e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102f93:	74 24                	je     f0102fb9 <mem_init+0x1a71>
f0102f95:	c7 44 24 0c dd 63 10 	movl   $0xf01063dd,0xc(%esp)
f0102f9c:	f0 
f0102f9d:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102fa4:	f0 
f0102fa5:	c7 44 24 04 df 03 00 	movl   $0x3df,0x4(%esp)
f0102fac:	00 
f0102fad:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102fb4:	e8 fd d0 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102fb9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102fbe:	74 24                	je     f0102fe4 <mem_init+0x1a9c>
f0102fc0:	c7 44 24 0c 26 64 10 	movl   $0xf0106426,0xc(%esp)
f0102fc7:	f0 
f0102fc8:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0102fcf:	f0 
f0102fd0:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f0102fd7:	00 
f0102fd8:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f0102fdf:	e8 d2 d0 ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102fe4:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102feb:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102fee:	89 f0                	mov    %esi,%eax
f0102ff0:	e8 b7 dd ff ff       	call   f0100dac <page2kva>
f0102ff5:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102ffb:	74 24                	je     f0103021 <mem_init+0x1ad9>
f0102ffd:	c7 44 24 0c 60 61 10 	movl   $0xf0106160,0xc(%esp)
f0103004:	f0 
f0103005:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010300c:	f0 
f010300d:	c7 44 24 04 e2 03 00 	movl   $0x3e2,0x4(%esp)
f0103014:	00 
f0103015:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010301c:	e8 95 d0 ff ff       	call   f01000b6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103021:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103028:	00 
f0103029:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f010302e:	89 04 24             	mov    %eax,(%esp)
f0103031:	e8 4c e4 ff ff       	call   f0101482 <page_remove>
	assert(pp2->pp_ref == 0);
f0103036:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010303b:	74 24                	je     f0103061 <mem_init+0x1b19>
f010303d:	c7 44 24 0c 15 64 10 	movl   $0xf0106415,0xc(%esp)
f0103044:	f0 
f0103045:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010304c:	f0 
f010304d:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0103054:	00 
f0103055:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010305c:	e8 55 d0 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103061:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0103066:	8b 08                	mov    (%eax),%ecx
f0103068:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010306e:	89 da                	mov    %ebx,%edx
f0103070:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f0103076:	c1 fa 03             	sar    $0x3,%edx
f0103079:	c1 e2 0c             	shl    $0xc,%edx
f010307c:	39 d1                	cmp    %edx,%ecx
f010307e:	74 24                	je     f01030a4 <mem_init+0x1b5c>
f0103080:	c7 44 24 0c a8 5c 10 	movl   $0xf0105ca8,0xc(%esp)
f0103087:	f0 
f0103088:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010308f:	f0 
f0103090:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0103097:	00 
f0103098:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f010309f:	e8 12 d0 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f01030a4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01030aa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01030af:	74 24                	je     f01030d5 <mem_init+0x1b8d>
f01030b1:	c7 44 24 0c cc 63 10 	movl   $0xf01063cc,0xc(%esp)
f01030b8:	f0 
f01030b9:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f01030c0:	f0 
f01030c1:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f01030c8:	00 
f01030c9:	c7 04 24 fb 61 10 f0 	movl   $0xf01061fb,(%esp)
f01030d0:	e8 e1 cf ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f01030d5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01030db:	89 1c 24             	mov    %ebx,(%esp)
f01030de:	e8 f6 e1 ff ff       	call   f01012d9 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01030e3:	c7 04 24 8c 61 10 f0 	movl   $0xf010618c,(%esp)
f01030ea:	e8 8a 08 00 00       	call   f0103979 <cprintf>
f01030ef:	eb 0f                	jmp    f0103100 <mem_init+0x1bb8>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01030f1:	89 f2                	mov    %esi,%edx
f01030f3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030f6:	e8 f6 dc ff ff       	call   f0100df1 <check_va2pa>
f01030fb:	e9 8e fa ff ff       	jmp    f0102b8e <mem_init+0x1646>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0103100:	83 c4 4c             	add    $0x4c,%esp
f0103103:	5b                   	pop    %ebx
f0103104:	5e                   	pop    %esi
f0103105:	5f                   	pop    %edi
f0103106:	5d                   	pop    %ebp
f0103107:	c3                   	ret    

f0103108 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0103108:	55                   	push   %ebp
f0103109:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010310b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010310e:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0103111:	5d                   	pop    %ebp
f0103112:	c3                   	ret    

f0103113 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0103113:	55                   	push   %ebp
f0103114:	89 e5                	mov    %esp,%ebp
f0103116:	57                   	push   %edi
f0103117:	56                   	push   %esi
f0103118:	53                   	push   %ebx
f0103119:	83 ec 1c             	sub    $0x1c,%esp
f010311c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010311f:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN((char *)va, PGSIZE);
f0103122:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103125:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t)ROUNDUP((char *)va+len, PGSIZE);
f010312b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010312e:	03 45 10             	add    0x10(%ebp),%eax
f0103131:	05 ff 0f 00 00       	add    $0xfff,%eax
f0103136:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010313b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(; start < end; start += PGSIZE) {
f010313e:	eb 49                	jmp    f0103189 <user_mem_check+0x76>
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)start, 0);
f0103140:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0103147:	00 
f0103148:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010314c:	8b 47 5c             	mov    0x5c(%edi),%eax
f010314f:	89 04 24             	mov    %eax,(%esp)
f0103152:	e8 ba e1 ff ff       	call   f0101311 <pgdir_walk>
		if((start >= ULIM) || (pte == NULL) || !(*pte & PTE_P) || ((*pte & perm) != perm)) {
f0103157:	85 c0                	test   %eax,%eax
f0103159:	74 14                	je     f010316f <user_mem_check+0x5c>
f010315b:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103161:	77 0c                	ja     f010316f <user_mem_check+0x5c>
f0103163:	8b 00                	mov    (%eax),%eax
f0103165:	a8 01                	test   $0x1,%al
f0103167:	74 06                	je     f010316f <user_mem_check+0x5c>
f0103169:	21 f0                	and    %esi,%eax
f010316b:	39 c6                	cmp    %eax,%esi
f010316d:	74 14                	je     f0103183 <user_mem_check+0x70>
f010316f:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0103172:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
			user_mem_check_addr = (start < (uint32_t)va ? (uint32_t)va : start);
f0103176:	89 1d dc e1 17 f0    	mov    %ebx,0xf017e1dc
			return -E_FAULT;
f010317c:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103181:	eb 10                	jmp    f0103193 <user_mem_check+0x80>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN((char *)va, PGSIZE);
	uint32_t end = (uint32_t)ROUNDUP((char *)va+len, PGSIZE);
	for(; start < end; start += PGSIZE) {
f0103183:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103189:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f010318c:	72 b2                	jb     f0103140 <user_mem_check+0x2d>
		if((start >= ULIM) || (pte == NULL) || !(*pte & PTE_P) || ((*pte & perm) != perm)) {
			user_mem_check_addr = (start < (uint32_t)va ? (uint32_t)va : start);
			return -E_FAULT;
		}
	}
	return 0;
f010318e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103193:	83 c4 1c             	add    $0x1c,%esp
f0103196:	5b                   	pop    %ebx
f0103197:	5e                   	pop    %esi
f0103198:	5f                   	pop    %edi
f0103199:	5d                   	pop    %ebp
f010319a:	c3                   	ret    

f010319b <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f010319b:	55                   	push   %ebp
f010319c:	89 e5                	mov    %esp,%ebp
f010319e:	53                   	push   %ebx
f010319f:	83 ec 14             	sub    $0x14,%esp
f01031a2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01031a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01031a8:	83 c8 04             	or     $0x4,%eax
f01031ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031af:	8b 45 10             	mov    0x10(%ebp),%eax
f01031b2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031b6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031bd:	89 1c 24             	mov    %ebx,(%esp)
f01031c0:	e8 4e ff ff ff       	call   f0103113 <user_mem_check>
f01031c5:	85 c0                	test   %eax,%eax
f01031c7:	79 24                	jns    f01031ed <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f01031c9:	a1 dc e1 17 f0       	mov    0xf017e1dc,%eax
f01031ce:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031d2:	8b 43 48             	mov    0x48(%ebx),%eax
f01031d5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031d9:	c7 04 24 b8 61 10 f0 	movl   $0xf01061b8,(%esp)
f01031e0:	e8 94 07 00 00       	call   f0103979 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01031e5:	89 1c 24             	mov    %ebx,(%esp)
f01031e8:	e8 59 06 00 00       	call   f0103846 <env_destroy>
	}
}
f01031ed:	83 c4 14             	add    $0x14,%esp
f01031f0:	5b                   	pop    %ebx
f01031f1:	5d                   	pop    %ebp
f01031f2:	c3                   	ret    

f01031f3 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01031f3:	55                   	push   %ebp
f01031f4:	89 e5                	mov    %esp,%ebp
f01031f6:	57                   	push   %edi
f01031f7:	56                   	push   %esi
f01031f8:	53                   	push   %ebx
f01031f9:	83 ec 1c             	sub    $0x1c,%esp
f01031fc:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
f01031fe:	89 d3                	mov    %edx,%ebx
f0103200:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = (void *)ROUNDUP((uint32_t)va+len, PGSIZE);
f0103206:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010320d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *p = NULL;
	void* i;
	int r;
	for(i=start; i<end; i+=PGSIZE){
f0103213:	eb 6d                	jmp    f0103282 <region_alloc+0x8f>
		p = page_alloc(0);
f0103215:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010321c:	e8 2d e0 ff ff       	call   f010124e <page_alloc>
		if(p == NULL)
f0103221:	85 c0                	test   %eax,%eax
f0103223:	75 1c                	jne    f0103241 <region_alloc+0x4e>
			panic(" region alloc, allocation failed.");
f0103225:	c7 44 24 08 b0 64 10 	movl   $0xf01064b0,0x8(%esp)
f010322c:	f0 
f010322d:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
f0103234:	00 
f0103235:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f010323c:	e8 75 ce ff ff       	call   f01000b6 <_panic>

		r = page_insert(e->env_pgdir, p, i, PTE_W | PTE_U);
f0103241:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0103248:	00 
f0103249:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010324d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103251:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103254:	89 04 24             	mov    %eax,(%esp)
f0103257:	e8 6b e2 ff ff       	call   f01014c7 <page_insert>
		if(r != 0) {
f010325c:	85 c0                	test   %eax,%eax
f010325e:	74 1c                	je     f010327c <region_alloc+0x89>
			panic("region alloc error");
f0103260:	c7 44 24 08 a5 65 10 	movl   $0xf01065a5,0x8(%esp)
f0103267:	f0 
f0103268:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
f010326f:	00 
f0103270:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f0103277:	e8 3a ce ff ff       	call   f01000b6 <_panic>
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
	void* end = (void *)ROUNDUP((uint32_t)va+len, PGSIZE);
	struct PageInfo *p = NULL;
	void* i;
	int r;
	for(i=start; i<end; i+=PGSIZE){
f010327c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103282:	39 f3                	cmp    %esi,%ebx
f0103284:	72 8f                	jb     f0103215 <region_alloc+0x22>
		r = page_insert(e->env_pgdir, p, i, PTE_W | PTE_U);
		if(r != 0) {
			panic("region alloc error");
		}
	}
}
f0103286:	83 c4 1c             	add    $0x1c,%esp
f0103289:	5b                   	pop    %ebx
f010328a:	5e                   	pop    %esi
f010328b:	5f                   	pop    %edi
f010328c:	5d                   	pop    %ebp
f010328d:	c3                   	ret    

f010328e <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010328e:	55                   	push   %ebp
f010328f:	89 e5                	mov    %esp,%ebp
f0103291:	8b 45 08             	mov    0x8(%ebp),%eax
f0103294:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103297:	85 c0                	test   %eax,%eax
f0103299:	75 11                	jne    f01032ac <envid2env+0x1e>
		*env_store = curenv;
f010329b:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01032a0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01032a3:	89 01                	mov    %eax,(%ecx)
		return 0;
f01032a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01032aa:	eb 5e                	jmp    f010330a <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01032ac:	89 c2                	mov    %eax,%edx
f01032ae:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01032b4:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01032b7:	c1 e2 05             	shl    $0x5,%edx
f01032ba:	03 15 ec e1 17 f0    	add    0xf017e1ec,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01032c0:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f01032c4:	74 05                	je     f01032cb <envid2env+0x3d>
f01032c6:	39 42 48             	cmp    %eax,0x48(%edx)
f01032c9:	74 10                	je     f01032db <envid2env+0x4d>
		*env_store = 0;
f01032cb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032ce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01032d4:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01032d9:	eb 2f                	jmp    f010330a <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01032db:	84 c9                	test   %cl,%cl
f01032dd:	74 21                	je     f0103300 <envid2env+0x72>
f01032df:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01032e4:	39 c2                	cmp    %eax,%edx
f01032e6:	74 18                	je     f0103300 <envid2env+0x72>
f01032e8:	8b 40 48             	mov    0x48(%eax),%eax
f01032eb:	39 42 4c             	cmp    %eax,0x4c(%edx)
f01032ee:	74 10                	je     f0103300 <envid2env+0x72>
		*env_store = 0;
f01032f0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032f3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01032f9:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01032fe:	eb 0a                	jmp    f010330a <envid2env+0x7c>
	}

	*env_store = e;
f0103300:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103303:	89 10                	mov    %edx,(%eax)
	return 0;
f0103305:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010330a:	5d                   	pop    %ebp
f010330b:	c3                   	ret    

f010330c <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010330c:	55                   	push   %ebp
f010330d:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f010330f:	b8 00 c3 11 f0       	mov    $0xf011c300,%eax
f0103314:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103317:	b8 23 00 00 00       	mov    $0x23,%eax
f010331c:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010331e:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0103320:	b0 10                	mov    $0x10,%al
f0103322:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0103324:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0103326:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0103328:	ea 2f 33 10 f0 08 00 	ljmp   $0x8,$0xf010332f
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f010332f:	b0 00                	mov    $0x0,%al
f0103331:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103334:	5d                   	pop    %ebp
f0103335:	c3                   	ret    

f0103336 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103336:	55                   	push   %ebp
f0103337:	89 e5                	mov    %esp,%ebp
f0103339:	56                   	push   %esi
f010333a:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1; i>=0; i--){
		envs[i].env_id = 0;
f010333b:	8b 35 ec e1 17 f0    	mov    0xf017e1ec,%esi
f0103341:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0103347:	ba 00 04 00 00       	mov    $0x400,%edx
f010334c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103351:	89 c3                	mov    %eax,%ebx
f0103353:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f010335a:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f0103361:	89 48 44             	mov    %ecx,0x44(%eax)
f0103364:	83 e8 60             	sub    $0x60,%eax
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1; i>=0; i--){
f0103367:	83 ea 01             	sub    $0x1,%edx
f010336a:	74 04                	je     f0103370 <env_init+0x3a>
		envs[i].env_id = 0;
		envs[i].env_status = ENV_FREE;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
f010336c:	89 d9                	mov    %ebx,%ecx
f010336e:	eb e1                	jmp    f0103351 <env_init+0x1b>
f0103370:	89 35 f0 e1 17 f0    	mov    %esi,0xf017e1f0
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0103376:	e8 91 ff ff ff       	call   f010330c <env_init_percpu>
}
f010337b:	5b                   	pop    %ebx
f010337c:	5e                   	pop    %esi
f010337d:	5d                   	pop    %ebp
f010337e:	c3                   	ret    

f010337f <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010337f:	55                   	push   %ebp
f0103380:	89 e5                	mov    %esp,%ebp
f0103382:	53                   	push   %ebx
f0103383:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103386:	8b 1d f0 e1 17 f0    	mov    0xf017e1f0,%ebx
f010338c:	85 db                	test   %ebx,%ebx
f010338e:	0f 84 6d 01 00 00    	je     f0103501 <env_alloc+0x182>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103394:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010339b:	e8 ae de ff ff       	call   f010124e <page_alloc>
f01033a0:	85 c0                	test   %eax,%eax
f01033a2:	0f 84 60 01 00 00    	je     f0103508 <env_alloc+0x189>
f01033a8:	89 c2                	mov    %eax,%edx
f01033aa:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f01033b0:	c1 fa 03             	sar    $0x3,%edx
f01033b3:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01033b6:	89 d1                	mov    %edx,%ecx
f01033b8:	c1 e9 0c             	shr    $0xc,%ecx
f01033bb:	3b 0d a4 ee 17 f0    	cmp    0xf017eea4,%ecx
f01033c1:	72 20                	jb     f01033e3 <env_alloc+0x64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01033c3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033c7:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f01033ce:	f0 
f01033cf:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01033d6:	00 
f01033d7:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f01033de:	e8 d3 cc ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f01033e3:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01033e9:	89 53 5c             	mov    %edx,0x5c(%ebx)
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;
f01033ec:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f01033f1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01033f8:	00 
f01033f9:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01033fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103402:	8b 43 5c             	mov    0x5c(%ebx),%eax
f0103405:	89 04 24             	mov    %eax,(%esp)
f0103408:	e8 7f 1b 00 00       	call   f0104f8c <memcpy>
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010340d:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103410:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103415:	77 20                	ja     f0103437 <env_alloc+0xb8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103417:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010341b:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f0103422:	f0 
f0103423:	c7 44 24 04 c2 00 00 	movl   $0xc2,0x4(%esp)
f010342a:	00 
f010342b:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f0103432:	e8 7f cc ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103437:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010343d:	83 ca 05             	or     $0x5,%edx
f0103440:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103446:	8b 43 48             	mov    0x48(%ebx),%eax
f0103449:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f010344e:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103453:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103458:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010345b:	89 da                	mov    %ebx,%edx
f010345d:	2b 15 ec e1 17 f0    	sub    0xf017e1ec,%edx
f0103463:	c1 fa 05             	sar    $0x5,%edx
f0103466:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010346c:	09 d0                	or     %edx,%eax
f010346e:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103471:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103474:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103477:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f010347e:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103485:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010348c:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103493:	00 
f0103494:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010349b:	00 
f010349c:	89 1c 24             	mov    %ebx,(%esp)
f010349f:	e8 33 1a 00 00       	call   f0104ed7 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01034a4:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01034aa:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01034b0:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01034b6:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01034bd:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01034c3:	8b 43 44             	mov    0x44(%ebx),%eax
f01034c6:	a3 f0 e1 17 f0       	mov    %eax,0xf017e1f0
	*newenv_store = e;
f01034cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01034ce:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01034d0:	8b 53 48             	mov    0x48(%ebx),%edx
f01034d3:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01034d8:	85 c0                	test   %eax,%eax
f01034da:	74 05                	je     f01034e1 <env_alloc+0x162>
f01034dc:	8b 40 48             	mov    0x48(%eax),%eax
f01034df:	eb 05                	jmp    f01034e6 <env_alloc+0x167>
f01034e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01034e6:	89 54 24 08          	mov    %edx,0x8(%esp)
f01034ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034ee:	c7 04 24 b8 65 10 f0 	movl   $0xf01065b8,(%esp)
f01034f5:	e8 7f 04 00 00       	call   f0103979 <cprintf>
	return 0;
f01034fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01034ff:	eb 0c                	jmp    f010350d <env_alloc+0x18e>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103501:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103506:	eb 05                	jmp    f010350d <env_alloc+0x18e>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103508:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010350d:	83 c4 14             	add    $0x14,%esp
f0103510:	5b                   	pop    %ebx
f0103511:	5d                   	pop    %ebp
f0103512:	c3                   	ret    

f0103513 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103513:	55                   	push   %ebp
f0103514:	89 e5                	mov    %esp,%ebp
f0103516:	57                   	push   %edi
f0103517:	56                   	push   %esi
f0103518:	53                   	push   %ebx
f0103519:	83 ec 3c             	sub    $0x3c,%esp
f010351c:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int rc;
	if((rc = env_alloc(&e, 0)) != 0) {
f010351f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103526:	00 
f0103527:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010352a:	89 04 24             	mov    %eax,(%esp)
f010352d:	e8 4d fe ff ff       	call   f010337f <env_alloc>
f0103532:	85 c0                	test   %eax,%eax
f0103534:	74 1c                	je     f0103552 <env_create+0x3f>
		panic("env_create failed: env_alloc failed.\n");
f0103536:	c7 44 24 08 d4 64 10 	movl   $0xf01064d4,0x8(%esp)
f010353d:	f0 
f010353e:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
f0103545:	00 
f0103546:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f010354d:	e8 64 cb ff ff       	call   f01000b6 <_panic>
	}

	load_icode(e, binary);
f0103552:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103555:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf* header = (struct Elf*)binary;
	
	if(header->e_magic != ELF_MAGIC) {
f0103558:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010355e:	74 1c                	je     f010357c <env_create+0x69>
		panic("load_icode failed: The binary we load is not elf.\n");
f0103560:	c7 44 24 08 fc 64 10 	movl   $0xf01064fc,0x8(%esp)
f0103567:	f0 
f0103568:	c7 44 24 04 61 01 00 	movl   $0x161,0x4(%esp)
f010356f:	00 
f0103570:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f0103577:	e8 3a cb ff ff       	call   f01000b6 <_panic>
	}

	if(header->e_entry == 0){
f010357c:	8b 47 18             	mov    0x18(%edi),%eax
f010357f:	85 c0                	test   %eax,%eax
f0103581:	75 1c                	jne    f010359f <env_create+0x8c>
		panic("load_icode failed: The elf file can't be excuterd.\n");
f0103583:	c7 44 24 08 30 65 10 	movl   $0xf0106530,0x8(%esp)
f010358a:	f0 
f010358b:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f0103592:	00 
f0103593:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f010359a:	e8 17 cb ff ff       	call   f01000b6 <_panic>
	}

	e->env_tf.tf_eip = header->e_entry;
f010359f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01035a2:	89 41 30             	mov    %eax,0x30(%ecx)

	lcr3(PADDR(e->env_pgdir));   
f01035a5:	8b 41 5c             	mov    0x5c(%ecx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01035a8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01035ad:	77 20                	ja     f01035cf <env_create+0xbc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01035af:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035b3:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f01035ba:	f0 
f01035bb:	c7 44 24 04 6a 01 00 	movl   $0x16a,0x4(%esp)
f01035c2:	00 
f01035c3:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f01035ca:	e8 e7 ca ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01035cf:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01035d4:	0f 22 d8             	mov    %eax,%cr3

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
f01035d7:	89 fb                	mov    %edi,%ebx
f01035d9:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + header->e_phnum;
f01035dc:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01035e0:	c1 e6 05             	shl    $0x5,%esi
f01035e3:	01 de                	add    %ebx,%esi
f01035e5:	eb 50                	jmp    f0103637 <env_create+0x124>
	for(; ph < eph; ph++) {
		if(ph->p_type == ELF_PROG_LOAD) {
f01035e7:	83 3b 01             	cmpl   $0x1,(%ebx)
f01035ea:	75 48                	jne    f0103634 <env_create+0x121>
			if(ph->p_memsz - ph->p_filesz < 0) {
				panic("load icode failed : p_memsz < p_filesz.\n");
			}

			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f01035ec:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01035ef:	8b 53 08             	mov    0x8(%ebx),%edx
f01035f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01035f5:	e8 f9 fb ff ff       	call   f01031f3 <region_alloc>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f01035fa:	8b 43 10             	mov    0x10(%ebx),%eax
f01035fd:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103601:	89 f8                	mov    %edi,%eax
f0103603:	03 43 04             	add    0x4(%ebx),%eax
f0103606:	89 44 24 04          	mov    %eax,0x4(%esp)
f010360a:	8b 43 08             	mov    0x8(%ebx),%eax
f010360d:	89 04 24             	mov    %eax,(%esp)
f0103610:	e8 0f 19 00 00       	call   f0104f24 <memmove>
			memset((void *)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f0103615:	8b 43 10             	mov    0x10(%ebx),%eax
f0103618:	8b 53 14             	mov    0x14(%ebx),%edx
f010361b:	29 c2                	sub    %eax,%edx
f010361d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103621:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103628:	00 
f0103629:	03 43 08             	add    0x8(%ebx),%eax
f010362c:	89 04 24             	mov    %eax,(%esp)
f010362f:	e8 a3 18 00 00       	call   f0104ed7 <memset>
	lcr3(PADDR(e->env_pgdir));   

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
	eph = ph + header->e_phnum;
	for(; ph < eph; ph++) {
f0103634:	83 c3 20             	add    $0x20,%ebx
f0103637:	39 de                	cmp    %ebx,%esi
f0103639:	77 ac                	ja     f01035e7 <env_create+0xd4>
	} 
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e,(void *)(USTACKTOP-PGSIZE), PGSIZE);
f010363b:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103640:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103645:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103648:	e8 a6 fb ff ff       	call   f01031f3 <region_alloc>
	if((rc = env_alloc(&e, 0)) != 0) {
		panic("env_create failed: env_alloc failed.\n");
	}

	load_icode(e, binary);
	e->env_type = type;
f010364d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103650:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103653:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103656:	83 c4 3c             	add    $0x3c,%esp
f0103659:	5b                   	pop    %ebx
f010365a:	5e                   	pop    %esi
f010365b:	5f                   	pop    %edi
f010365c:	5d                   	pop    %ebp
f010365d:	c3                   	ret    

f010365e <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010365e:	55                   	push   %ebp
f010365f:	89 e5                	mov    %esp,%ebp
f0103661:	57                   	push   %edi
f0103662:	56                   	push   %esi
f0103663:	53                   	push   %ebx
f0103664:	83 ec 2c             	sub    $0x2c,%esp
f0103667:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010366a:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f010366f:	39 c7                	cmp    %eax,%edi
f0103671:	75 37                	jne    f01036aa <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f0103673:	8b 15 a8 ee 17 f0    	mov    0xf017eea8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103679:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010367f:	77 20                	ja     f01036a1 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103681:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103685:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f010368c:	f0 
f010368d:	c7 44 24 04 a4 01 00 	movl   $0x1a4,0x4(%esp)
f0103694:	00 
f0103695:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f010369c:	e8 15 ca ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036a1:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01036a7:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01036aa:	8b 57 48             	mov    0x48(%edi),%edx
f01036ad:	85 c0                	test   %eax,%eax
f01036af:	74 05                	je     f01036b6 <env_free+0x58>
f01036b1:	8b 40 48             	mov    0x48(%eax),%eax
f01036b4:	eb 05                	jmp    f01036bb <env_free+0x5d>
f01036b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01036bb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01036bf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036c3:	c7 04 24 cd 65 10 f0 	movl   $0xf01065cd,(%esp)
f01036ca:	e8 aa 02 00 00       	call   f0103979 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01036cf:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01036d6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01036d9:	89 c8                	mov    %ecx,%eax
f01036db:	c1 e0 02             	shl    $0x2,%eax
f01036de:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01036e1:	8b 47 5c             	mov    0x5c(%edi),%eax
f01036e4:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f01036e7:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01036ed:	0f 84 b7 00 00 00    	je     f01037aa <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01036f3:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01036f9:	89 f0                	mov    %esi,%eax
f01036fb:	c1 e8 0c             	shr    $0xc,%eax
f01036fe:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103701:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f0103707:	72 20                	jb     f0103729 <env_free+0xcb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103709:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010370d:	c7 44 24 08 44 5a 10 	movl   $0xf0105a44,0x8(%esp)
f0103714:	f0 
f0103715:	c7 44 24 04 b3 01 00 	movl   $0x1b3,0x4(%esp)
f010371c:	00 
f010371d:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f0103724:	e8 8d c9 ff ff       	call   f01000b6 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103729:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010372c:	c1 e0 16             	shl    $0x16,%eax
f010372f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103732:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103737:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f010373e:	01 
f010373f:	74 17                	je     f0103758 <env_free+0xfa>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103741:	89 d8                	mov    %ebx,%eax
f0103743:	c1 e0 0c             	shl    $0xc,%eax
f0103746:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103749:	89 44 24 04          	mov    %eax,0x4(%esp)
f010374d:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103750:	89 04 24             	mov    %eax,(%esp)
f0103753:	e8 2a dd ff ff       	call   f0101482 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103758:	83 c3 01             	add    $0x1,%ebx
f010375b:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103761:	75 d4                	jne    f0103737 <env_free+0xd9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103763:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103766:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103769:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103770:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103773:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f0103779:	72 1c                	jb     f0103797 <env_free+0x139>
		panic("pa2page called with invalid pa");
f010377b:	c7 44 24 08 50 5b 10 	movl   $0xf0105b50,0x8(%esp)
f0103782:	f0 
f0103783:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010378a:	00 
f010378b:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f0103792:	e8 1f c9 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103797:	a1 ac ee 17 f0       	mov    0xf017eeac,%eax
f010379c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010379f:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f01037a2:	89 04 24             	mov    %eax,(%esp)
f01037a5:	e8 44 db ff ff       	call   f01012ee <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01037aa:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01037ae:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f01037b5:	0f 85 1b ff ff ff    	jne    f01036d6 <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01037bb:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01037be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01037c3:	77 20                	ja     f01037e5 <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01037c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01037c9:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f01037d0:	f0 
f01037d1:	c7 44 24 04 c1 01 00 	movl   $0x1c1,0x4(%esp)
f01037d8:	00 
f01037d9:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f01037e0:	e8 d1 c8 ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f01037e5:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f01037ec:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01037f1:	c1 e8 0c             	shr    $0xc,%eax
f01037f4:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f01037fa:	72 1c                	jb     f0103818 <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f01037fc:	c7 44 24 08 50 5b 10 	movl   $0xf0105b50,0x8(%esp)
f0103803:	f0 
f0103804:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010380b:	00 
f010380c:	c7 04 24 ed 61 10 f0 	movl   $0xf01061ed,(%esp)
f0103813:	e8 9e c8 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103818:	8b 15 ac ee 17 f0    	mov    0xf017eeac,%edx
f010381e:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103821:	89 04 24             	mov    %eax,(%esp)
f0103824:	e8 c5 da ff ff       	call   f01012ee <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103829:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103830:	a1 f0 e1 17 f0       	mov    0xf017e1f0,%eax
f0103835:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103838:	89 3d f0 e1 17 f0    	mov    %edi,0xf017e1f0
}
f010383e:	83 c4 2c             	add    $0x2c,%esp
f0103841:	5b                   	pop    %ebx
f0103842:	5e                   	pop    %esi
f0103843:	5f                   	pop    %edi
f0103844:	5d                   	pop    %ebp
f0103845:	c3                   	ret    

f0103846 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103846:	55                   	push   %ebp
f0103847:	89 e5                	mov    %esp,%ebp
f0103849:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f010384c:	8b 45 08             	mov    0x8(%ebp),%eax
f010384f:	89 04 24             	mov    %eax,(%esp)
f0103852:	e8 07 fe ff ff       	call   f010365e <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103857:	c7 04 24 64 65 10 f0 	movl   $0xf0106564,(%esp)
f010385e:	e8 16 01 00 00       	call   f0103979 <cprintf>
	while (1)
		monitor(NULL);
f0103863:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010386a:	e8 76 d3 ff ff       	call   f0100be5 <monitor>
f010386f:	eb f2                	jmp    f0103863 <env_destroy+0x1d>

f0103871 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103871:	55                   	push   %ebp
f0103872:	89 e5                	mov    %esp,%ebp
f0103874:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f0103877:	8b 65 08             	mov    0x8(%ebp),%esp
f010387a:	61                   	popa   
f010387b:	07                   	pop    %es
f010387c:	1f                   	pop    %ds
f010387d:	83 c4 08             	add    $0x8,%esp
f0103880:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103881:	c7 44 24 08 e3 65 10 	movl   $0xf01065e3,0x8(%esp)
f0103888:	f0 
f0103889:	c7 44 24 04 e9 01 00 	movl   $0x1e9,0x4(%esp)
f0103890:	00 
f0103891:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f0103898:	e8 19 c8 ff ff       	call   f01000b6 <_panic>

f010389d <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010389d:	55                   	push   %ebp
f010389e:	89 e5                	mov    %esp,%ebp
f01038a0:	83 ec 18             	sub    $0x18,%esp
f01038a3:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL && curenv->env_status == ENV_RUNNING) {
f01038a6:	8b 15 e8 e1 17 f0    	mov    0xf017e1e8,%edx
f01038ac:	85 d2                	test   %edx,%edx
f01038ae:	74 0d                	je     f01038bd <env_run+0x20>
f01038b0:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f01038b4:	75 07                	jne    f01038bd <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f01038b6:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}

	curenv = e;
f01038bd:	a3 e8 e1 17 f0       	mov    %eax,0xf017e1e8
	curenv->env_status = ENV_RUNNING;
f01038c2:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f01038c9:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f01038cd:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01038d0:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01038d6:	77 20                	ja     f01038f8 <env_run+0x5b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01038d8:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01038dc:	c7 44 24 08 ac 5b 10 	movl   $0xf0105bac,0x8(%esp)
f01038e3:	f0 
f01038e4:	c7 44 24 04 0e 02 00 	movl   $0x20e,0x4(%esp)
f01038eb:	00 
f01038ec:	c7 04 24 9a 65 10 f0 	movl   $0xf010659a,(%esp)
f01038f3:	e8 be c7 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01038f8:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01038fe:	0f 22 da             	mov    %edx,%cr3

	env_pop_tf(&curenv->env_tf);
f0103901:	89 04 24             	mov    %eax,(%esp)
f0103904:	e8 68 ff ff ff       	call   f0103871 <env_pop_tf>

f0103909 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103909:	55                   	push   %ebp
f010390a:	89 e5                	mov    %esp,%ebp
f010390c:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103910:	ba 70 00 00 00       	mov    $0x70,%edx
f0103915:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103916:	b2 71                	mov    $0x71,%dl
f0103918:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103919:	0f b6 c0             	movzbl %al,%eax
}
f010391c:	5d                   	pop    %ebp
f010391d:	c3                   	ret    

f010391e <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010391e:	55                   	push   %ebp
f010391f:	89 e5                	mov    %esp,%ebp
f0103921:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103925:	ba 70 00 00 00       	mov    $0x70,%edx
f010392a:	ee                   	out    %al,(%dx)
f010392b:	b2 71                	mov    $0x71,%dl
f010392d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103930:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103931:	5d                   	pop    %ebp
f0103932:	c3                   	ret    

f0103933 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103933:	55                   	push   %ebp
f0103934:	89 e5                	mov    %esp,%ebp
f0103936:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103939:	8b 45 08             	mov    0x8(%ebp),%eax
f010393c:	89 04 24             	mov    %eax,(%esp)
f010393f:	e8 cd cc ff ff       	call   f0100611 <cputchar>
	*cnt++;
}
f0103944:	c9                   	leave  
f0103945:	c3                   	ret    

f0103946 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103946:	55                   	push   %ebp
f0103947:	89 e5                	mov    %esp,%ebp
f0103949:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010394c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103953:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103956:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010395a:	8b 45 08             	mov    0x8(%ebp),%eax
f010395d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103961:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103964:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103968:	c7 04 24 33 39 10 f0 	movl   $0xf0103933,(%esp)
f010396f:	e8 aa 0e 00 00       	call   f010481e <vprintfmt>
	return cnt;
}
f0103974:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103977:	c9                   	leave  
f0103978:	c3                   	ret    

f0103979 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103979:	55                   	push   %ebp
f010397a:	89 e5                	mov    %esp,%ebp
f010397c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010397f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103982:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103986:	8b 45 08             	mov    0x8(%ebp),%eax
f0103989:	89 04 24             	mov    %eax,(%esp)
f010398c:	e8 b5 ff ff ff       	call   f0103946 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103991:	c9                   	leave  
f0103992:	c3                   	ret    
f0103993:	66 90                	xchg   %ax,%ax
f0103995:	66 90                	xchg   %ax,%ax
f0103997:	66 90                	xchg   %ax,%ax
f0103999:	66 90                	xchg   %ax,%ax
f010399b:	66 90                	xchg   %ax,%ax
f010399d:	66 90                	xchg   %ax,%ax
f010399f:	90                   	nop

f01039a0 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01039a0:	55                   	push   %ebp
f01039a1:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01039a3:	c7 05 24 ea 17 f0 00 	movl   $0xf0000000,0xf017ea24
f01039aa:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01039ad:	66 c7 05 28 ea 17 f0 	movw   $0x10,0xf017ea28
f01039b4:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f01039b6:	66 c7 05 48 c3 11 f0 	movw   $0x67,0xf011c348
f01039bd:	67 00 
f01039bf:	b8 20 ea 17 f0       	mov    $0xf017ea20,%eax
f01039c4:	66 a3 4a c3 11 f0    	mov    %ax,0xf011c34a
f01039ca:	89 c2                	mov    %eax,%edx
f01039cc:	c1 ea 10             	shr    $0x10,%edx
f01039cf:	88 15 4c c3 11 f0    	mov    %dl,0xf011c34c
f01039d5:	c6 05 4e c3 11 f0 40 	movb   $0x40,0xf011c34e
f01039dc:	c1 e8 18             	shr    $0x18,%eax
f01039df:	a2 4f c3 11 f0       	mov    %al,0xf011c34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01039e4:	c6 05 4d c3 11 f0 89 	movb   $0x89,0xf011c34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01039eb:	b8 28 00 00 00       	mov    $0x28,%eax
f01039f0:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01039f3:	b8 50 c3 11 f0       	mov    $0xf011c350,%eax
f01039f8:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01039fb:	5d                   	pop    %ebp
f01039fc:	c3                   	ret    

f01039fd <trap_init>:
}


void
trap_init(void)
{
f01039fd:	55                   	push   %ebp
f01039fe:	89 e5                	mov    %esp,%ebp
	void t_align();
	void t_mchk();
	void t_simderr();
	void t_syscall();	

	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0103a00:	b8 3c 41 10 f0       	mov    $0xf010413c,%eax
f0103a05:	66 a3 00 e2 17 f0    	mov    %ax,0xf017e200
f0103a0b:	66 c7 05 02 e2 17 f0 	movw   $0x8,0xf017e202
f0103a12:	08 00 
f0103a14:	c6 05 04 e2 17 f0 00 	movb   $0x0,0xf017e204
f0103a1b:	c6 05 05 e2 17 f0 8e 	movb   $0x8e,0xf017e205
f0103a22:	c1 e8 10             	shr    $0x10,%eax
f0103a25:	66 a3 06 e2 17 f0    	mov    %ax,0xf017e206
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0103a2b:	b8 42 41 10 f0       	mov    $0xf0104142,%eax
f0103a30:	66 a3 08 e2 17 f0    	mov    %ax,0xf017e208
f0103a36:	66 c7 05 0a e2 17 f0 	movw   $0x8,0xf017e20a
f0103a3d:	08 00 
f0103a3f:	c6 05 0c e2 17 f0 00 	movb   $0x0,0xf017e20c
f0103a46:	c6 05 0d e2 17 f0 8e 	movb   $0x8e,0xf017e20d
f0103a4d:	c1 e8 10             	shr    $0x10,%eax
f0103a50:	66 a3 0e e2 17 f0    	mov    %ax,0xf017e20e
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f0103a56:	b8 48 41 10 f0       	mov    $0xf0104148,%eax
f0103a5b:	66 a3 10 e2 17 f0    	mov    %ax,0xf017e210
f0103a61:	66 c7 05 12 e2 17 f0 	movw   $0x8,0xf017e212
f0103a68:	08 00 
f0103a6a:	c6 05 14 e2 17 f0 00 	movb   $0x0,0xf017e214
f0103a71:	c6 05 15 e2 17 f0 8e 	movb   $0x8e,0xf017e215
f0103a78:	c1 e8 10             	shr    $0x10,%eax
f0103a7b:	66 a3 16 e2 17 f0    	mov    %ax,0xf017e216
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f0103a81:	b8 4e 41 10 f0       	mov    $0xf010414e,%eax
f0103a86:	66 a3 18 e2 17 f0    	mov    %ax,0xf017e218
f0103a8c:	66 c7 05 1a e2 17 f0 	movw   $0x8,0xf017e21a
f0103a93:	08 00 
f0103a95:	c6 05 1c e2 17 f0 00 	movb   $0x0,0xf017e21c
f0103a9c:	c6 05 1d e2 17 f0 ee 	movb   $0xee,0xf017e21d
f0103aa3:	c1 e8 10             	shr    $0x10,%eax
f0103aa6:	66 a3 1e e2 17 f0    	mov    %ax,0xf017e21e
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f0103aac:	b8 54 41 10 f0       	mov    $0xf0104154,%eax
f0103ab1:	66 a3 20 e2 17 f0    	mov    %ax,0xf017e220
f0103ab7:	66 c7 05 22 e2 17 f0 	movw   $0x8,0xf017e222
f0103abe:	08 00 
f0103ac0:	c6 05 24 e2 17 f0 00 	movb   $0x0,0xf017e224
f0103ac7:	c6 05 25 e2 17 f0 8e 	movb   $0x8e,0xf017e225
f0103ace:	c1 e8 10             	shr    $0x10,%eax
f0103ad1:	66 a3 26 e2 17 f0    	mov    %ax,0xf017e226
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f0103ad7:	b8 5a 41 10 f0       	mov    $0xf010415a,%eax
f0103adc:	66 a3 28 e2 17 f0    	mov    %ax,0xf017e228
f0103ae2:	66 c7 05 2a e2 17 f0 	movw   $0x8,0xf017e22a
f0103ae9:	08 00 
f0103aeb:	c6 05 2c e2 17 f0 00 	movb   $0x0,0xf017e22c
f0103af2:	c6 05 2d e2 17 f0 8e 	movb   $0x8e,0xf017e22d
f0103af9:	c1 e8 10             	shr    $0x10,%eax
f0103afc:	66 a3 2e e2 17 f0    	mov    %ax,0xf017e22e
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0103b02:	b8 60 41 10 f0       	mov    $0xf0104160,%eax
f0103b07:	66 a3 30 e2 17 f0    	mov    %ax,0xf017e230
f0103b0d:	66 c7 05 32 e2 17 f0 	movw   $0x8,0xf017e232
f0103b14:	08 00 
f0103b16:	c6 05 34 e2 17 f0 00 	movb   $0x0,0xf017e234
f0103b1d:	c6 05 35 e2 17 f0 8e 	movb   $0x8e,0xf017e235
f0103b24:	c1 e8 10             	shr    $0x10,%eax
f0103b27:	66 a3 36 e2 17 f0    	mov    %ax,0xf017e236
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f0103b2d:	b8 66 41 10 f0       	mov    $0xf0104166,%eax
f0103b32:	66 a3 38 e2 17 f0    	mov    %ax,0xf017e238
f0103b38:	66 c7 05 3a e2 17 f0 	movw   $0x8,0xf017e23a
f0103b3f:	08 00 
f0103b41:	c6 05 3c e2 17 f0 00 	movb   $0x0,0xf017e23c
f0103b48:	c6 05 3d e2 17 f0 8e 	movb   $0x8e,0xf017e23d
f0103b4f:	c1 e8 10             	shr    $0x10,%eax
f0103b52:	66 a3 3e e2 17 f0    	mov    %ax,0xf017e23e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f0103b58:	b8 6c 41 10 f0       	mov    $0xf010416c,%eax
f0103b5d:	66 a3 40 e2 17 f0    	mov    %ax,0xf017e240
f0103b63:	66 c7 05 42 e2 17 f0 	movw   $0x8,0xf017e242
f0103b6a:	08 00 
f0103b6c:	c6 05 44 e2 17 f0 00 	movb   $0x0,0xf017e244
f0103b73:	c6 05 45 e2 17 f0 8e 	movb   $0x8e,0xf017e245
f0103b7a:	c1 e8 10             	shr    $0x10,%eax
f0103b7d:	66 a3 46 e2 17 f0    	mov    %ax,0xf017e246
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f0103b83:	b8 70 41 10 f0       	mov    $0xf0104170,%eax
f0103b88:	66 a3 50 e2 17 f0    	mov    %ax,0xf017e250
f0103b8e:	66 c7 05 52 e2 17 f0 	movw   $0x8,0xf017e252
f0103b95:	08 00 
f0103b97:	c6 05 54 e2 17 f0 00 	movb   $0x0,0xf017e254
f0103b9e:	c6 05 55 e2 17 f0 8e 	movb   $0x8e,0xf017e255
f0103ba5:	c1 e8 10             	shr    $0x10,%eax
f0103ba8:	66 a3 56 e2 17 f0    	mov    %ax,0xf017e256
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f0103bae:	b8 74 41 10 f0       	mov    $0xf0104174,%eax
f0103bb3:	66 a3 58 e2 17 f0    	mov    %ax,0xf017e258
f0103bb9:	66 c7 05 5a e2 17 f0 	movw   $0x8,0xf017e25a
f0103bc0:	08 00 
f0103bc2:	c6 05 5c e2 17 f0 00 	movb   $0x0,0xf017e25c
f0103bc9:	c6 05 5d e2 17 f0 8e 	movb   $0x8e,0xf017e25d
f0103bd0:	c1 e8 10             	shr    $0x10,%eax
f0103bd3:	66 a3 5e e2 17 f0    	mov    %ax,0xf017e25e
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f0103bd9:	b8 78 41 10 f0       	mov    $0xf0104178,%eax
f0103bde:	66 a3 60 e2 17 f0    	mov    %ax,0xf017e260
f0103be4:	66 c7 05 62 e2 17 f0 	movw   $0x8,0xf017e262
f0103beb:	08 00 
f0103bed:	c6 05 64 e2 17 f0 00 	movb   $0x0,0xf017e264
f0103bf4:	c6 05 65 e2 17 f0 8e 	movb   $0x8e,0xf017e265
f0103bfb:	c1 e8 10             	shr    $0x10,%eax
f0103bfe:	66 a3 66 e2 17 f0    	mov    %ax,0xf017e266
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f0103c04:	b8 7c 41 10 f0       	mov    $0xf010417c,%eax
f0103c09:	66 a3 68 e2 17 f0    	mov    %ax,0xf017e268
f0103c0f:	66 c7 05 6a e2 17 f0 	movw   $0x8,0xf017e26a
f0103c16:	08 00 
f0103c18:	c6 05 6c e2 17 f0 00 	movb   $0x0,0xf017e26c
f0103c1f:	c6 05 6d e2 17 f0 8e 	movb   $0x8e,0xf017e26d
f0103c26:	c1 e8 10             	shr    $0x10,%eax
f0103c29:	66 a3 6e e2 17 f0    	mov    %ax,0xf017e26e
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0103c2f:	b8 80 41 10 f0       	mov    $0xf0104180,%eax
f0103c34:	66 a3 70 e2 17 f0    	mov    %ax,0xf017e270
f0103c3a:	66 c7 05 72 e2 17 f0 	movw   $0x8,0xf017e272
f0103c41:	08 00 
f0103c43:	c6 05 74 e2 17 f0 00 	movb   $0x0,0xf017e274
f0103c4a:	c6 05 75 e2 17 f0 8e 	movb   $0x8e,0xf017e275
f0103c51:	c1 e8 10             	shr    $0x10,%eax
f0103c54:	66 a3 76 e2 17 f0    	mov    %ax,0xf017e276
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f0103c5a:	b8 84 41 10 f0       	mov    $0xf0104184,%eax
f0103c5f:	66 a3 80 e2 17 f0    	mov    %ax,0xf017e280
f0103c65:	66 c7 05 82 e2 17 f0 	movw   $0x8,0xf017e282
f0103c6c:	08 00 
f0103c6e:	c6 05 84 e2 17 f0 00 	movb   $0x0,0xf017e284
f0103c75:	c6 05 85 e2 17 f0 8e 	movb   $0x8e,0xf017e285
f0103c7c:	c1 e8 10             	shr    $0x10,%eax
f0103c7f:	66 a3 86 e2 17 f0    	mov    %ax,0xf017e286
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f0103c85:	b8 8a 41 10 f0       	mov    $0xf010418a,%eax
f0103c8a:	66 a3 88 e2 17 f0    	mov    %ax,0xf017e288
f0103c90:	66 c7 05 8a e2 17 f0 	movw   $0x8,0xf017e28a
f0103c97:	08 00 
f0103c99:	c6 05 8c e2 17 f0 00 	movb   $0x0,0xf017e28c
f0103ca0:	c6 05 8d e2 17 f0 8e 	movb   $0x8e,0xf017e28d
f0103ca7:	c1 e8 10             	shr    $0x10,%eax
f0103caa:	66 a3 8e e2 17 f0    	mov    %ax,0xf017e28e
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f0103cb0:	b8 8e 41 10 f0       	mov    $0xf010418e,%eax
f0103cb5:	66 a3 90 e2 17 f0    	mov    %ax,0xf017e290
f0103cbb:	66 c7 05 92 e2 17 f0 	movw   $0x8,0xf017e292
f0103cc2:	08 00 
f0103cc4:	c6 05 94 e2 17 f0 00 	movb   $0x0,0xf017e294
f0103ccb:	c6 05 95 e2 17 f0 8e 	movb   $0x8e,0xf017e295
f0103cd2:	c1 e8 10             	shr    $0x10,%eax
f0103cd5:	66 a3 96 e2 17 f0    	mov    %ax,0xf017e296
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f0103cdb:	b8 94 41 10 f0       	mov    $0xf0104194,%eax
f0103ce0:	66 a3 98 e2 17 f0    	mov    %ax,0xf017e298
f0103ce6:	66 c7 05 9a e2 17 f0 	movw   $0x8,0xf017e29a
f0103ced:	08 00 
f0103cef:	c6 05 9c e2 17 f0 00 	movb   $0x0,0xf017e29c
f0103cf6:	c6 05 9d e2 17 f0 8e 	movb   $0x8e,0xf017e29d
f0103cfd:	c1 e8 10             	shr    $0x10,%eax
f0103d00:	66 a3 9e e2 17 f0    	mov    %ax,0xf017e29e
	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f0103d06:	b8 9a 41 10 f0       	mov    $0xf010419a,%eax
f0103d0b:	66 a3 80 e3 17 f0    	mov    %ax,0xf017e380
f0103d11:	66 c7 05 82 e3 17 f0 	movw   $0x8,0xf017e382
f0103d18:	08 00 
f0103d1a:	c6 05 84 e3 17 f0 00 	movb   $0x0,0xf017e384
f0103d21:	c6 05 85 e3 17 f0 ee 	movb   $0xee,0xf017e385
f0103d28:	c1 e8 10             	shr    $0x10,%eax
f0103d2b:	66 a3 86 e3 17 f0    	mov    %ax,0xf017e386
	// Per-CPU setup 
	trap_init_percpu();
f0103d31:	e8 6a fc ff ff       	call   f01039a0 <trap_init_percpu>
}
f0103d36:	5d                   	pop    %ebp
f0103d37:	c3                   	ret    

f0103d38 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103d38:	55                   	push   %ebp
f0103d39:	89 e5                	mov    %esp,%ebp
f0103d3b:	53                   	push   %ebx
f0103d3c:	83 ec 14             	sub    $0x14,%esp
f0103d3f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103d42:	8b 03                	mov    (%ebx),%eax
f0103d44:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d48:	c7 04 24 ef 65 10 f0 	movl   $0xf01065ef,(%esp)
f0103d4f:	e8 25 fc ff ff       	call   f0103979 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103d54:	8b 43 04             	mov    0x4(%ebx),%eax
f0103d57:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d5b:	c7 04 24 fe 65 10 f0 	movl   $0xf01065fe,(%esp)
f0103d62:	e8 12 fc ff ff       	call   f0103979 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103d67:	8b 43 08             	mov    0x8(%ebx),%eax
f0103d6a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d6e:	c7 04 24 0d 66 10 f0 	movl   $0xf010660d,(%esp)
f0103d75:	e8 ff fb ff ff       	call   f0103979 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103d7a:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d81:	c7 04 24 1c 66 10 f0 	movl   $0xf010661c,(%esp)
f0103d88:	e8 ec fb ff ff       	call   f0103979 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103d8d:	8b 43 10             	mov    0x10(%ebx),%eax
f0103d90:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d94:	c7 04 24 2b 66 10 f0 	movl   $0xf010662b,(%esp)
f0103d9b:	e8 d9 fb ff ff       	call   f0103979 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103da0:	8b 43 14             	mov    0x14(%ebx),%eax
f0103da3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103da7:	c7 04 24 3a 66 10 f0 	movl   $0xf010663a,(%esp)
f0103dae:	e8 c6 fb ff ff       	call   f0103979 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103db3:	8b 43 18             	mov    0x18(%ebx),%eax
f0103db6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dba:	c7 04 24 49 66 10 f0 	movl   $0xf0106649,(%esp)
f0103dc1:	e8 b3 fb ff ff       	call   f0103979 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103dc6:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103dc9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dcd:	c7 04 24 58 66 10 f0 	movl   $0xf0106658,(%esp)
f0103dd4:	e8 a0 fb ff ff       	call   f0103979 <cprintf>
}
f0103dd9:	83 c4 14             	add    $0x14,%esp
f0103ddc:	5b                   	pop    %ebx
f0103ddd:	5d                   	pop    %ebp
f0103dde:	c3                   	ret    

f0103ddf <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103ddf:	55                   	push   %ebp
f0103de0:	89 e5                	mov    %esp,%ebp
f0103de2:	56                   	push   %esi
f0103de3:	53                   	push   %ebx
f0103de4:	83 ec 10             	sub    $0x10,%esp
f0103de7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103dea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103dee:	c7 04 24 8e 67 10 f0 	movl   $0xf010678e,(%esp)
f0103df5:	e8 7f fb ff ff       	call   f0103979 <cprintf>
	print_regs(&tf->tf_regs);
f0103dfa:	89 1c 24             	mov    %ebx,(%esp)
f0103dfd:	e8 36 ff ff ff       	call   f0103d38 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103e02:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103e06:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e0a:	c7 04 24 a9 66 10 f0 	movl   $0xf01066a9,(%esp)
f0103e11:	e8 63 fb ff ff       	call   f0103979 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103e16:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103e1a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e1e:	c7 04 24 bc 66 10 f0 	movl   $0xf01066bc,(%esp)
f0103e25:	e8 4f fb ff ff       	call   f0103979 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e2a:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103e2d:	83 f8 13             	cmp    $0x13,%eax
f0103e30:	77 09                	ja     f0103e3b <print_trapframe+0x5c>
		return excnames[trapno];
f0103e32:	8b 14 85 a0 69 10 f0 	mov    -0xfef9660(,%eax,4),%edx
f0103e39:	eb 10                	jmp    f0103e4b <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0103e3b:	83 f8 30             	cmp    $0x30,%eax
f0103e3e:	ba 67 66 10 f0       	mov    $0xf0106667,%edx
f0103e43:	b9 73 66 10 f0       	mov    $0xf0106673,%ecx
f0103e48:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e4b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103e4f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e53:	c7 04 24 cf 66 10 f0 	movl   $0xf01066cf,(%esp)
f0103e5a:	e8 1a fb ff ff       	call   f0103979 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103e5f:	3b 1d 00 ea 17 f0    	cmp    0xf017ea00,%ebx
f0103e65:	75 19                	jne    f0103e80 <print_trapframe+0xa1>
f0103e67:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103e6b:	75 13                	jne    f0103e80 <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103e6d:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103e70:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e74:	c7 04 24 e1 66 10 f0 	movl   $0xf01066e1,(%esp)
f0103e7b:	e8 f9 fa ff ff       	call   f0103979 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103e80:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103e83:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e87:	c7 04 24 f0 66 10 f0 	movl   $0xf01066f0,(%esp)
f0103e8e:	e8 e6 fa ff ff       	call   f0103979 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103e93:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103e97:	75 51                	jne    f0103eea <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103e99:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103e9c:	89 c2                	mov    %eax,%edx
f0103e9e:	83 e2 01             	and    $0x1,%edx
f0103ea1:	ba 82 66 10 f0       	mov    $0xf0106682,%edx
f0103ea6:	b9 8d 66 10 f0       	mov    $0xf010668d,%ecx
f0103eab:	0f 45 ca             	cmovne %edx,%ecx
f0103eae:	89 c2                	mov    %eax,%edx
f0103eb0:	83 e2 02             	and    $0x2,%edx
f0103eb3:	ba 99 66 10 f0       	mov    $0xf0106699,%edx
f0103eb8:	be 9f 66 10 f0       	mov    $0xf010669f,%esi
f0103ebd:	0f 44 d6             	cmove  %esi,%edx
f0103ec0:	83 e0 04             	and    $0x4,%eax
f0103ec3:	b8 a4 66 10 f0       	mov    $0xf01066a4,%eax
f0103ec8:	be b9 67 10 f0       	mov    $0xf01067b9,%esi
f0103ecd:	0f 44 c6             	cmove  %esi,%eax
f0103ed0:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103ed4:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103ed8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103edc:	c7 04 24 fe 66 10 f0 	movl   $0xf01066fe,(%esp)
f0103ee3:	e8 91 fa ff ff       	call   f0103979 <cprintf>
f0103ee8:	eb 0c                	jmp    f0103ef6 <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103eea:	c7 04 24 7d 64 10 f0 	movl   $0xf010647d,(%esp)
f0103ef1:	e8 83 fa ff ff       	call   f0103979 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103ef6:	8b 43 30             	mov    0x30(%ebx),%eax
f0103ef9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103efd:	c7 04 24 0d 67 10 f0 	movl   $0xf010670d,(%esp)
f0103f04:	e8 70 fa ff ff       	call   f0103979 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103f09:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103f0d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f11:	c7 04 24 1c 67 10 f0 	movl   $0xf010671c,(%esp)
f0103f18:	e8 5c fa ff ff       	call   f0103979 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103f1d:	8b 43 38             	mov    0x38(%ebx),%eax
f0103f20:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f24:	c7 04 24 2f 67 10 f0 	movl   $0xf010672f,(%esp)
f0103f2b:	e8 49 fa ff ff       	call   f0103979 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103f30:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103f34:	74 27                	je     f0103f5d <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103f36:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103f39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f3d:	c7 04 24 3e 67 10 f0 	movl   $0xf010673e,(%esp)
f0103f44:	e8 30 fa ff ff       	call   f0103979 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103f49:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103f4d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f51:	c7 04 24 4d 67 10 f0 	movl   $0xf010674d,(%esp)
f0103f58:	e8 1c fa ff ff       	call   f0103979 <cprintf>
	}
}
f0103f5d:	83 c4 10             	add    $0x10,%esp
f0103f60:	5b                   	pop    %ebx
f0103f61:	5e                   	pop    %esi
f0103f62:	5d                   	pop    %ebp
f0103f63:	c3                   	ret    

f0103f64 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103f64:	55                   	push   %ebp
f0103f65:	89 e5                	mov    %esp,%ebp
f0103f67:	53                   	push   %ebx
f0103f68:	83 ec 14             	sub    $0x14,%esp
f0103f6b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103f6e:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if((tf->tf_cs & 3) == 0) 
f0103f71:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103f75:	75 20                	jne    f0103f97 <page_fault_handler+0x33>
	{
        	panic("page_fault in kernel mode, fault address %d\n", fault_va);
f0103f77:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f7b:	c7 44 24 08 04 69 10 	movl   $0xf0106904,0x8(%esp)
f0103f82:	f0 
f0103f83:	c7 44 24 04 08 01 00 	movl   $0x108,0x4(%esp)
f0103f8a:	00 
f0103f8b:	c7 04 24 60 67 10 f0 	movl   $0xf0106760,(%esp)
f0103f92:	e8 1f c1 ff ff       	call   f01000b6 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103f97:	8b 53 30             	mov    0x30(%ebx),%edx
f0103f9a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103f9e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fa2:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f0103fa7:	8b 40 48             	mov    0x48(%eax),%eax
f0103faa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fae:	c7 04 24 34 69 10 f0 	movl   $0xf0106934,(%esp)
f0103fb5:	e8 bf f9 ff ff       	call   f0103979 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103fba:	89 1c 24             	mov    %ebx,(%esp)
f0103fbd:	e8 1d fe ff ff       	call   f0103ddf <print_trapframe>
	env_destroy(curenv);
f0103fc2:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f0103fc7:	89 04 24             	mov    %eax,(%esp)
f0103fca:	e8 77 f8 ff ff       	call   f0103846 <env_destroy>
}
f0103fcf:	83 c4 14             	add    $0x14,%esp
f0103fd2:	5b                   	pop    %ebx
f0103fd3:	5d                   	pop    %ebp
f0103fd4:	c3                   	ret    

f0103fd5 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103fd5:	55                   	push   %ebp
f0103fd6:	89 e5                	mov    %esp,%ebp
f0103fd8:	57                   	push   %edi
f0103fd9:	56                   	push   %esi
f0103fda:	83 ec 20             	sub    $0x20,%esp
f0103fdd:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103fe0:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103fe1:	9c                   	pushf  
f0103fe2:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103fe3:	f6 c4 02             	test   $0x2,%ah
f0103fe6:	74 24                	je     f010400c <trap+0x37>
f0103fe8:	c7 44 24 0c 6c 67 10 	movl   $0xf010676c,0xc(%esp)
f0103fef:	f0 
f0103ff0:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0103ff7:	f0 
f0103ff8:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
f0103fff:	00 
f0104000:	c7 04 24 60 67 10 f0 	movl   $0xf0106760,(%esp)
f0104007:	e8 aa c0 ff ff       	call   f01000b6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f010400c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104010:	c7 04 24 85 67 10 f0 	movl   $0xf0106785,(%esp)
f0104017:	e8 5d f9 ff ff       	call   f0103979 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f010401c:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104020:	83 e0 03             	and    $0x3,%eax
f0104023:	66 83 f8 03          	cmp    $0x3,%ax
f0104027:	75 3c                	jne    f0104065 <trap+0x90>
		// Trapped from user mode.
		assert(curenv);
f0104029:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f010402e:	85 c0                	test   %eax,%eax
f0104030:	75 24                	jne    f0104056 <trap+0x81>
f0104032:	c7 44 24 0c a0 67 10 	movl   $0xf01067a0,0xc(%esp)
f0104039:	f0 
f010403a:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f0104041:	f0 
f0104042:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
f0104049:	00 
f010404a:	c7 04 24 60 67 10 f0 	movl   $0xf0106760,(%esp)
f0104051:	e8 60 c0 ff ff       	call   f01000b6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0104056:	b9 11 00 00 00       	mov    $0x11,%ecx
f010405b:	89 c7                	mov    %eax,%edi
f010405d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010405f:	8b 35 e8 e1 17 f0    	mov    0xf017e1e8,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0104065:	89 35 00 ea 17 f0    	mov    %esi,0xf017ea00
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno) {
f010406b:	8b 46 28             	mov    0x28(%esi),%eax
f010406e:	83 f8 0e             	cmp    $0xe,%eax
f0104071:	74 0f                	je     f0104082 <trap+0xad>
f0104073:	83 f8 30             	cmp    $0x30,%eax
f0104076:	74 1e                	je     f0104096 <trap+0xc1>
f0104078:	83 f8 03             	cmp    $0x3,%eax
f010407b:	75 4b                	jne    f01040c8 <trap+0xf3>
f010407d:	8d 76 00             	lea    0x0(%esi),%esi
f0104080:	eb 0a                	jmp    f010408c <trap+0xb7>
		case T_PGFLT: 
			page_fault_handler(tf);
f0104082:	89 34 24             	mov    %esi,(%esp)
f0104085:	e8 da fe ff ff       	call   f0103f64 <page_fault_handler>
f010408a:	eb 74                	jmp    f0104100 <trap+0x12b>
			break;
		case T_BRKPT:
			monitor(tf);
f010408c:	89 34 24             	mov    %esi,(%esp)
f010408f:	e8 51 cb ff ff       	call   f0100be5 <monitor>
f0104094:	eb 6a                	jmp    f0104100 <trap+0x12b>
			break;
		case T_SYSCALL:
			 tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0104096:	8b 46 04             	mov    0x4(%esi),%eax
f0104099:	89 44 24 14          	mov    %eax,0x14(%esp)
f010409d:	8b 06                	mov    (%esi),%eax
f010409f:	89 44 24 10          	mov    %eax,0x10(%esp)
f01040a3:	8b 46 10             	mov    0x10(%esi),%eax
f01040a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01040aa:	8b 46 18             	mov    0x18(%esi),%eax
f01040ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040b1:	8b 46 14             	mov    0x14(%esi),%eax
f01040b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040b8:	8b 46 1c             	mov    0x1c(%esi),%eax
f01040bb:	89 04 24             	mov    %eax,(%esp)
f01040be:	e8 fd 00 00 00       	call   f01041c0 <syscall>
f01040c3:	89 46 1c             	mov    %eax,0x1c(%esi)
f01040c6:	eb 38                	jmp    f0104100 <trap+0x12b>
            						tf->tf_regs.reg_edi,
            						tf->tf_regs.reg_esi);
			break;
		default: 
	// Unexpected trap: The user process or the kernel has a bug.
			print_trapframe(tf);
f01040c8:	89 34 24             	mov    %esi,(%esp)
f01040cb:	e8 0f fd ff ff       	call   f0103ddf <print_trapframe>
			if (tf->tf_cs == GD_KT)
f01040d0:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01040d5:	75 1c                	jne    f01040f3 <trap+0x11e>
				panic("unhandled trap in kernel");
f01040d7:	c7 44 24 08 a7 67 10 	movl   $0xf01067a7,0x8(%esp)
f01040de:	f0 
f01040df:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
f01040e6:	00 
f01040e7:	c7 04 24 60 67 10 f0 	movl   $0xf0106760,(%esp)
f01040ee:	e8 c3 bf ff ff       	call   f01000b6 <_panic>
			else 
			{
				env_destroy(curenv);
f01040f3:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01040f8:	89 04 24             	mov    %eax,(%esp)
f01040fb:	e8 46 f7 ff ff       	call   f0103846 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0104100:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f0104105:	85 c0                	test   %eax,%eax
f0104107:	74 06                	je     f010410f <trap+0x13a>
f0104109:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010410d:	74 24                	je     f0104133 <trap+0x15e>
f010410f:	c7 44 24 0c 58 69 10 	movl   $0xf0106958,0xc(%esp)
f0104116:	f0 
f0104117:	c7 44 24 08 13 62 10 	movl   $0xf0106213,0x8(%esp)
f010411e:	f0 
f010411f:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
f0104126:	00 
f0104127:	c7 04 24 60 67 10 f0 	movl   $0xf0106760,(%esp)
f010412e:	e8 83 bf ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f0104133:	89 04 24             	mov    %eax,(%esp)
f0104136:	e8 62 f7 ff ff       	call   f010389d <env_run>
f010413b:	90                   	nop

f010413c <t_divide>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f010413c:	6a 00                	push   $0x0
f010413e:	6a 00                	push   $0x0
f0104140:	eb 5e                	jmp    f01041a0 <_alltraps>

f0104142 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f0104142:	6a 00                	push   $0x0
f0104144:	6a 01                	push   $0x1
f0104146:	eb 58                	jmp    f01041a0 <_alltraps>

f0104148 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f0104148:	6a 00                	push   $0x0
f010414a:	6a 02                	push   $0x2
f010414c:	eb 52                	jmp    f01041a0 <_alltraps>

f010414e <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f010414e:	6a 00                	push   $0x0
f0104150:	6a 03                	push   $0x3
f0104152:	eb 4c                	jmp    f01041a0 <_alltraps>

f0104154 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f0104154:	6a 00                	push   $0x0
f0104156:	6a 04                	push   $0x4
f0104158:	eb 46                	jmp    f01041a0 <_alltraps>

f010415a <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f010415a:	6a 00                	push   $0x0
f010415c:	6a 05                	push   $0x5
f010415e:	eb 40                	jmp    f01041a0 <_alltraps>

f0104160 <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f0104160:	6a 00                	push   $0x0
f0104162:	6a 06                	push   $0x6
f0104164:	eb 3a                	jmp    f01041a0 <_alltraps>

f0104166 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f0104166:	6a 00                	push   $0x0
f0104168:	6a 07                	push   $0x7
f010416a:	eb 34                	jmp    f01041a0 <_alltraps>

f010416c <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f010416c:	6a 08                	push   $0x8
f010416e:	eb 30                	jmp    f01041a0 <_alltraps>

f0104170 <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f0104170:	6a 0a                	push   $0xa
f0104172:	eb 2c                	jmp    f01041a0 <_alltraps>

f0104174 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f0104174:	6a 0b                	push   $0xb
f0104176:	eb 28                	jmp    f01041a0 <_alltraps>

f0104178 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f0104178:	6a 0c                	push   $0xc
f010417a:	eb 24                	jmp    f01041a0 <_alltraps>

f010417c <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f010417c:	6a 0d                	push   $0xd
f010417e:	eb 20                	jmp    f01041a0 <_alltraps>

f0104180 <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f0104180:	6a 0e                	push   $0xe
f0104182:	eb 1c                	jmp    f01041a0 <_alltraps>

f0104184 <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f0104184:	6a 00                	push   $0x0
f0104186:	6a 10                	push   $0x10
f0104188:	eb 16                	jmp    f01041a0 <_alltraps>

f010418a <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f010418a:	6a 11                	push   $0x11
f010418c:	eb 12                	jmp    f01041a0 <_alltraps>

f010418e <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f010418e:	6a 00                	push   $0x0
f0104190:	6a 12                	push   $0x12
f0104192:	eb 0c                	jmp    f01041a0 <_alltraps>

f0104194 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f0104194:	6a 00                	push   $0x0
f0104196:	6a 13                	push   $0x13
f0104198:	eb 06                	jmp    f01041a0 <_alltraps>

f010419a <t_syscall>:

TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f010419a:	6a 00                	push   $0x0
f010419c:	6a 30                	push   $0x30
f010419e:	eb 00                	jmp    f01041a0 <_alltraps>

f01041a0 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
f01041a0:	1e                   	push   %ds
	pushl %es
f01041a1:	06                   	push   %es
	pushal 
f01041a2:	60                   	pusha  

	movl $GD_KD, %eax
f01041a3:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax, %ds
f01041a8:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01041aa:	8e c0                	mov    %eax,%es

	push %esp
f01041ac:	54                   	push   %esp
	call trap	
f01041ad:	e8 23 fe ff ff       	call   f0103fd5 <trap>
f01041b2:	66 90                	xchg   %ax,%ax
f01041b4:	66 90                	xchg   %ax,%ax
f01041b6:	66 90                	xchg   %ax,%ax
f01041b8:	66 90                	xchg   %ax,%ax
f01041ba:	66 90                	xchg   %ax,%ax
f01041bc:	66 90                	xchg   %ax,%ax
f01041be:	66 90                	xchg   %ax,%ax

f01041c0 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01041c0:	55                   	push   %ebp
f01041c1:	89 e5                	mov    %esp,%ebp
f01041c3:	83 ec 28             	sub    $0x28,%esp
f01041c6:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f01041c9:	83 f8 01             	cmp    $0x1,%eax
f01041cc:	74 5e                	je     f010422c <syscall+0x6c>
f01041ce:	83 f8 01             	cmp    $0x1,%eax
f01041d1:	72 12                	jb     f01041e5 <syscall+0x25>
f01041d3:	83 f8 02             	cmp    $0x2,%eax
f01041d6:	74 5b                	je     f0104233 <syscall+0x73>
f01041d8:	83 f8 03             	cmp    $0x3,%eax
f01041db:	74 60                	je     f010423d <syscall+0x7d>
f01041dd:	8d 76 00             	lea    0x0(%esi),%esi
f01041e0:	e9 c4 00 00 00       	jmp    f01042a9 <syscall+0xe9>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, 0);
f01041e5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01041ec:	00 
f01041ed:	8b 45 10             	mov    0x10(%ebp),%eax
f01041f0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01041f4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01041f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041fb:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f0104200:	89 04 24             	mov    %eax,(%esp)
f0104203:	e8 93 ef ff ff       	call   f010319b <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104208:	8b 45 0c             	mov    0xc(%ebp),%eax
f010420b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010420f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104212:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104216:	c7 04 24 f0 69 10 f0 	movl   $0xf01069f0,(%esp)
f010421d:	e8 57 f7 ff ff       	call   f0103979 <cprintf>
	//panic("syscall not implemented");

	switch (syscallno) {
	case SYS_cputs:
        	sys_cputs((char *)a1, a2);
        	return 0;
f0104222:	b8 00 00 00 00       	mov    $0x0,%eax
f0104227:	e9 82 00 00 00       	jmp    f01042ae <syscall+0xee>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010422c:	e8 a4 c2 ff ff       	call   f01004d5 <cons_getc>
	switch (syscallno) {
	case SYS_cputs:
        	sys_cputs((char *)a1, a2);
        	return 0;
    	case SYS_cgetc:
        	return sys_cgetc();
f0104231:	eb 7b                	jmp    f01042ae <syscall+0xee>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104233:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f0104238:	8b 40 48             	mov    0x48(%eax),%eax
        	sys_cputs((char *)a1, a2);
        	return 0;
    	case SYS_cgetc:
        	return sys_cgetc();
    	case SYS_getenvid:
        	return sys_getenvid();
f010423b:	eb 71                	jmp    f01042ae <syscall+0xee>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010423d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104244:	00 
f0104245:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104248:	89 44 24 04          	mov    %eax,0x4(%esp)
f010424c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010424f:	89 04 24             	mov    %eax,(%esp)
f0104252:	e8 37 f0 ff ff       	call   f010328e <envid2env>
f0104257:	85 c0                	test   %eax,%eax
f0104259:	78 53                	js     f01042ae <syscall+0xee>
		return r;
	if (e == curenv)
f010425b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010425e:	8b 15 e8 e1 17 f0    	mov    0xf017e1e8,%edx
f0104264:	39 d0                	cmp    %edx,%eax
f0104266:	75 15                	jne    f010427d <syscall+0xbd>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104268:	8b 40 48             	mov    0x48(%eax),%eax
f010426b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010426f:	c7 04 24 f5 69 10 f0 	movl   $0xf01069f5,(%esp)
f0104276:	e8 fe f6 ff ff       	call   f0103979 <cprintf>
f010427b:	eb 1a                	jmp    f0104297 <syscall+0xd7>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010427d:	8b 40 48             	mov    0x48(%eax),%eax
f0104280:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104284:	8b 42 48             	mov    0x48(%edx),%eax
f0104287:	89 44 24 04          	mov    %eax,0x4(%esp)
f010428b:	c7 04 24 10 6a 10 f0 	movl   $0xf0106a10,(%esp)
f0104292:	e8 e2 f6 ff ff       	call   f0103979 <cprintf>
	env_destroy(e);
f0104297:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010429a:	89 04 24             	mov    %eax,(%esp)
f010429d:	e8 a4 f5 ff ff       	call   f0103846 <env_destroy>
	return 0;
f01042a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01042a7:	eb 05                	jmp    f01042ae <syscall+0xee>
    	case SYS_getenvid:
        	return sys_getenvid();
    	case SYS_env_destroy:
        	return sys_env_destroy(a1);
	default:
		return -E_NO_SYS;
f01042a9:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
}
f01042ae:	c9                   	leave  
f01042af:	c3                   	ret    

f01042b0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01042b0:	55                   	push   %ebp
f01042b1:	89 e5                	mov    %esp,%ebp
f01042b3:	57                   	push   %edi
f01042b4:	56                   	push   %esi
f01042b5:	53                   	push   %ebx
f01042b6:	83 ec 14             	sub    $0x14,%esp
f01042b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01042bc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01042bf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01042c2:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01042c5:	8b 1a                	mov    (%edx),%ebx
f01042c7:	8b 01                	mov    (%ecx),%eax
f01042c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01042cc:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01042d3:	e9 88 00 00 00       	jmp    f0104360 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01042d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01042db:	01 d8                	add    %ebx,%eax
f01042dd:	89 c7                	mov    %eax,%edi
f01042df:	c1 ef 1f             	shr    $0x1f,%edi
f01042e2:	01 c7                	add    %eax,%edi
f01042e4:	d1 ff                	sar    %edi
f01042e6:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01042e9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01042ec:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01042ef:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01042f1:	eb 03                	jmp    f01042f6 <stab_binsearch+0x46>
			m--;
f01042f3:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01042f6:	39 c3                	cmp    %eax,%ebx
f01042f8:	7f 1f                	jg     f0104319 <stab_binsearch+0x69>
f01042fa:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01042fe:	83 ea 0c             	sub    $0xc,%edx
f0104301:	39 f1                	cmp    %esi,%ecx
f0104303:	75 ee                	jne    f01042f3 <stab_binsearch+0x43>
f0104305:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104308:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010430b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010430e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104312:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104315:	76 18                	jbe    f010432f <stab_binsearch+0x7f>
f0104317:	eb 05                	jmp    f010431e <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104319:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f010431c:	eb 42                	jmp    f0104360 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f010431e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104321:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104323:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104326:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010432d:	eb 31                	jmp    f0104360 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010432f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104332:	73 17                	jae    f010434b <stab_binsearch+0x9b>
			*region_right = m - 1;
f0104334:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104337:	83 e8 01             	sub    $0x1,%eax
f010433a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010433d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104340:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104342:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104349:	eb 15                	jmp    f0104360 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010434b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010434e:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0104351:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0104353:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104357:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104359:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104360:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104363:	0f 8e 6f ff ff ff    	jle    f01042d8 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104369:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010436d:	75 0f                	jne    f010437e <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f010436f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104372:	8b 00                	mov    (%eax),%eax
f0104374:	83 e8 01             	sub    $0x1,%eax
f0104377:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010437a:	89 07                	mov    %eax,(%edi)
f010437c:	eb 2c                	jmp    f01043aa <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010437e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104381:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104383:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104386:	8b 0f                	mov    (%edi),%ecx
f0104388:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010438b:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010438e:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104391:	eb 03                	jmp    f0104396 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104393:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104396:	39 c8                	cmp    %ecx,%eax
f0104398:	7e 0b                	jle    f01043a5 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010439a:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010439e:	83 ea 0c             	sub    $0xc,%edx
f01043a1:	39 f3                	cmp    %esi,%ebx
f01043a3:	75 ee                	jne    f0104393 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f01043a5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01043a8:	89 07                	mov    %eax,(%edi)
	}
}
f01043aa:	83 c4 14             	add    $0x14,%esp
f01043ad:	5b                   	pop    %ebx
f01043ae:	5e                   	pop    %esi
f01043af:	5f                   	pop    %edi
f01043b0:	5d                   	pop    %ebp
f01043b1:	c3                   	ret    

f01043b2 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01043b2:	55                   	push   %ebp
f01043b3:	89 e5                	mov    %esp,%ebp
f01043b5:	57                   	push   %edi
f01043b6:	56                   	push   %esi
f01043b7:	53                   	push   %ebx
f01043b8:	83 ec 4c             	sub    $0x4c,%esp
f01043bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01043be:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01043c1:	c7 07 28 6a 10 f0    	movl   $0xf0106a28,(%edi)
	info->eip_line = 0;
f01043c7:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f01043ce:	c7 47 08 28 6a 10 f0 	movl   $0xf0106a28,0x8(%edi)
	info->eip_fn_namelen = 9;
f01043d5:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f01043dc:	89 77 10             	mov    %esi,0x10(%edi)
	info->eip_fn_narg = 0;
f01043df:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01043e6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01043ec:	0f 87 ae 00 00 00    	ja     f01044a0 <debuginfo_eip+0xee>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
f01043f2:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01043f9:	00 
f01043fa:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0104401:	00 
f0104402:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0104409:	00 
f010440a:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f010440f:	89 04 24             	mov    %eax,(%esp)
f0104412:	e8 fc ec ff ff       	call   f0103113 <user_mem_check>
f0104417:	85 c0                	test   %eax,%eax
f0104419:	0f 85 47 02 00 00    	jne    f0104666 <debuginfo_eip+0x2b4>
    			return -1; 
		stabs = usd->stabs;
f010441f:	a1 00 00 20 00       	mov    0x200000,%eax
f0104424:	89 c1                	mov    %eax,%ecx
f0104426:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0104429:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f010442f:	a1 08 00 20 00       	mov    0x200008,%eax
f0104434:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0104437:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010443d:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
f0104440:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104447:	00 
f0104448:	89 d8                	mov    %ebx,%eax
f010444a:	29 c8                	sub    %ecx,%eax
f010444c:	c1 f8 02             	sar    $0x2,%eax
f010444f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104455:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104459:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010445d:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f0104462:	89 04 24             	mov    %eax,(%esp)
f0104465:	e8 a9 ec ff ff       	call   f0103113 <user_mem_check>
f010446a:	85 c0                	test   %eax,%eax
f010446c:	0f 85 fb 01 00 00    	jne    f010466d <debuginfo_eip+0x2bb>
    			return -1;

		if (user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
f0104472:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104479:	00 
f010447a:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010447d:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104480:	29 ca                	sub    %ecx,%edx
f0104482:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104486:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010448a:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f010448f:	89 04 24             	mov    %eax,(%esp)
f0104492:	e8 7c ec ff ff       	call   f0103113 <user_mem_check>
f0104497:	85 c0                	test   %eax,%eax
f0104499:	74 1f                	je     f01044ba <debuginfo_eip+0x108>
f010449b:	e9 d4 01 00 00       	jmp    f0104674 <debuginfo_eip+0x2c2>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01044a0:	c7 45 bc 08 16 11 f0 	movl   $0xf0111608,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01044a7:	c7 45 c0 c9 ea 10 f0 	movl   $0xf010eac9,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01044ae:	bb c8 ea 10 f0       	mov    $0xf010eac8,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01044b3:	c7 45 c4 50 6c 10 f0 	movl   $0xf0106c50,-0x3c(%ebp)
		if (user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
    			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01044ba:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01044bd:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f01044c0:	0f 83 b5 01 00 00    	jae    f010467b <debuginfo_eip+0x2c9>
f01044c6:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01044ca:	0f 85 b2 01 00 00    	jne    f0104682 <debuginfo_eip+0x2d0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01044d0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01044d7:	2b 5d c4             	sub    -0x3c(%ebp),%ebx
f01044da:	c1 fb 02             	sar    $0x2,%ebx
f01044dd:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01044e3:	83 e8 01             	sub    $0x1,%eax
f01044e6:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01044e9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01044ed:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01044f4:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01044f7:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01044fa:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01044fd:	89 d8                	mov    %ebx,%eax
f01044ff:	e8 ac fd ff ff       	call   f01042b0 <stab_binsearch>
	if (lfile == 0)
f0104504:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104507:	85 c0                	test   %eax,%eax
f0104509:	0f 84 7a 01 00 00    	je     f0104689 <debuginfo_eip+0x2d7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010450f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104512:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104515:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104518:	89 74 24 04          	mov    %esi,0x4(%esp)
f010451c:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0104523:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104526:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104529:	89 d8                	mov    %ebx,%eax
f010452b:	e8 80 fd ff ff       	call   f01042b0 <stab_binsearch>

	if (lfun <= rfun) {
f0104530:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104533:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0104536:	39 c8                	cmp    %ecx,%eax
f0104538:	7f 32                	jg     f010456c <debuginfo_eip+0x1ba>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010453a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010453d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104540:	8d 1c 93             	lea    (%ebx,%edx,4),%ebx
f0104543:	8b 13                	mov    (%ebx),%edx
f0104545:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104548:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010454b:	2b 55 c0             	sub    -0x40(%ebp),%edx
f010454e:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0104551:	73 09                	jae    f010455c <debuginfo_eip+0x1aa>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104553:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104556:	03 55 c0             	add    -0x40(%ebp),%edx
f0104559:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010455c:	8b 53 08             	mov    0x8(%ebx),%edx
f010455f:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0104562:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0104564:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104567:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010456a:	eb 0f                	jmp    f010457b <debuginfo_eip+0x1c9>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010456c:	89 77 10             	mov    %esi,0x10(%edi)
		lline = lfile;
f010456f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104572:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104575:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104578:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010457b:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104582:	00 
f0104583:	8b 47 08             	mov    0x8(%edi),%eax
f0104586:	89 04 24             	mov    %eax,(%esp)
f0104589:	e8 2d 09 00 00       	call   f0104ebb <strfind>
f010458e:	2b 47 08             	sub    0x8(%edi),%eax
f0104591:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104594:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104598:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010459f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01045a2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01045a5:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01045a8:	89 f0                	mov    %esi,%eax
f01045aa:	e8 01 fd ff ff       	call   f01042b0 <stab_binsearch>
	if (lline <= rline) 
f01045af:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01045b2:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01045b5:	0f 8f d5 00 00 00    	jg     f0104690 <debuginfo_eip+0x2de>
    		info->eip_line = stabs[rline].n_desc;
f01045bb:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01045be:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f01045c3:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01045c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045c9:	89 c3                	mov    %eax,%ebx
f01045cb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01045ce:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01045d1:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01045d4:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01045d7:	89 df                	mov    %ebx,%edi
f01045d9:	eb 06                	jmp    f01045e1 <debuginfo_eip+0x22f>
f01045db:	83 e8 01             	sub    $0x1,%eax
f01045de:	83 ea 0c             	sub    $0xc,%edx
f01045e1:	89 c6                	mov    %eax,%esi
f01045e3:	39 c7                	cmp    %eax,%edi
f01045e5:	7f 3c                	jg     f0104623 <debuginfo_eip+0x271>
	       && stabs[lline].n_type != N_SOL
f01045e7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01045eb:	80 f9 84             	cmp    $0x84,%cl
f01045ee:	75 08                	jne    f01045f8 <debuginfo_eip+0x246>
f01045f0:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01045f3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01045f6:	eb 11                	jmp    f0104609 <debuginfo_eip+0x257>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01045f8:	80 f9 64             	cmp    $0x64,%cl
f01045fb:	75 de                	jne    f01045db <debuginfo_eip+0x229>
f01045fd:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104601:	74 d8                	je     f01045db <debuginfo_eip+0x229>
f0104603:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104606:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104609:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010460c:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010460f:	8b 04 86             	mov    (%esi,%eax,4),%eax
f0104612:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104615:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104618:	39 d0                	cmp    %edx,%eax
f010461a:	73 0a                	jae    f0104626 <debuginfo_eip+0x274>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010461c:	03 45 c0             	add    -0x40(%ebp),%eax
f010461f:	89 07                	mov    %eax,(%edi)
f0104621:	eb 03                	jmp    f0104626 <debuginfo_eip+0x274>
f0104623:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104626:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104629:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010462c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104631:	39 da                	cmp    %ebx,%edx
f0104633:	7d 67                	jge    f010469c <debuginfo_eip+0x2ea>
		for (lline = lfun + 1;
f0104635:	83 c2 01             	add    $0x1,%edx
f0104638:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010463b:	89 d0                	mov    %edx,%eax
f010463d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104640:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104643:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104646:	eb 04                	jmp    f010464c <debuginfo_eip+0x29a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104648:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010464c:	39 c3                	cmp    %eax,%ebx
f010464e:	7e 47                	jle    f0104697 <debuginfo_eip+0x2e5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104650:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104654:	83 c0 01             	add    $0x1,%eax
f0104657:	83 c2 0c             	add    $0xc,%edx
f010465a:	80 f9 a0             	cmp    $0xa0,%cl
f010465d:	74 e9                	je     f0104648 <debuginfo_eip+0x296>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010465f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104664:	eb 36                	jmp    f010469c <debuginfo_eip+0x2ea>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
    			return -1; 
f0104666:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010466b:	eb 2f                	jmp    f010469c <debuginfo_eip+0x2ea>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
    			return -1;
f010466d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104672:	eb 28                	jmp    f010469c <debuginfo_eip+0x2ea>

		if (user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
    			return -1;
f0104674:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104679:	eb 21                	jmp    f010469c <debuginfo_eip+0x2ea>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010467b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104680:	eb 1a                	jmp    f010469c <debuginfo_eip+0x2ea>
f0104682:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104687:	eb 13                	jmp    f010469c <debuginfo_eip+0x2ea>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104689:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010468e:	eb 0c                	jmp    f010469c <debuginfo_eip+0x2ea>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline) 
    		info->eip_line = stabs[rline].n_desc;
	else 
    		return -1;
f0104690:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104695:	eb 05                	jmp    f010469c <debuginfo_eip+0x2ea>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104697:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010469c:	83 c4 4c             	add    $0x4c,%esp
f010469f:	5b                   	pop    %ebx
f01046a0:	5e                   	pop    %esi
f01046a1:	5f                   	pop    %edi
f01046a2:	5d                   	pop    %ebp
f01046a3:	c3                   	ret    
f01046a4:	66 90                	xchg   %ax,%ax
f01046a6:	66 90                	xchg   %ax,%ax
f01046a8:	66 90                	xchg   %ax,%ax
f01046aa:	66 90                	xchg   %ax,%ax
f01046ac:	66 90                	xchg   %ax,%ax
f01046ae:	66 90                	xchg   %ax,%ax

f01046b0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01046b0:	55                   	push   %ebp
f01046b1:	89 e5                	mov    %esp,%ebp
f01046b3:	57                   	push   %edi
f01046b4:	56                   	push   %esi
f01046b5:	53                   	push   %ebx
f01046b6:	83 ec 3c             	sub    $0x3c,%esp
f01046b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01046bc:	89 d7                	mov    %edx,%edi
f01046be:	8b 45 08             	mov    0x8(%ebp),%eax
f01046c1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01046c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01046c7:	89 c3                	mov    %eax,%ebx
f01046c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01046cc:	8b 45 10             	mov    0x10(%ebp),%eax
f01046cf:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01046d2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01046d7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01046da:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01046dd:	39 d9                	cmp    %ebx,%ecx
f01046df:	72 05                	jb     f01046e6 <printnum+0x36>
f01046e1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01046e4:	77 69                	ja     f010474f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01046e6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01046e9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01046ed:	83 ee 01             	sub    $0x1,%esi
f01046f0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01046f4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01046f8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01046fc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104700:	89 c3                	mov    %eax,%ebx
f0104702:	89 d6                	mov    %edx,%esi
f0104704:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104707:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010470a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010470e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104712:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104715:	89 04 24             	mov    %eax,(%esp)
f0104718:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010471b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010471f:	e8 bc 09 00 00       	call   f01050e0 <__udivdi3>
f0104724:	89 d9                	mov    %ebx,%ecx
f0104726:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010472a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010472e:	89 04 24             	mov    %eax,(%esp)
f0104731:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104735:	89 fa                	mov    %edi,%edx
f0104737:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010473a:	e8 71 ff ff ff       	call   f01046b0 <printnum>
f010473f:	eb 1b                	jmp    f010475c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104741:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104745:	8b 45 18             	mov    0x18(%ebp),%eax
f0104748:	89 04 24             	mov    %eax,(%esp)
f010474b:	ff d3                	call   *%ebx
f010474d:	eb 03                	jmp    f0104752 <printnum+0xa2>
f010474f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104752:	83 ee 01             	sub    $0x1,%esi
f0104755:	85 f6                	test   %esi,%esi
f0104757:	7f e8                	jg     f0104741 <printnum+0x91>
f0104759:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010475c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104760:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104764:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104767:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010476a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010476e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104772:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104775:	89 04 24             	mov    %eax,(%esp)
f0104778:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010477b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010477f:	e8 8c 0a 00 00       	call   f0105210 <__umoddi3>
f0104784:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104788:	0f be 80 32 6a 10 f0 	movsbl -0xfef95ce(%eax),%eax
f010478f:	89 04 24             	mov    %eax,(%esp)
f0104792:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104795:	ff d0                	call   *%eax
}
f0104797:	83 c4 3c             	add    $0x3c,%esp
f010479a:	5b                   	pop    %ebx
f010479b:	5e                   	pop    %esi
f010479c:	5f                   	pop    %edi
f010479d:	5d                   	pop    %ebp
f010479e:	c3                   	ret    

f010479f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010479f:	55                   	push   %ebp
f01047a0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01047a2:	83 fa 01             	cmp    $0x1,%edx
f01047a5:	7e 0e                	jle    f01047b5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01047a7:	8b 10                	mov    (%eax),%edx
f01047a9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01047ac:	89 08                	mov    %ecx,(%eax)
f01047ae:	8b 02                	mov    (%edx),%eax
f01047b0:	8b 52 04             	mov    0x4(%edx),%edx
f01047b3:	eb 22                	jmp    f01047d7 <getuint+0x38>
	else if (lflag)
f01047b5:	85 d2                	test   %edx,%edx
f01047b7:	74 10                	je     f01047c9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01047b9:	8b 10                	mov    (%eax),%edx
f01047bb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01047be:	89 08                	mov    %ecx,(%eax)
f01047c0:	8b 02                	mov    (%edx),%eax
f01047c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01047c7:	eb 0e                	jmp    f01047d7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01047c9:	8b 10                	mov    (%eax),%edx
f01047cb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01047ce:	89 08                	mov    %ecx,(%eax)
f01047d0:	8b 02                	mov    (%edx),%eax
f01047d2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01047d7:	5d                   	pop    %ebp
f01047d8:	c3                   	ret    

f01047d9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01047d9:	55                   	push   %ebp
f01047da:	89 e5                	mov    %esp,%ebp
f01047dc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01047df:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01047e3:	8b 10                	mov    (%eax),%edx
f01047e5:	3b 50 04             	cmp    0x4(%eax),%edx
f01047e8:	73 0a                	jae    f01047f4 <sprintputch+0x1b>
		*b->buf++ = ch;
f01047ea:	8d 4a 01             	lea    0x1(%edx),%ecx
f01047ed:	89 08                	mov    %ecx,(%eax)
f01047ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01047f2:	88 02                	mov    %al,(%edx)
}
f01047f4:	5d                   	pop    %ebp
f01047f5:	c3                   	ret    

f01047f6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01047f6:	55                   	push   %ebp
f01047f7:	89 e5                	mov    %esp,%ebp
f01047f9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01047fc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01047ff:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104803:	8b 45 10             	mov    0x10(%ebp),%eax
f0104806:	89 44 24 08          	mov    %eax,0x8(%esp)
f010480a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010480d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104811:	8b 45 08             	mov    0x8(%ebp),%eax
f0104814:	89 04 24             	mov    %eax,(%esp)
f0104817:	e8 02 00 00 00       	call   f010481e <vprintfmt>
	va_end(ap);
}
f010481c:	c9                   	leave  
f010481d:	c3                   	ret    

f010481e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010481e:	55                   	push   %ebp
f010481f:	89 e5                	mov    %esp,%ebp
f0104821:	57                   	push   %edi
f0104822:	56                   	push   %esi
f0104823:	53                   	push   %ebx
f0104824:	83 ec 3c             	sub    $0x3c,%esp
f0104827:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010482a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010482d:	eb 14                	jmp    f0104843 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010482f:	85 c0                	test   %eax,%eax
f0104831:	0f 84 b3 03 00 00    	je     f0104bea <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0104837:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010483b:	89 04 24             	mov    %eax,(%esp)
f010483e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104841:	89 f3                	mov    %esi,%ebx
f0104843:	8d 73 01             	lea    0x1(%ebx),%esi
f0104846:	0f b6 03             	movzbl (%ebx),%eax
f0104849:	83 f8 25             	cmp    $0x25,%eax
f010484c:	75 e1                	jne    f010482f <vprintfmt+0x11>
f010484e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0104852:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0104859:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0104860:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104867:	ba 00 00 00 00       	mov    $0x0,%edx
f010486c:	eb 1d                	jmp    f010488b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010486e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104870:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0104874:	eb 15                	jmp    f010488b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104876:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104878:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010487c:	eb 0d                	jmp    f010488b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010487e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104881:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104884:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010488b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010488e:	0f b6 0e             	movzbl (%esi),%ecx
f0104891:	0f b6 c1             	movzbl %cl,%eax
f0104894:	83 e9 23             	sub    $0x23,%ecx
f0104897:	80 f9 55             	cmp    $0x55,%cl
f010489a:	0f 87 2a 03 00 00    	ja     f0104bca <vprintfmt+0x3ac>
f01048a0:	0f b6 c9             	movzbl %cl,%ecx
f01048a3:	ff 24 8d c0 6a 10 f0 	jmp    *-0xfef9540(,%ecx,4)
f01048aa:	89 de                	mov    %ebx,%esi
f01048ac:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01048b1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01048b4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01048b8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01048bb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01048be:	83 fb 09             	cmp    $0x9,%ebx
f01048c1:	77 36                	ja     f01048f9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01048c3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01048c6:	eb e9                	jmp    f01048b1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01048c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01048cb:	8d 48 04             	lea    0x4(%eax),%ecx
f01048ce:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01048d1:	8b 00                	mov    (%eax),%eax
f01048d3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01048d6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01048d8:	eb 22                	jmp    f01048fc <vprintfmt+0xde>
f01048da:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01048dd:	85 c9                	test   %ecx,%ecx
f01048df:	b8 00 00 00 00       	mov    $0x0,%eax
f01048e4:	0f 49 c1             	cmovns %ecx,%eax
f01048e7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01048ea:	89 de                	mov    %ebx,%esi
f01048ec:	eb 9d                	jmp    f010488b <vprintfmt+0x6d>
f01048ee:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01048f0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01048f7:	eb 92                	jmp    f010488b <vprintfmt+0x6d>
f01048f9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01048fc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104900:	79 89                	jns    f010488b <vprintfmt+0x6d>
f0104902:	e9 77 ff ff ff       	jmp    f010487e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104907:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010490a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010490c:	e9 7a ff ff ff       	jmp    f010488b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104911:	8b 45 14             	mov    0x14(%ebp),%eax
f0104914:	8d 50 04             	lea    0x4(%eax),%edx
f0104917:	89 55 14             	mov    %edx,0x14(%ebp)
f010491a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010491e:	8b 00                	mov    (%eax),%eax
f0104920:	89 04 24             	mov    %eax,(%esp)
f0104923:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104926:	e9 18 ff ff ff       	jmp    f0104843 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010492b:	8b 45 14             	mov    0x14(%ebp),%eax
f010492e:	8d 50 04             	lea    0x4(%eax),%edx
f0104931:	89 55 14             	mov    %edx,0x14(%ebp)
f0104934:	8b 00                	mov    (%eax),%eax
f0104936:	99                   	cltd   
f0104937:	31 d0                	xor    %edx,%eax
f0104939:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010493b:	83 f8 07             	cmp    $0x7,%eax
f010493e:	7f 0b                	jg     f010494b <vprintfmt+0x12d>
f0104940:	8b 14 85 20 6c 10 f0 	mov    -0xfef93e0(,%eax,4),%edx
f0104947:	85 d2                	test   %edx,%edx
f0104949:	75 20                	jne    f010496b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010494b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010494f:	c7 44 24 08 4a 6a 10 	movl   $0xf0106a4a,0x8(%esp)
f0104956:	f0 
f0104957:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010495b:	8b 45 08             	mov    0x8(%ebp),%eax
f010495e:	89 04 24             	mov    %eax,(%esp)
f0104961:	e8 90 fe ff ff       	call   f01047f6 <printfmt>
f0104966:	e9 d8 fe ff ff       	jmp    f0104843 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010496b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010496f:	c7 44 24 08 25 62 10 	movl   $0xf0106225,0x8(%esp)
f0104976:	f0 
f0104977:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010497b:	8b 45 08             	mov    0x8(%ebp),%eax
f010497e:	89 04 24             	mov    %eax,(%esp)
f0104981:	e8 70 fe ff ff       	call   f01047f6 <printfmt>
f0104986:	e9 b8 fe ff ff       	jmp    f0104843 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010498b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010498e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104991:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104994:	8b 45 14             	mov    0x14(%ebp),%eax
f0104997:	8d 50 04             	lea    0x4(%eax),%edx
f010499a:	89 55 14             	mov    %edx,0x14(%ebp)
f010499d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010499f:	85 f6                	test   %esi,%esi
f01049a1:	b8 43 6a 10 f0       	mov    $0xf0106a43,%eax
f01049a6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01049a9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01049ad:	0f 84 97 00 00 00    	je     f0104a4a <vprintfmt+0x22c>
f01049b3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01049b7:	0f 8e 9b 00 00 00    	jle    f0104a58 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01049bd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01049c1:	89 34 24             	mov    %esi,(%esp)
f01049c4:	e8 9f 03 00 00       	call   f0104d68 <strnlen>
f01049c9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01049cc:	29 c2                	sub    %eax,%edx
f01049ce:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f01049d1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01049d5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01049d8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01049db:	8b 75 08             	mov    0x8(%ebp),%esi
f01049de:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01049e1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01049e3:	eb 0f                	jmp    f01049f4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01049e5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01049e9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01049ec:	89 04 24             	mov    %eax,(%esp)
f01049ef:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01049f1:	83 eb 01             	sub    $0x1,%ebx
f01049f4:	85 db                	test   %ebx,%ebx
f01049f6:	7f ed                	jg     f01049e5 <vprintfmt+0x1c7>
f01049f8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01049fb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01049fe:	85 d2                	test   %edx,%edx
f0104a00:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a05:	0f 49 c2             	cmovns %edx,%eax
f0104a08:	29 c2                	sub    %eax,%edx
f0104a0a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104a0d:	89 d7                	mov    %edx,%edi
f0104a0f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104a12:	eb 50                	jmp    f0104a64 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104a14:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104a18:	74 1e                	je     f0104a38 <vprintfmt+0x21a>
f0104a1a:	0f be d2             	movsbl %dl,%edx
f0104a1d:	83 ea 20             	sub    $0x20,%edx
f0104a20:	83 fa 5e             	cmp    $0x5e,%edx
f0104a23:	76 13                	jbe    f0104a38 <vprintfmt+0x21a>
					putch('?', putdat);
f0104a25:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a28:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a2c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104a33:	ff 55 08             	call   *0x8(%ebp)
f0104a36:	eb 0d                	jmp    f0104a45 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104a38:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104a3b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104a3f:	89 04 24             	mov    %eax,(%esp)
f0104a42:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104a45:	83 ef 01             	sub    $0x1,%edi
f0104a48:	eb 1a                	jmp    f0104a64 <vprintfmt+0x246>
f0104a4a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104a4d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104a50:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104a53:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104a56:	eb 0c                	jmp    f0104a64 <vprintfmt+0x246>
f0104a58:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104a5b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104a5e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104a61:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104a64:	83 c6 01             	add    $0x1,%esi
f0104a67:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0104a6b:	0f be c2             	movsbl %dl,%eax
f0104a6e:	85 c0                	test   %eax,%eax
f0104a70:	74 27                	je     f0104a99 <vprintfmt+0x27b>
f0104a72:	85 db                	test   %ebx,%ebx
f0104a74:	78 9e                	js     f0104a14 <vprintfmt+0x1f6>
f0104a76:	83 eb 01             	sub    $0x1,%ebx
f0104a79:	79 99                	jns    f0104a14 <vprintfmt+0x1f6>
f0104a7b:	89 f8                	mov    %edi,%eax
f0104a7d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104a80:	8b 75 08             	mov    0x8(%ebp),%esi
f0104a83:	89 c3                	mov    %eax,%ebx
f0104a85:	eb 1a                	jmp    f0104aa1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104a87:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104a8b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104a92:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104a94:	83 eb 01             	sub    $0x1,%ebx
f0104a97:	eb 08                	jmp    f0104aa1 <vprintfmt+0x283>
f0104a99:	89 fb                	mov    %edi,%ebx
f0104a9b:	8b 75 08             	mov    0x8(%ebp),%esi
f0104a9e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104aa1:	85 db                	test   %ebx,%ebx
f0104aa3:	7f e2                	jg     f0104a87 <vprintfmt+0x269>
f0104aa5:	89 75 08             	mov    %esi,0x8(%ebp)
f0104aa8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104aab:	e9 93 fd ff ff       	jmp    f0104843 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104ab0:	83 fa 01             	cmp    $0x1,%edx
f0104ab3:	7e 16                	jle    f0104acb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0104ab5:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ab8:	8d 50 08             	lea    0x8(%eax),%edx
f0104abb:	89 55 14             	mov    %edx,0x14(%ebp)
f0104abe:	8b 50 04             	mov    0x4(%eax),%edx
f0104ac1:	8b 00                	mov    (%eax),%eax
f0104ac3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104ac6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104ac9:	eb 32                	jmp    f0104afd <vprintfmt+0x2df>
	else if (lflag)
f0104acb:	85 d2                	test   %edx,%edx
f0104acd:	74 18                	je     f0104ae7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f0104acf:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ad2:	8d 50 04             	lea    0x4(%eax),%edx
f0104ad5:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ad8:	8b 30                	mov    (%eax),%esi
f0104ada:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0104add:	89 f0                	mov    %esi,%eax
f0104adf:	c1 f8 1f             	sar    $0x1f,%eax
f0104ae2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104ae5:	eb 16                	jmp    f0104afd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0104ae7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104aea:	8d 50 04             	lea    0x4(%eax),%edx
f0104aed:	89 55 14             	mov    %edx,0x14(%ebp)
f0104af0:	8b 30                	mov    (%eax),%esi
f0104af2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0104af5:	89 f0                	mov    %esi,%eax
f0104af7:	c1 f8 1f             	sar    $0x1f,%eax
f0104afa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104afd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b00:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104b03:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104b08:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104b0c:	0f 89 80 00 00 00    	jns    f0104b92 <vprintfmt+0x374>
				putch('-', putdat);
f0104b12:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104b16:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104b1d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104b20:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b23:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104b26:	f7 d8                	neg    %eax
f0104b28:	83 d2 00             	adc    $0x0,%edx
f0104b2b:	f7 da                	neg    %edx
			}
			base = 10;
f0104b2d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104b32:	eb 5e                	jmp    f0104b92 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104b34:	8d 45 14             	lea    0x14(%ebp),%eax
f0104b37:	e8 63 fc ff ff       	call   f010479f <getuint>
			base = 10;
f0104b3c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104b41:	eb 4f                	jmp    f0104b92 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint (&ap, lflag);
f0104b43:	8d 45 14             	lea    0x14(%ebp),%eax
f0104b46:	e8 54 fc ff ff       	call   f010479f <getuint>
			base = 8;
f0104b4b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104b50:	eb 40                	jmp    f0104b92 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0104b52:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104b56:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0104b5d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104b60:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104b64:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0104b6b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104b6e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b71:	8d 50 04             	lea    0x4(%eax),%edx
f0104b74:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104b77:	8b 00                	mov    (%eax),%eax
f0104b79:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104b7e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104b83:	eb 0d                	jmp    f0104b92 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104b85:	8d 45 14             	lea    0x14(%ebp),%eax
f0104b88:	e8 12 fc ff ff       	call   f010479f <getuint>
			base = 16;
f0104b8d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104b92:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0104b96:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104b9a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104b9d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104ba1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104ba5:	89 04 24             	mov    %eax,(%esp)
f0104ba8:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104bac:	89 fa                	mov    %edi,%edx
f0104bae:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bb1:	e8 fa fa ff ff       	call   f01046b0 <printnum>
			break;
f0104bb6:	e9 88 fc ff ff       	jmp    f0104843 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104bbb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104bbf:	89 04 24             	mov    %eax,(%esp)
f0104bc2:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104bc5:	e9 79 fc ff ff       	jmp    f0104843 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104bca:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104bce:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104bd5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104bd8:	89 f3                	mov    %esi,%ebx
f0104bda:	eb 03                	jmp    f0104bdf <vprintfmt+0x3c1>
f0104bdc:	83 eb 01             	sub    $0x1,%ebx
f0104bdf:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0104be3:	75 f7                	jne    f0104bdc <vprintfmt+0x3be>
f0104be5:	e9 59 fc ff ff       	jmp    f0104843 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0104bea:	83 c4 3c             	add    $0x3c,%esp
f0104bed:	5b                   	pop    %ebx
f0104bee:	5e                   	pop    %esi
f0104bef:	5f                   	pop    %edi
f0104bf0:	5d                   	pop    %ebp
f0104bf1:	c3                   	ret    

f0104bf2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104bf2:	55                   	push   %ebp
f0104bf3:	89 e5                	mov    %esp,%ebp
f0104bf5:	83 ec 28             	sub    $0x28,%esp
f0104bf8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bfb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104bfe:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104c01:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104c05:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104c08:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104c0f:	85 c0                	test   %eax,%eax
f0104c11:	74 30                	je     f0104c43 <vsnprintf+0x51>
f0104c13:	85 d2                	test   %edx,%edx
f0104c15:	7e 2c                	jle    f0104c43 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104c17:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c1a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104c1e:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c21:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104c25:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104c28:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c2c:	c7 04 24 d9 47 10 f0 	movl   $0xf01047d9,(%esp)
f0104c33:	e8 e6 fb ff ff       	call   f010481e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104c38:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104c3b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104c3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104c41:	eb 05                	jmp    f0104c48 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104c43:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104c48:	c9                   	leave  
f0104c49:	c3                   	ret    

f0104c4a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104c4a:	55                   	push   %ebp
f0104c4b:	89 e5                	mov    %esp,%ebp
f0104c4d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104c50:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104c53:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104c57:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c5a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104c5e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c61:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c65:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c68:	89 04 24             	mov    %eax,(%esp)
f0104c6b:	e8 82 ff ff ff       	call   f0104bf2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104c70:	c9                   	leave  
f0104c71:	c3                   	ret    
f0104c72:	66 90                	xchg   %ax,%ax
f0104c74:	66 90                	xchg   %ax,%ax
f0104c76:	66 90                	xchg   %ax,%ax
f0104c78:	66 90                	xchg   %ax,%ax
f0104c7a:	66 90                	xchg   %ax,%ax
f0104c7c:	66 90                	xchg   %ax,%ax
f0104c7e:	66 90                	xchg   %ax,%ax

f0104c80 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104c80:	55                   	push   %ebp
f0104c81:	89 e5                	mov    %esp,%ebp
f0104c83:	57                   	push   %edi
f0104c84:	56                   	push   %esi
f0104c85:	53                   	push   %ebx
f0104c86:	83 ec 1c             	sub    $0x1c,%esp
f0104c89:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104c8c:	85 c0                	test   %eax,%eax
f0104c8e:	74 10                	je     f0104ca0 <readline+0x20>
		cprintf("%s", prompt);
f0104c90:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c94:	c7 04 24 25 62 10 f0 	movl   $0xf0106225,(%esp)
f0104c9b:	e8 d9 ec ff ff       	call   f0103979 <cprintf>

	i = 0;
	echoing = iscons(0);
f0104ca0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104ca7:	e8 86 b9 ff ff       	call   f0100632 <iscons>
f0104cac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104cae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104cb3:	e8 69 b9 ff ff       	call   f0100621 <getchar>
f0104cb8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104cba:	85 c0                	test   %eax,%eax
f0104cbc:	79 17                	jns    f0104cd5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0104cbe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104cc2:	c7 04 24 40 6c 10 f0 	movl   $0xf0106c40,(%esp)
f0104cc9:	e8 ab ec ff ff       	call   f0103979 <cprintf>
			return NULL;
f0104cce:	b8 00 00 00 00       	mov    $0x0,%eax
f0104cd3:	eb 6d                	jmp    f0104d42 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104cd5:	83 f8 7f             	cmp    $0x7f,%eax
f0104cd8:	74 05                	je     f0104cdf <readline+0x5f>
f0104cda:	83 f8 08             	cmp    $0x8,%eax
f0104cdd:	75 19                	jne    f0104cf8 <readline+0x78>
f0104cdf:	85 f6                	test   %esi,%esi
f0104ce1:	7e 15                	jle    f0104cf8 <readline+0x78>
			if (echoing)
f0104ce3:	85 ff                	test   %edi,%edi
f0104ce5:	74 0c                	je     f0104cf3 <readline+0x73>
				cputchar('\b');
f0104ce7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0104cee:	e8 1e b9 ff ff       	call   f0100611 <cputchar>
			i--;
f0104cf3:	83 ee 01             	sub    $0x1,%esi
f0104cf6:	eb bb                	jmp    f0104cb3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104cf8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104cfe:	7f 1c                	jg     f0104d1c <readline+0x9c>
f0104d00:	83 fb 1f             	cmp    $0x1f,%ebx
f0104d03:	7e 17                	jle    f0104d1c <readline+0x9c>
			if (echoing)
f0104d05:	85 ff                	test   %edi,%edi
f0104d07:	74 08                	je     f0104d11 <readline+0x91>
				cputchar(c);
f0104d09:	89 1c 24             	mov    %ebx,(%esp)
f0104d0c:	e8 00 b9 ff ff       	call   f0100611 <cputchar>
			buf[i++] = c;
f0104d11:	88 9e a0 ea 17 f0    	mov    %bl,-0xfe81560(%esi)
f0104d17:	8d 76 01             	lea    0x1(%esi),%esi
f0104d1a:	eb 97                	jmp    f0104cb3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0104d1c:	83 fb 0d             	cmp    $0xd,%ebx
f0104d1f:	74 05                	je     f0104d26 <readline+0xa6>
f0104d21:	83 fb 0a             	cmp    $0xa,%ebx
f0104d24:	75 8d                	jne    f0104cb3 <readline+0x33>
			if (echoing)
f0104d26:	85 ff                	test   %edi,%edi
f0104d28:	74 0c                	je     f0104d36 <readline+0xb6>
				cputchar('\n');
f0104d2a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104d31:	e8 db b8 ff ff       	call   f0100611 <cputchar>
			buf[i] = 0;
f0104d36:	c6 86 a0 ea 17 f0 00 	movb   $0x0,-0xfe81560(%esi)
			return buf;
f0104d3d:	b8 a0 ea 17 f0       	mov    $0xf017eaa0,%eax
		}
	}
}
f0104d42:	83 c4 1c             	add    $0x1c,%esp
f0104d45:	5b                   	pop    %ebx
f0104d46:	5e                   	pop    %esi
f0104d47:	5f                   	pop    %edi
f0104d48:	5d                   	pop    %ebp
f0104d49:	c3                   	ret    
f0104d4a:	66 90                	xchg   %ax,%ax
f0104d4c:	66 90                	xchg   %ax,%ax
f0104d4e:	66 90                	xchg   %ax,%ax

f0104d50 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104d50:	55                   	push   %ebp
f0104d51:	89 e5                	mov    %esp,%ebp
f0104d53:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104d56:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d5b:	eb 03                	jmp    f0104d60 <strlen+0x10>
		n++;
f0104d5d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104d60:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104d64:	75 f7                	jne    f0104d5d <strlen+0xd>
		n++;
	return n;
}
f0104d66:	5d                   	pop    %ebp
f0104d67:	c3                   	ret    

f0104d68 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104d68:	55                   	push   %ebp
f0104d69:	89 e5                	mov    %esp,%ebp
f0104d6b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104d6e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104d71:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d76:	eb 03                	jmp    f0104d7b <strnlen+0x13>
		n++;
f0104d78:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104d7b:	39 d0                	cmp    %edx,%eax
f0104d7d:	74 06                	je     f0104d85 <strnlen+0x1d>
f0104d7f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104d83:	75 f3                	jne    f0104d78 <strnlen+0x10>
		n++;
	return n;
}
f0104d85:	5d                   	pop    %ebp
f0104d86:	c3                   	ret    

f0104d87 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104d87:	55                   	push   %ebp
f0104d88:	89 e5                	mov    %esp,%ebp
f0104d8a:	53                   	push   %ebx
f0104d8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d8e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104d91:	89 c2                	mov    %eax,%edx
f0104d93:	83 c2 01             	add    $0x1,%edx
f0104d96:	83 c1 01             	add    $0x1,%ecx
f0104d99:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104d9d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104da0:	84 db                	test   %bl,%bl
f0104da2:	75 ef                	jne    f0104d93 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104da4:	5b                   	pop    %ebx
f0104da5:	5d                   	pop    %ebp
f0104da6:	c3                   	ret    

f0104da7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104da7:	55                   	push   %ebp
f0104da8:	89 e5                	mov    %esp,%ebp
f0104daa:	53                   	push   %ebx
f0104dab:	83 ec 08             	sub    $0x8,%esp
f0104dae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104db1:	89 1c 24             	mov    %ebx,(%esp)
f0104db4:	e8 97 ff ff ff       	call   f0104d50 <strlen>
	strcpy(dst + len, src);
f0104db9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104dbc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104dc0:	01 d8                	add    %ebx,%eax
f0104dc2:	89 04 24             	mov    %eax,(%esp)
f0104dc5:	e8 bd ff ff ff       	call   f0104d87 <strcpy>
	return dst;
}
f0104dca:	89 d8                	mov    %ebx,%eax
f0104dcc:	83 c4 08             	add    $0x8,%esp
f0104dcf:	5b                   	pop    %ebx
f0104dd0:	5d                   	pop    %ebp
f0104dd1:	c3                   	ret    

f0104dd2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104dd2:	55                   	push   %ebp
f0104dd3:	89 e5                	mov    %esp,%ebp
f0104dd5:	56                   	push   %esi
f0104dd6:	53                   	push   %ebx
f0104dd7:	8b 75 08             	mov    0x8(%ebp),%esi
f0104dda:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104ddd:	89 f3                	mov    %esi,%ebx
f0104ddf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104de2:	89 f2                	mov    %esi,%edx
f0104de4:	eb 0f                	jmp    f0104df5 <strncpy+0x23>
		*dst++ = *src;
f0104de6:	83 c2 01             	add    $0x1,%edx
f0104de9:	0f b6 01             	movzbl (%ecx),%eax
f0104dec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104def:	80 39 01             	cmpb   $0x1,(%ecx)
f0104df2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104df5:	39 da                	cmp    %ebx,%edx
f0104df7:	75 ed                	jne    f0104de6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104df9:	89 f0                	mov    %esi,%eax
f0104dfb:	5b                   	pop    %ebx
f0104dfc:	5e                   	pop    %esi
f0104dfd:	5d                   	pop    %ebp
f0104dfe:	c3                   	ret    

f0104dff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104dff:	55                   	push   %ebp
f0104e00:	89 e5                	mov    %esp,%ebp
f0104e02:	56                   	push   %esi
f0104e03:	53                   	push   %ebx
f0104e04:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e07:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e0a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104e0d:	89 f0                	mov    %esi,%eax
f0104e0f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104e13:	85 c9                	test   %ecx,%ecx
f0104e15:	75 0b                	jne    f0104e22 <strlcpy+0x23>
f0104e17:	eb 1d                	jmp    f0104e36 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104e19:	83 c0 01             	add    $0x1,%eax
f0104e1c:	83 c2 01             	add    $0x1,%edx
f0104e1f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104e22:	39 d8                	cmp    %ebx,%eax
f0104e24:	74 0b                	je     f0104e31 <strlcpy+0x32>
f0104e26:	0f b6 0a             	movzbl (%edx),%ecx
f0104e29:	84 c9                	test   %cl,%cl
f0104e2b:	75 ec                	jne    f0104e19 <strlcpy+0x1a>
f0104e2d:	89 c2                	mov    %eax,%edx
f0104e2f:	eb 02                	jmp    f0104e33 <strlcpy+0x34>
f0104e31:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104e33:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104e36:	29 f0                	sub    %esi,%eax
}
f0104e38:	5b                   	pop    %ebx
f0104e39:	5e                   	pop    %esi
f0104e3a:	5d                   	pop    %ebp
f0104e3b:	c3                   	ret    

f0104e3c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104e3c:	55                   	push   %ebp
f0104e3d:	89 e5                	mov    %esp,%ebp
f0104e3f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104e42:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104e45:	eb 06                	jmp    f0104e4d <strcmp+0x11>
		p++, q++;
f0104e47:	83 c1 01             	add    $0x1,%ecx
f0104e4a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104e4d:	0f b6 01             	movzbl (%ecx),%eax
f0104e50:	84 c0                	test   %al,%al
f0104e52:	74 04                	je     f0104e58 <strcmp+0x1c>
f0104e54:	3a 02                	cmp    (%edx),%al
f0104e56:	74 ef                	je     f0104e47 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104e58:	0f b6 c0             	movzbl %al,%eax
f0104e5b:	0f b6 12             	movzbl (%edx),%edx
f0104e5e:	29 d0                	sub    %edx,%eax
}
f0104e60:	5d                   	pop    %ebp
f0104e61:	c3                   	ret    

f0104e62 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104e62:	55                   	push   %ebp
f0104e63:	89 e5                	mov    %esp,%ebp
f0104e65:	53                   	push   %ebx
f0104e66:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e69:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e6c:	89 c3                	mov    %eax,%ebx
f0104e6e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104e71:	eb 06                	jmp    f0104e79 <strncmp+0x17>
		n--, p++, q++;
f0104e73:	83 c0 01             	add    $0x1,%eax
f0104e76:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104e79:	39 d8                	cmp    %ebx,%eax
f0104e7b:	74 15                	je     f0104e92 <strncmp+0x30>
f0104e7d:	0f b6 08             	movzbl (%eax),%ecx
f0104e80:	84 c9                	test   %cl,%cl
f0104e82:	74 04                	je     f0104e88 <strncmp+0x26>
f0104e84:	3a 0a                	cmp    (%edx),%cl
f0104e86:	74 eb                	je     f0104e73 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104e88:	0f b6 00             	movzbl (%eax),%eax
f0104e8b:	0f b6 12             	movzbl (%edx),%edx
f0104e8e:	29 d0                	sub    %edx,%eax
f0104e90:	eb 05                	jmp    f0104e97 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104e92:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104e97:	5b                   	pop    %ebx
f0104e98:	5d                   	pop    %ebp
f0104e99:	c3                   	ret    

f0104e9a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104e9a:	55                   	push   %ebp
f0104e9b:	89 e5                	mov    %esp,%ebp
f0104e9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ea0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104ea4:	eb 07                	jmp    f0104ead <strchr+0x13>
		if (*s == c)
f0104ea6:	38 ca                	cmp    %cl,%dl
f0104ea8:	74 0f                	je     f0104eb9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104eaa:	83 c0 01             	add    $0x1,%eax
f0104ead:	0f b6 10             	movzbl (%eax),%edx
f0104eb0:	84 d2                	test   %dl,%dl
f0104eb2:	75 f2                	jne    f0104ea6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104eb4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104eb9:	5d                   	pop    %ebp
f0104eba:	c3                   	ret    

f0104ebb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104ebb:	55                   	push   %ebp
f0104ebc:	89 e5                	mov    %esp,%ebp
f0104ebe:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ec1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104ec5:	eb 07                	jmp    f0104ece <strfind+0x13>
		if (*s == c)
f0104ec7:	38 ca                	cmp    %cl,%dl
f0104ec9:	74 0a                	je     f0104ed5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104ecb:	83 c0 01             	add    $0x1,%eax
f0104ece:	0f b6 10             	movzbl (%eax),%edx
f0104ed1:	84 d2                	test   %dl,%dl
f0104ed3:	75 f2                	jne    f0104ec7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104ed5:	5d                   	pop    %ebp
f0104ed6:	c3                   	ret    

f0104ed7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104ed7:	55                   	push   %ebp
f0104ed8:	89 e5                	mov    %esp,%ebp
f0104eda:	57                   	push   %edi
f0104edb:	56                   	push   %esi
f0104edc:	53                   	push   %ebx
f0104edd:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104ee0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104ee3:	85 c9                	test   %ecx,%ecx
f0104ee5:	74 36                	je     f0104f1d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104ee7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104eed:	75 28                	jne    f0104f17 <memset+0x40>
f0104eef:	f6 c1 03             	test   $0x3,%cl
f0104ef2:	75 23                	jne    f0104f17 <memset+0x40>
		c &= 0xFF;
f0104ef4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104ef8:	89 d3                	mov    %edx,%ebx
f0104efa:	c1 e3 08             	shl    $0x8,%ebx
f0104efd:	89 d6                	mov    %edx,%esi
f0104eff:	c1 e6 18             	shl    $0x18,%esi
f0104f02:	89 d0                	mov    %edx,%eax
f0104f04:	c1 e0 10             	shl    $0x10,%eax
f0104f07:	09 f0                	or     %esi,%eax
f0104f09:	09 c2                	or     %eax,%edx
f0104f0b:	89 d0                	mov    %edx,%eax
f0104f0d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104f0f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104f12:	fc                   	cld    
f0104f13:	f3 ab                	rep stos %eax,%es:(%edi)
f0104f15:	eb 06                	jmp    f0104f1d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104f17:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104f1a:	fc                   	cld    
f0104f1b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104f1d:	89 f8                	mov    %edi,%eax
f0104f1f:	5b                   	pop    %ebx
f0104f20:	5e                   	pop    %esi
f0104f21:	5f                   	pop    %edi
f0104f22:	5d                   	pop    %ebp
f0104f23:	c3                   	ret    

f0104f24 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104f24:	55                   	push   %ebp
f0104f25:	89 e5                	mov    %esp,%ebp
f0104f27:	57                   	push   %edi
f0104f28:	56                   	push   %esi
f0104f29:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f2c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104f2f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104f32:	39 c6                	cmp    %eax,%esi
f0104f34:	73 35                	jae    f0104f6b <memmove+0x47>
f0104f36:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104f39:	39 d0                	cmp    %edx,%eax
f0104f3b:	73 2e                	jae    f0104f6b <memmove+0x47>
		s += n;
		d += n;
f0104f3d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104f40:	89 d6                	mov    %edx,%esi
f0104f42:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104f44:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104f4a:	75 13                	jne    f0104f5f <memmove+0x3b>
f0104f4c:	f6 c1 03             	test   $0x3,%cl
f0104f4f:	75 0e                	jne    f0104f5f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104f51:	83 ef 04             	sub    $0x4,%edi
f0104f54:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104f57:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104f5a:	fd                   	std    
f0104f5b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104f5d:	eb 09                	jmp    f0104f68 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104f5f:	83 ef 01             	sub    $0x1,%edi
f0104f62:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104f65:	fd                   	std    
f0104f66:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104f68:	fc                   	cld    
f0104f69:	eb 1d                	jmp    f0104f88 <memmove+0x64>
f0104f6b:	89 f2                	mov    %esi,%edx
f0104f6d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104f6f:	f6 c2 03             	test   $0x3,%dl
f0104f72:	75 0f                	jne    f0104f83 <memmove+0x5f>
f0104f74:	f6 c1 03             	test   $0x3,%cl
f0104f77:	75 0a                	jne    f0104f83 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104f79:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0104f7c:	89 c7                	mov    %eax,%edi
f0104f7e:	fc                   	cld    
f0104f7f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104f81:	eb 05                	jmp    f0104f88 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104f83:	89 c7                	mov    %eax,%edi
f0104f85:	fc                   	cld    
f0104f86:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104f88:	5e                   	pop    %esi
f0104f89:	5f                   	pop    %edi
f0104f8a:	5d                   	pop    %ebp
f0104f8b:	c3                   	ret    

f0104f8c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104f8c:	55                   	push   %ebp
f0104f8d:	89 e5                	mov    %esp,%ebp
f0104f8f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104f92:	8b 45 10             	mov    0x10(%ebp),%eax
f0104f95:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104f99:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104f9c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104fa0:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fa3:	89 04 24             	mov    %eax,(%esp)
f0104fa6:	e8 79 ff ff ff       	call   f0104f24 <memmove>
}
f0104fab:	c9                   	leave  
f0104fac:	c3                   	ret    

f0104fad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104fad:	55                   	push   %ebp
f0104fae:	89 e5                	mov    %esp,%ebp
f0104fb0:	56                   	push   %esi
f0104fb1:	53                   	push   %ebx
f0104fb2:	8b 55 08             	mov    0x8(%ebp),%edx
f0104fb5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104fb8:	89 d6                	mov    %edx,%esi
f0104fba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104fbd:	eb 1a                	jmp    f0104fd9 <memcmp+0x2c>
		if (*s1 != *s2)
f0104fbf:	0f b6 02             	movzbl (%edx),%eax
f0104fc2:	0f b6 19             	movzbl (%ecx),%ebx
f0104fc5:	38 d8                	cmp    %bl,%al
f0104fc7:	74 0a                	je     f0104fd3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104fc9:	0f b6 c0             	movzbl %al,%eax
f0104fcc:	0f b6 db             	movzbl %bl,%ebx
f0104fcf:	29 d8                	sub    %ebx,%eax
f0104fd1:	eb 0f                	jmp    f0104fe2 <memcmp+0x35>
		s1++, s2++;
f0104fd3:	83 c2 01             	add    $0x1,%edx
f0104fd6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104fd9:	39 f2                	cmp    %esi,%edx
f0104fdb:	75 e2                	jne    f0104fbf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104fdd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104fe2:	5b                   	pop    %ebx
f0104fe3:	5e                   	pop    %esi
f0104fe4:	5d                   	pop    %ebp
f0104fe5:	c3                   	ret    

f0104fe6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104fe6:	55                   	push   %ebp
f0104fe7:	89 e5                	mov    %esp,%ebp
f0104fe9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104fef:	89 c2                	mov    %eax,%edx
f0104ff1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104ff4:	eb 07                	jmp    f0104ffd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104ff6:	38 08                	cmp    %cl,(%eax)
f0104ff8:	74 07                	je     f0105001 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104ffa:	83 c0 01             	add    $0x1,%eax
f0104ffd:	39 d0                	cmp    %edx,%eax
f0104fff:	72 f5                	jb     f0104ff6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105001:	5d                   	pop    %ebp
f0105002:	c3                   	ret    

f0105003 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105003:	55                   	push   %ebp
f0105004:	89 e5                	mov    %esp,%ebp
f0105006:	57                   	push   %edi
f0105007:	56                   	push   %esi
f0105008:	53                   	push   %ebx
f0105009:	8b 55 08             	mov    0x8(%ebp),%edx
f010500c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010500f:	eb 03                	jmp    f0105014 <strtol+0x11>
		s++;
f0105011:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105014:	0f b6 0a             	movzbl (%edx),%ecx
f0105017:	80 f9 09             	cmp    $0x9,%cl
f010501a:	74 f5                	je     f0105011 <strtol+0xe>
f010501c:	80 f9 20             	cmp    $0x20,%cl
f010501f:	74 f0                	je     f0105011 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105021:	80 f9 2b             	cmp    $0x2b,%cl
f0105024:	75 0a                	jne    f0105030 <strtol+0x2d>
		s++;
f0105026:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105029:	bf 00 00 00 00       	mov    $0x0,%edi
f010502e:	eb 11                	jmp    f0105041 <strtol+0x3e>
f0105030:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105035:	80 f9 2d             	cmp    $0x2d,%cl
f0105038:	75 07                	jne    f0105041 <strtol+0x3e>
		s++, neg = 1;
f010503a:	8d 52 01             	lea    0x1(%edx),%edx
f010503d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105041:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0105046:	75 15                	jne    f010505d <strtol+0x5a>
f0105048:	80 3a 30             	cmpb   $0x30,(%edx)
f010504b:	75 10                	jne    f010505d <strtol+0x5a>
f010504d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105051:	75 0a                	jne    f010505d <strtol+0x5a>
		s += 2, base = 16;
f0105053:	83 c2 02             	add    $0x2,%edx
f0105056:	b8 10 00 00 00       	mov    $0x10,%eax
f010505b:	eb 10                	jmp    f010506d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010505d:	85 c0                	test   %eax,%eax
f010505f:	75 0c                	jne    f010506d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105061:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105063:	80 3a 30             	cmpb   $0x30,(%edx)
f0105066:	75 05                	jne    f010506d <strtol+0x6a>
		s++, base = 8;
f0105068:	83 c2 01             	add    $0x1,%edx
f010506b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010506d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105072:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105075:	0f b6 0a             	movzbl (%edx),%ecx
f0105078:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010507b:	89 f0                	mov    %esi,%eax
f010507d:	3c 09                	cmp    $0x9,%al
f010507f:	77 08                	ja     f0105089 <strtol+0x86>
			dig = *s - '0';
f0105081:	0f be c9             	movsbl %cl,%ecx
f0105084:	83 e9 30             	sub    $0x30,%ecx
f0105087:	eb 20                	jmp    f01050a9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0105089:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010508c:	89 f0                	mov    %esi,%eax
f010508e:	3c 19                	cmp    $0x19,%al
f0105090:	77 08                	ja     f010509a <strtol+0x97>
			dig = *s - 'a' + 10;
f0105092:	0f be c9             	movsbl %cl,%ecx
f0105095:	83 e9 57             	sub    $0x57,%ecx
f0105098:	eb 0f                	jmp    f01050a9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010509a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010509d:	89 f0                	mov    %esi,%eax
f010509f:	3c 19                	cmp    $0x19,%al
f01050a1:	77 16                	ja     f01050b9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01050a3:	0f be c9             	movsbl %cl,%ecx
f01050a6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01050a9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01050ac:	7d 0f                	jge    f01050bd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01050ae:	83 c2 01             	add    $0x1,%edx
f01050b1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01050b5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01050b7:	eb bc                	jmp    f0105075 <strtol+0x72>
f01050b9:	89 d8                	mov    %ebx,%eax
f01050bb:	eb 02                	jmp    f01050bf <strtol+0xbc>
f01050bd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01050bf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01050c3:	74 05                	je     f01050ca <strtol+0xc7>
		*endptr = (char *) s;
f01050c5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01050c8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01050ca:	f7 d8                	neg    %eax
f01050cc:	85 ff                	test   %edi,%edi
f01050ce:	0f 44 c3             	cmove  %ebx,%eax
}
f01050d1:	5b                   	pop    %ebx
f01050d2:	5e                   	pop    %esi
f01050d3:	5f                   	pop    %edi
f01050d4:	5d                   	pop    %ebp
f01050d5:	c3                   	ret    
f01050d6:	66 90                	xchg   %ax,%ax
f01050d8:	66 90                	xchg   %ax,%ax
f01050da:	66 90                	xchg   %ax,%ax
f01050dc:	66 90                	xchg   %ax,%ax
f01050de:	66 90                	xchg   %ax,%ax

f01050e0 <__udivdi3>:
f01050e0:	55                   	push   %ebp
f01050e1:	57                   	push   %edi
f01050e2:	56                   	push   %esi
f01050e3:	83 ec 0c             	sub    $0xc,%esp
f01050e6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01050ea:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01050ee:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01050f2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01050f6:	85 c0                	test   %eax,%eax
f01050f8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01050fc:	89 ea                	mov    %ebp,%edx
f01050fe:	89 0c 24             	mov    %ecx,(%esp)
f0105101:	75 2d                	jne    f0105130 <__udivdi3+0x50>
f0105103:	39 e9                	cmp    %ebp,%ecx
f0105105:	77 61                	ja     f0105168 <__udivdi3+0x88>
f0105107:	85 c9                	test   %ecx,%ecx
f0105109:	89 ce                	mov    %ecx,%esi
f010510b:	75 0b                	jne    f0105118 <__udivdi3+0x38>
f010510d:	b8 01 00 00 00       	mov    $0x1,%eax
f0105112:	31 d2                	xor    %edx,%edx
f0105114:	f7 f1                	div    %ecx
f0105116:	89 c6                	mov    %eax,%esi
f0105118:	31 d2                	xor    %edx,%edx
f010511a:	89 e8                	mov    %ebp,%eax
f010511c:	f7 f6                	div    %esi
f010511e:	89 c5                	mov    %eax,%ebp
f0105120:	89 f8                	mov    %edi,%eax
f0105122:	f7 f6                	div    %esi
f0105124:	89 ea                	mov    %ebp,%edx
f0105126:	83 c4 0c             	add    $0xc,%esp
f0105129:	5e                   	pop    %esi
f010512a:	5f                   	pop    %edi
f010512b:	5d                   	pop    %ebp
f010512c:	c3                   	ret    
f010512d:	8d 76 00             	lea    0x0(%esi),%esi
f0105130:	39 e8                	cmp    %ebp,%eax
f0105132:	77 24                	ja     f0105158 <__udivdi3+0x78>
f0105134:	0f bd e8             	bsr    %eax,%ebp
f0105137:	83 f5 1f             	xor    $0x1f,%ebp
f010513a:	75 3c                	jne    f0105178 <__udivdi3+0x98>
f010513c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0105140:	39 34 24             	cmp    %esi,(%esp)
f0105143:	0f 86 9f 00 00 00    	jbe    f01051e8 <__udivdi3+0x108>
f0105149:	39 d0                	cmp    %edx,%eax
f010514b:	0f 82 97 00 00 00    	jb     f01051e8 <__udivdi3+0x108>
f0105151:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105158:	31 d2                	xor    %edx,%edx
f010515a:	31 c0                	xor    %eax,%eax
f010515c:	83 c4 0c             	add    $0xc,%esp
f010515f:	5e                   	pop    %esi
f0105160:	5f                   	pop    %edi
f0105161:	5d                   	pop    %ebp
f0105162:	c3                   	ret    
f0105163:	90                   	nop
f0105164:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105168:	89 f8                	mov    %edi,%eax
f010516a:	f7 f1                	div    %ecx
f010516c:	31 d2                	xor    %edx,%edx
f010516e:	83 c4 0c             	add    $0xc,%esp
f0105171:	5e                   	pop    %esi
f0105172:	5f                   	pop    %edi
f0105173:	5d                   	pop    %ebp
f0105174:	c3                   	ret    
f0105175:	8d 76 00             	lea    0x0(%esi),%esi
f0105178:	89 e9                	mov    %ebp,%ecx
f010517a:	8b 3c 24             	mov    (%esp),%edi
f010517d:	d3 e0                	shl    %cl,%eax
f010517f:	89 c6                	mov    %eax,%esi
f0105181:	b8 20 00 00 00       	mov    $0x20,%eax
f0105186:	29 e8                	sub    %ebp,%eax
f0105188:	89 c1                	mov    %eax,%ecx
f010518a:	d3 ef                	shr    %cl,%edi
f010518c:	89 e9                	mov    %ebp,%ecx
f010518e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0105192:	8b 3c 24             	mov    (%esp),%edi
f0105195:	09 74 24 08          	or     %esi,0x8(%esp)
f0105199:	89 d6                	mov    %edx,%esi
f010519b:	d3 e7                	shl    %cl,%edi
f010519d:	89 c1                	mov    %eax,%ecx
f010519f:	89 3c 24             	mov    %edi,(%esp)
f01051a2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01051a6:	d3 ee                	shr    %cl,%esi
f01051a8:	89 e9                	mov    %ebp,%ecx
f01051aa:	d3 e2                	shl    %cl,%edx
f01051ac:	89 c1                	mov    %eax,%ecx
f01051ae:	d3 ef                	shr    %cl,%edi
f01051b0:	09 d7                	or     %edx,%edi
f01051b2:	89 f2                	mov    %esi,%edx
f01051b4:	89 f8                	mov    %edi,%eax
f01051b6:	f7 74 24 08          	divl   0x8(%esp)
f01051ba:	89 d6                	mov    %edx,%esi
f01051bc:	89 c7                	mov    %eax,%edi
f01051be:	f7 24 24             	mull   (%esp)
f01051c1:	39 d6                	cmp    %edx,%esi
f01051c3:	89 14 24             	mov    %edx,(%esp)
f01051c6:	72 30                	jb     f01051f8 <__udivdi3+0x118>
f01051c8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01051cc:	89 e9                	mov    %ebp,%ecx
f01051ce:	d3 e2                	shl    %cl,%edx
f01051d0:	39 c2                	cmp    %eax,%edx
f01051d2:	73 05                	jae    f01051d9 <__udivdi3+0xf9>
f01051d4:	3b 34 24             	cmp    (%esp),%esi
f01051d7:	74 1f                	je     f01051f8 <__udivdi3+0x118>
f01051d9:	89 f8                	mov    %edi,%eax
f01051db:	31 d2                	xor    %edx,%edx
f01051dd:	e9 7a ff ff ff       	jmp    f010515c <__udivdi3+0x7c>
f01051e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01051e8:	31 d2                	xor    %edx,%edx
f01051ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01051ef:	e9 68 ff ff ff       	jmp    f010515c <__udivdi3+0x7c>
f01051f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01051f8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01051fb:	31 d2                	xor    %edx,%edx
f01051fd:	83 c4 0c             	add    $0xc,%esp
f0105200:	5e                   	pop    %esi
f0105201:	5f                   	pop    %edi
f0105202:	5d                   	pop    %ebp
f0105203:	c3                   	ret    
f0105204:	66 90                	xchg   %ax,%ax
f0105206:	66 90                	xchg   %ax,%ax
f0105208:	66 90                	xchg   %ax,%ax
f010520a:	66 90                	xchg   %ax,%ax
f010520c:	66 90                	xchg   %ax,%ax
f010520e:	66 90                	xchg   %ax,%ax

f0105210 <__umoddi3>:
f0105210:	55                   	push   %ebp
f0105211:	57                   	push   %edi
f0105212:	56                   	push   %esi
f0105213:	83 ec 14             	sub    $0x14,%esp
f0105216:	8b 44 24 28          	mov    0x28(%esp),%eax
f010521a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010521e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0105222:	89 c7                	mov    %eax,%edi
f0105224:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105228:	8b 44 24 30          	mov    0x30(%esp),%eax
f010522c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0105230:	89 34 24             	mov    %esi,(%esp)
f0105233:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105237:	85 c0                	test   %eax,%eax
f0105239:	89 c2                	mov    %eax,%edx
f010523b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010523f:	75 17                	jne    f0105258 <__umoddi3+0x48>
f0105241:	39 fe                	cmp    %edi,%esi
f0105243:	76 4b                	jbe    f0105290 <__umoddi3+0x80>
f0105245:	89 c8                	mov    %ecx,%eax
f0105247:	89 fa                	mov    %edi,%edx
f0105249:	f7 f6                	div    %esi
f010524b:	89 d0                	mov    %edx,%eax
f010524d:	31 d2                	xor    %edx,%edx
f010524f:	83 c4 14             	add    $0x14,%esp
f0105252:	5e                   	pop    %esi
f0105253:	5f                   	pop    %edi
f0105254:	5d                   	pop    %ebp
f0105255:	c3                   	ret    
f0105256:	66 90                	xchg   %ax,%ax
f0105258:	39 f8                	cmp    %edi,%eax
f010525a:	77 54                	ja     f01052b0 <__umoddi3+0xa0>
f010525c:	0f bd e8             	bsr    %eax,%ebp
f010525f:	83 f5 1f             	xor    $0x1f,%ebp
f0105262:	75 5c                	jne    f01052c0 <__umoddi3+0xb0>
f0105264:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0105268:	39 3c 24             	cmp    %edi,(%esp)
f010526b:	0f 87 e7 00 00 00    	ja     f0105358 <__umoddi3+0x148>
f0105271:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105275:	29 f1                	sub    %esi,%ecx
f0105277:	19 c7                	sbb    %eax,%edi
f0105279:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010527d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105281:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105285:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105289:	83 c4 14             	add    $0x14,%esp
f010528c:	5e                   	pop    %esi
f010528d:	5f                   	pop    %edi
f010528e:	5d                   	pop    %ebp
f010528f:	c3                   	ret    
f0105290:	85 f6                	test   %esi,%esi
f0105292:	89 f5                	mov    %esi,%ebp
f0105294:	75 0b                	jne    f01052a1 <__umoddi3+0x91>
f0105296:	b8 01 00 00 00       	mov    $0x1,%eax
f010529b:	31 d2                	xor    %edx,%edx
f010529d:	f7 f6                	div    %esi
f010529f:	89 c5                	mov    %eax,%ebp
f01052a1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01052a5:	31 d2                	xor    %edx,%edx
f01052a7:	f7 f5                	div    %ebp
f01052a9:	89 c8                	mov    %ecx,%eax
f01052ab:	f7 f5                	div    %ebp
f01052ad:	eb 9c                	jmp    f010524b <__umoddi3+0x3b>
f01052af:	90                   	nop
f01052b0:	89 c8                	mov    %ecx,%eax
f01052b2:	89 fa                	mov    %edi,%edx
f01052b4:	83 c4 14             	add    $0x14,%esp
f01052b7:	5e                   	pop    %esi
f01052b8:	5f                   	pop    %edi
f01052b9:	5d                   	pop    %ebp
f01052ba:	c3                   	ret    
f01052bb:	90                   	nop
f01052bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01052c0:	8b 04 24             	mov    (%esp),%eax
f01052c3:	be 20 00 00 00       	mov    $0x20,%esi
f01052c8:	89 e9                	mov    %ebp,%ecx
f01052ca:	29 ee                	sub    %ebp,%esi
f01052cc:	d3 e2                	shl    %cl,%edx
f01052ce:	89 f1                	mov    %esi,%ecx
f01052d0:	d3 e8                	shr    %cl,%eax
f01052d2:	89 e9                	mov    %ebp,%ecx
f01052d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01052d8:	8b 04 24             	mov    (%esp),%eax
f01052db:	09 54 24 04          	or     %edx,0x4(%esp)
f01052df:	89 fa                	mov    %edi,%edx
f01052e1:	d3 e0                	shl    %cl,%eax
f01052e3:	89 f1                	mov    %esi,%ecx
f01052e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01052e9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01052ed:	d3 ea                	shr    %cl,%edx
f01052ef:	89 e9                	mov    %ebp,%ecx
f01052f1:	d3 e7                	shl    %cl,%edi
f01052f3:	89 f1                	mov    %esi,%ecx
f01052f5:	d3 e8                	shr    %cl,%eax
f01052f7:	89 e9                	mov    %ebp,%ecx
f01052f9:	09 f8                	or     %edi,%eax
f01052fb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01052ff:	f7 74 24 04          	divl   0x4(%esp)
f0105303:	d3 e7                	shl    %cl,%edi
f0105305:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105309:	89 d7                	mov    %edx,%edi
f010530b:	f7 64 24 08          	mull   0x8(%esp)
f010530f:	39 d7                	cmp    %edx,%edi
f0105311:	89 c1                	mov    %eax,%ecx
f0105313:	89 14 24             	mov    %edx,(%esp)
f0105316:	72 2c                	jb     f0105344 <__umoddi3+0x134>
f0105318:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010531c:	72 22                	jb     f0105340 <__umoddi3+0x130>
f010531e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105322:	29 c8                	sub    %ecx,%eax
f0105324:	19 d7                	sbb    %edx,%edi
f0105326:	89 e9                	mov    %ebp,%ecx
f0105328:	89 fa                	mov    %edi,%edx
f010532a:	d3 e8                	shr    %cl,%eax
f010532c:	89 f1                	mov    %esi,%ecx
f010532e:	d3 e2                	shl    %cl,%edx
f0105330:	89 e9                	mov    %ebp,%ecx
f0105332:	d3 ef                	shr    %cl,%edi
f0105334:	09 d0                	or     %edx,%eax
f0105336:	89 fa                	mov    %edi,%edx
f0105338:	83 c4 14             	add    $0x14,%esp
f010533b:	5e                   	pop    %esi
f010533c:	5f                   	pop    %edi
f010533d:	5d                   	pop    %ebp
f010533e:	c3                   	ret    
f010533f:	90                   	nop
f0105340:	39 d7                	cmp    %edx,%edi
f0105342:	75 da                	jne    f010531e <__umoddi3+0x10e>
f0105344:	8b 14 24             	mov    (%esp),%edx
f0105347:	89 c1                	mov    %eax,%ecx
f0105349:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010534d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0105351:	eb cb                	jmp    f010531e <__umoddi3+0x10e>
f0105353:	90                   	nop
f0105354:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105358:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010535c:	0f 82 0f ff ff ff    	jb     f0105271 <__umoddi3+0x61>
f0105362:	e9 1a ff ff ff       	jmp    f0105281 <__umoddi3+0x71>
