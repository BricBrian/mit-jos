
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 00 1a 10 f0 	movl   $0xf0101a00,(%esp)
f0100055:	e8 a2 09 00 00       	call   f01009fc <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 08 07 00 00       	call   f010078f <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 1c 1a 10 f0 	movl   $0xf0101a1c,(%esp)
f0100092:	e8 65 09 00 00       	call   f01009fc <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 a2 14 00 00       	call   f0101567 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 95 04 00 00       	call   f010055f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 37 1a 10 f0 	movl   $0xf0101a37,(%esp)
f01000d9:	e8 1e 09 00 00       	call   f01009fc <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 48 07 00 00       	call   f010083e <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 52 1a 10 f0 	movl   $0xf0101a52,(%esp)
f010012c:	e8 cb 08 00 00       	call   f01009fc <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 8c 08 00 00       	call   f01009c9 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 8e 1a 10 f0 	movl   $0xf0101a8e,(%esp)
f0100144:	e8 b3 08 00 00       	call   f01009fc <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 e9 06 00 00       	call   f010083e <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 6a 1a 10 f0 	movl   $0xf0101a6a,(%esp)
f0100176:	e8 81 08 00 00       	call   f01009fc <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 3f 08 00 00       	call   f01009c9 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 8e 1a 10 f0 	movl   $0xf0101a8e,(%esp)
f0100191:	e8 66 08 00 00       	call   f01009fc <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 e0 1b 10 f0 	movzbl -0xfefe420(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 e0 1b 10 f0 	movzbl -0xfefe420(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a e0 1a 10 f0 	movzbl -0xfefe520(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d c0 1a 10 f0 	mov    -0xfefe540(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 84 1a 10 f0 	movl   $0xf0101a84,(%esp)
f01002e9:	e8 0e 07 00 00       	call   f01009fc <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi
f0100314:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100319:	be fd 03 00 00       	mov    $0x3fd,%esi
f010031e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100323:	eb 06                	jmp    f010032b <cons_putc+0x22>
f0100325:	89 ca                	mov    %ecx,%edx
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
f0100329:	ec                   	in     (%dx),%al
f010032a:	ec                   	in     (%dx),%al
f010032b:	89 f2                	mov    %esi,%edx
f010032d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010032e:	a8 20                	test   $0x20,%al
f0100330:	75 05                	jne    f0100337 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100332:	83 eb 01             	sub    $0x1,%ebx
f0100335:	75 ee                	jne    f0100325 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	0f b6 c0             	movzbl %al,%eax
f010033c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010033f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100344:	ee                   	out    %al,(%dx)
f0100345:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034a:	be 79 03 00 00       	mov    $0x379,%esi
f010034f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100354:	eb 06                	jmp    f010035c <cons_putc+0x53>
f0100356:	89 ca                	mov    %ecx,%edx
f0100358:	ec                   	in     (%dx),%al
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	ec                   	in     (%dx),%al
f010035c:	89 f2                	mov    %esi,%edx
f010035e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010035f:	84 c0                	test   %al,%al
f0100361:	78 05                	js     f0100368 <cons_putc+0x5f>
f0100363:	83 eb 01             	sub    $0x1,%ebx
f0100366:	75 ee                	jne    f0100356 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100368:	ba 78 03 00 00       	mov    $0x378,%edx
f010036d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100371:	ee                   	out    %al,(%dx)
f0100372:	b2 7a                	mov    $0x7a,%dl
f0100374:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100379:	ee                   	out    %al,(%dx)
f010037a:	b8 08 00 00 00       	mov    $0x8,%eax
f010037f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100380:	89 fa                	mov    %edi,%edx
f0100382:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100388:	89 f8                	mov    %edi,%eax
f010038a:	80 cc 07             	or     $0x7,%ah
f010038d:	85 d2                	test   %edx,%edx
f010038f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100392:	89 f8                	mov    %edi,%eax
f0100394:	0f b6 c0             	movzbl %al,%eax
f0100397:	83 f8 09             	cmp    $0x9,%eax
f010039a:	74 76                	je     f0100412 <cons_putc+0x109>
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	7f 0a                	jg     f01003ab <cons_putc+0xa2>
f01003a1:	83 f8 08             	cmp    $0x8,%eax
f01003a4:	74 16                	je     f01003bc <cons_putc+0xb3>
f01003a6:	e9 9b 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
f01003ab:	83 f8 0a             	cmp    $0xa,%eax
f01003ae:	66 90                	xchg   %ax,%ax
f01003b0:	74 3a                	je     f01003ec <cons_putc+0xe3>
f01003b2:	83 f8 0d             	cmp    $0xd,%eax
f01003b5:	74 3d                	je     f01003f4 <cons_putc+0xeb>
f01003b7:	e9 8a 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01003bc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003c3:	66 85 c0             	test   %ax,%ax
f01003c6:	0f 84 e5 00 00 00    	je     f01004b1 <cons_putc+0x1a8>
			crt_pos--;
f01003cc:	83 e8 01             	sub    $0x1,%eax
f01003cf:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003d5:	0f b7 c0             	movzwl %ax,%eax
f01003d8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003dd:	83 cf 20             	or     $0x20,%edi
f01003e0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003e6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ea:	eb 78                	jmp    f0100464 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ec:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003f3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003f4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003fb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100401:	c1 e8 16             	shr    $0x16,%eax
f0100404:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100407:	c1 e0 04             	shl    $0x4,%eax
f010040a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100410:	eb 52                	jmp    f0100464 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 ed fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 e3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100426:	b8 20 00 00 00       	mov    $0x20,%eax
f010042b:	e8 d9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 cf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 c5 fe ff ff       	call   f0100309 <cons_putc>
f0100444:	eb 1e                	jmp    f0100464 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100446:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010044d:	8d 50 01             	lea    0x1(%eax),%edx
f0100450:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100457:	0f b7 c0             	movzwl %ax,%eax
f010045a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100460:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100464:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010046b:	cf 07 
f010046d:	76 42                	jbe    f01004b1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010046f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100474:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010047b:	00 
f010047c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100482:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100486:	89 04 24             	mov    %eax,(%esp)
f0100489:	e8 26 11 00 00       	call   f01015b4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010048e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100494:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100499:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010049f:	83 c0 01             	add    $0x1,%eax
f01004a2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004a7:	75 f0                	jne    f0100499 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004a9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004b0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004b1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004bc:	89 ca                	mov    %ecx,%edx
f01004be:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004bf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004c6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004c9:	89 d8                	mov    %ebx,%eax
f01004cb:	66 c1 e8 08          	shr    $0x8,%ax
f01004cf:	89 f2                	mov    %esi,%edx
f01004d1:	ee                   	out    %al,(%dx)
f01004d2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004d7:	89 ca                	mov    %ecx,%edx
f01004d9:	ee                   	out    %al,(%dx)
f01004da:	89 d8                	mov    %ebx,%eax
f01004dc:	89 f2                	mov    %esi,%edx
f01004de:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004df:	83 c4 1c             	add    $0x1c,%esp
f01004e2:	5b                   	pop    %ebx
f01004e3:	5e                   	pop    %esi
f01004e4:	5f                   	pop    %edi
f01004e5:	5d                   	pop    %ebp
f01004e6:	c3                   	ret    

f01004e7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004e7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004ee:	74 11                	je     f0100501 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004f0:	55                   	push   %ebp
f01004f1:	89 e5                	mov    %esp,%ebp
f01004f3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004f6:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004fb:	e8 bc fc ff ff       	call   f01001bc <cons_intr>
}
f0100500:	c9                   	leave  
f0100501:	f3 c3                	repz ret 

f0100503 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100503:	55                   	push   %ebp
f0100504:	89 e5                	mov    %esp,%ebp
f0100506:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100509:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010050e:	e8 a9 fc ff ff       	call   f01001bc <cons_intr>
}
f0100513:	c9                   	leave  
f0100514:	c3                   	ret    

f0100515 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100515:	55                   	push   %ebp
f0100516:	89 e5                	mov    %esp,%ebp
f0100518:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051b:	e8 c7 ff ff ff       	call   f01004e7 <serial_intr>
	kbd_intr();
f0100520:	e8 de ff ff ff       	call   f0100503 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100525:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010052a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100530:	74 26                	je     f0100558 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100532:	8d 50 01             	lea    0x1(%eax),%edx
f0100535:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010053b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100542:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100544:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054a:	75 11                	jne    f010055d <cons_getc+0x48>
			cons.rpos = 0;
f010054c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100553:	00 00 00 
f0100556:	eb 05                	jmp    f010055d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100558:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010055d:	c9                   	leave  
f010055e:	c3                   	ret    

f010055f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055f:	55                   	push   %ebp
f0100560:	89 e5                	mov    %esp,%ebp
f0100562:	57                   	push   %edi
f0100563:	56                   	push   %esi
f0100564:	53                   	push   %ebx
f0100565:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100568:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100576:	5a a5 
	if (*cp != 0xA55A) {
f0100578:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100583:	74 11                	je     f0100596 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100585:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010058c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100594:	eb 16                	jmp    f01005ac <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100596:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059d:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005a4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005ac:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005b2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ba:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bd:	89 da                	mov    %ebx,%edx
f01005bf:	ec                   	in     (%dx),%al
f01005c0:	0f b6 f0             	movzbl %al,%esi
f01005c3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005cb:	89 ca                	mov    %ecx,%edx
f01005cd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ce:	89 da                	mov    %ebx,%edx
f01005d0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d7:	0f b6 d8             	movzbl %al,%ebx
f01005da:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005dc:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ed:	89 f2                	mov    %esi,%edx
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	b2 fb                	mov    $0xfb,%dl
f01005f2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005fd:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100602:	89 da                	mov    %ebx,%edx
f0100604:	ee                   	out    %al,(%dx)
f0100605:	b2 f9                	mov    $0xf9,%dl
f0100607:	b8 00 00 00 00       	mov    $0x0,%eax
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 fb                	mov    $0xfb,%dl
f010060f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 fc                	mov    $0xfc,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 f9                	mov    $0xf9,%dl
f010061f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100624:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100625:	b2 fd                	mov    $0xfd,%dl
f0100627:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100628:	3c ff                	cmp    $0xff,%al
f010062a:	0f 95 c1             	setne  %cl
f010062d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100633:	89 f2                	mov    %esi,%edx
f0100635:	ec                   	in     (%dx),%al
f0100636:	89 da                	mov    %ebx,%edx
f0100638:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100639:	84 c9                	test   %cl,%cl
f010063b:	75 0c                	jne    f0100649 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010063d:	c7 04 24 90 1a 10 f0 	movl   $0xf0101a90,(%esp)
f0100644:	e8 b3 03 00 00       	call   f01009fc <cprintf>
}
f0100649:	83 c4 1c             	add    $0x1c,%esp
f010064c:	5b                   	pop    %ebx
f010064d:	5e                   	pop    %esi
f010064e:	5f                   	pop    %edi
f010064f:	5d                   	pop    %ebp
f0100650:	c3                   	ret    

f0100651 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100651:	55                   	push   %ebp
f0100652:	89 e5                	mov    %esp,%ebp
f0100654:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100657:	8b 45 08             	mov    0x8(%ebp),%eax
f010065a:	e8 aa fc ff ff       	call   f0100309 <cons_putc>
}
f010065f:	c9                   	leave  
f0100660:	c3                   	ret    

f0100661 <getchar>:

int
getchar(void)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100667:	e8 a9 fe ff ff       	call   f0100515 <cons_getc>
f010066c:	85 c0                	test   %eax,%eax
f010066e:	74 f7                	je     f0100667 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <iscons>:

int
iscons(int fdnum)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100675:	b8 01 00 00 00       	mov    $0x1,%eax
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100686:	c7 44 24 08 e0 1c 10 	movl   $0xf0101ce0,0x8(%esp)
f010068d:	f0 
f010068e:	c7 44 24 04 fe 1c 10 	movl   $0xf0101cfe,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 03 1d 10 f0 	movl   $0xf0101d03,(%esp)
f010069d:	e8 5a 03 00 00       	call   f01009fc <cprintf>
f01006a2:	c7 44 24 08 b4 1d 10 	movl   $0xf0101db4,0x8(%esp)
f01006a9:	f0 
f01006aa:	c7 44 24 04 0c 1d 10 	movl   $0xf0101d0c,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 03 1d 10 f0 	movl   $0xf0101d03,(%esp)
f01006b9:	e8 3e 03 00 00       	call   f01009fc <cprintf>
	return 0;
}
f01006be:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c3:	c9                   	leave  
f01006c4:	c3                   	ret    

f01006c5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c5:	55                   	push   %ebp
f01006c6:	89 e5                	mov    %esp,%ebp
f01006c8:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cb:	c7 04 24 15 1d 10 f0 	movl   $0xf0101d15,(%esp)
f01006d2:	e8 25 03 00 00       	call   f01009fc <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006de:	00 
f01006df:	c7 04 24 dc 1d 10 f0 	movl   $0xf0101ddc,(%esp)
f01006e6:	e8 11 03 00 00       	call   f01009fc <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006eb:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006f2:	00 
f01006f3:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006fa:	f0 
f01006fb:	c7 04 24 04 1e 10 f0 	movl   $0xf0101e04,(%esp)
f0100702:	e8 f5 02 00 00       	call   f01009fc <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100707:	c7 44 24 08 f7 19 10 	movl   $0x1019f7,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 f7 19 10 	movl   $0xf01019f7,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 28 1e 10 f0 	movl   $0xf0101e28,(%esp)
f010071e:	e8 d9 02 00 00       	call   f01009fc <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100723:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 4c 1e 10 f0 	movl   $0xf0101e4c,(%esp)
f010073a:	e8 bd 02 00 00       	call   f01009fc <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073f:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 70 1e 10 f0 	movl   $0xf0101e70,(%esp)
f0100756:	e8 a1 02 00 00       	call   f01009fc <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010075b:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100760:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100765:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010076a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100770:	85 c0                	test   %eax,%eax
f0100772:	0f 48 c2             	cmovs  %edx,%eax
f0100775:	c1 f8 0a             	sar    $0xa,%eax
f0100778:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077c:	c7 04 24 94 1e 10 f0 	movl   $0xf0101e94,(%esp)
f0100783:	e8 74 02 00 00       	call   f01009fc <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100788:	b8 00 00 00 00       	mov    $0x0,%eax
f010078d:	c9                   	leave  
f010078e:	c3                   	ret    

f010078f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
f0100792:	57                   	push   %edi
f0100793:	56                   	push   %esi
f0100794:	53                   	push   %ebx
f0100795:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	int i;
	uint32_t eip;
	uint32_t* ebp = (uint32_t *)read_ebp();
f0100798:	89 ee                	mov    %ebp,%esi

	while (ebp) {
f010079a:	e9 8a 00 00 00       	jmp    f0100829 <mon_backtrace+0x9a>
		eip = *(ebp + 1);
f010079f:	8b 46 04             	mov    0x4(%esi),%eax
f01007a2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		cprintf("ebp %x eip %x args", ebp, eip);
f01007a5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007a9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007ad:	c7 04 24 2e 1d 10 f0 	movl   $0xf0101d2e,(%esp)
f01007b4:	e8 43 02 00 00       	call   f01009fc <cprintf>
		uint32_t *args = ebp + 2;
f01007b9:	8d 5e 08             	lea    0x8(%esi),%ebx
f01007bc:	8d 7e 1c             	lea    0x1c(%esi),%edi
		for (i = 0; i < 5; i++) {
			uint32_t argi = args[i];
			cprintf(" %08x ", argi);
f01007bf:	8b 03                	mov    (%ebx),%eax
f01007c1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c5:	c7 04 24 41 1d 10 f0 	movl   $0xf0101d41,(%esp)
f01007cc:	e8 2b 02 00 00       	call   f01009fc <cprintf>
f01007d1:	83 c3 04             	add    $0x4,%ebx

	while (ebp) {
		eip = *(ebp + 1);
		cprintf("ebp %x eip %x args", ebp, eip);
		uint32_t *args = ebp + 2;
		for (i = 0; i < 5; i++) {
f01007d4:	39 fb                	cmp    %edi,%ebx
f01007d6:	75 e7                	jne    f01007bf <mon_backtrace+0x30>
			uint32_t argi = args[i];
			cprintf(" %08x ", argi);
		}
		cprintf("\n");
f01007d8:	c7 04 24 8e 1a 10 f0 	movl   $0xf0101a8e,(%esp)
f01007df:	e8 18 02 00 00       	call   f01009fc <cprintf>
		struct Eipdebuginfo debug_info;
		debuginfo_eip(eip, &debug_info);
f01007e4:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007eb:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01007ee:	89 3c 24             	mov    %edi,(%esp)
f01007f1:	e8 fd 02 00 00       	call   f0100af3 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",
f01007f6:	89 f8                	mov    %edi,%eax
f01007f8:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007fb:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007ff:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100802:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100806:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100809:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010080d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100810:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100814:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100817:	89 44 24 04          	mov    %eax,0x4(%esp)
f010081b:	c7 04 24 48 1d 10 f0 	movl   $0xf0101d48,(%esp)
f0100822:	e8 d5 01 00 00       	call   f01009fc <cprintf>
			debug_info.eip_file, 
			debug_info.eip_line, 				
			debug_info.eip_fn_namelen,
			debug_info.eip_fn_name, 
			eip - debug_info.eip_fn_addr);
		ebp = (uint32_t *) *ebp;
f0100827:	8b 36                	mov    (%esi),%esi
	// Your code here.
	int i;
	uint32_t eip;
	uint32_t* ebp = (uint32_t *)read_ebp();

	while (ebp) {
f0100829:	85 f6                	test   %esi,%esi
f010082b:	0f 85 6e ff ff ff    	jne    f010079f <mon_backtrace+0x10>
			debug_info.eip_fn_name, 
			eip - debug_info.eip_fn_addr);
		ebp = (uint32_t *) *ebp;
	}
	return 0;
}
f0100831:	b8 00 00 00 00       	mov    $0x0,%eax
f0100836:	83 c4 4c             	add    $0x4c,%esp
f0100839:	5b                   	pop    %ebx
f010083a:	5e                   	pop    %esi
f010083b:	5f                   	pop    %edi
f010083c:	5d                   	pop    %ebp
f010083d:	c3                   	ret    

f010083e <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010083e:	55                   	push   %ebp
f010083f:	89 e5                	mov    %esp,%ebp
f0100841:	57                   	push   %edi
f0100842:	56                   	push   %esi
f0100843:	53                   	push   %ebx
f0100844:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;
	unsigned int i = 0x00646c72;
f0100847:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
	cprintf("Welcome to the JOS kernel monitor!\n");
f010084e:	c7 04 24 c0 1e 10 f0 	movl   $0xf0101ec0,(%esp)
f0100855:	e8 a2 01 00 00       	call   f01009fc <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010085a:	c7 04 24 e4 1e 10 f0 	movl   $0xf0101ee4,(%esp)
f0100861:	e8 96 01 00 00       	call   f01009fc <cprintf>
	cprintf("\033[0;32;40m H%x Wo%s", 57616, &i);
f0100866:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100869:	89 44 24 08          	mov    %eax,0x8(%esp)
f010086d:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f0100874:	00 
f0100875:	c7 04 24 59 1d 10 f0 	movl   $0xf0101d59,(%esp)
f010087c:	e8 7b 01 00 00       	call   f01009fc <cprintf>
	cprintf("x=%d y=%d", 3);
f0100881:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0100888:	00 
f0100889:	c7 04 24 6d 1d 10 f0 	movl   $0xf0101d6d,(%esp)
f0100890:	e8 67 01 00 00       	call   f01009fc <cprintf>
	while (1) {
		buf = readline("K> ");
f0100895:	c7 04 24 77 1d 10 f0 	movl   $0xf0101d77,(%esp)
f010089c:	e8 6f 0a 00 00       	call   f0101310 <readline>
f01008a1:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008a3:	85 c0                	test   %eax,%eax
f01008a5:	74 ee                	je     f0100895 <monitor+0x57>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008a7:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008ae:	be 00 00 00 00       	mov    $0x0,%esi
f01008b3:	eb 0a                	jmp    f01008bf <monitor+0x81>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008b5:	c6 03 00             	movb   $0x0,(%ebx)
f01008b8:	89 f7                	mov    %esi,%edi
f01008ba:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008bd:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008bf:	0f b6 03             	movzbl (%ebx),%eax
f01008c2:	84 c0                	test   %al,%al
f01008c4:	74 63                	je     f0100929 <monitor+0xeb>
f01008c6:	0f be c0             	movsbl %al,%eax
f01008c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cd:	c7 04 24 7b 1d 10 f0 	movl   $0xf0101d7b,(%esp)
f01008d4:	e8 51 0c 00 00       	call   f010152a <strchr>
f01008d9:	85 c0                	test   %eax,%eax
f01008db:	75 d8                	jne    f01008b5 <monitor+0x77>
			*buf++ = 0;
		if (*buf == 0)
f01008dd:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008e0:	74 47                	je     f0100929 <monitor+0xeb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008e2:	83 fe 0f             	cmp    $0xf,%esi
f01008e5:	75 16                	jne    f01008fd <monitor+0xbf>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008e7:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008ee:	00 
f01008ef:	c7 04 24 80 1d 10 f0 	movl   $0xf0101d80,(%esp)
f01008f6:	e8 01 01 00 00       	call   f01009fc <cprintf>
f01008fb:	eb 98                	jmp    f0100895 <monitor+0x57>
			return 0;
		}
		argv[argc++] = buf;
f01008fd:	8d 7e 01             	lea    0x1(%esi),%edi
f0100900:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f0100904:	eb 03                	jmp    f0100909 <monitor+0xcb>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100906:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100909:	0f b6 03             	movzbl (%ebx),%eax
f010090c:	84 c0                	test   %al,%al
f010090e:	74 ad                	je     f01008bd <monitor+0x7f>
f0100910:	0f be c0             	movsbl %al,%eax
f0100913:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100917:	c7 04 24 7b 1d 10 f0 	movl   $0xf0101d7b,(%esp)
f010091e:	e8 07 0c 00 00       	call   f010152a <strchr>
f0100923:	85 c0                	test   %eax,%eax
f0100925:	74 df                	je     f0100906 <monitor+0xc8>
f0100927:	eb 94                	jmp    f01008bd <monitor+0x7f>
			buf++;
	}
	argv[argc] = 0;
f0100929:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f0100930:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100931:	85 f6                	test   %esi,%esi
f0100933:	0f 84 5c ff ff ff    	je     f0100895 <monitor+0x57>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100939:	c7 44 24 04 fe 1c 10 	movl   $0xf0101cfe,0x4(%esp)
f0100940:	f0 
f0100941:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100944:	89 04 24             	mov    %eax,(%esp)
f0100947:	e8 80 0b 00 00       	call   f01014cc <strcmp>
f010094c:	85 c0                	test   %eax,%eax
f010094e:	74 1b                	je     f010096b <monitor+0x12d>
f0100950:	c7 44 24 04 0c 1d 10 	movl   $0xf0101d0c,0x4(%esp)
f0100957:	f0 
f0100958:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010095b:	89 04 24             	mov    %eax,(%esp)
f010095e:	e8 69 0b 00 00       	call   f01014cc <strcmp>
f0100963:	85 c0                	test   %eax,%eax
f0100965:	75 2f                	jne    f0100996 <monitor+0x158>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100967:	b0 01                	mov    $0x1,%al
f0100969:	eb 05                	jmp    f0100970 <monitor+0x132>
		if (strcmp(argv[0], commands[i].name) == 0)
f010096b:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100970:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100973:	01 d0                	add    %edx,%eax
f0100975:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100978:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010097c:	8d 55 a4             	lea    -0x5c(%ebp),%edx
f010097f:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100983:	89 34 24             	mov    %esi,(%esp)
f0100986:	ff 14 85 14 1f 10 f0 	call   *-0xfefe0ec(,%eax,4)
	cprintf("\033[0;32;40m H%x Wo%s", 57616, &i);
	cprintf("x=%d y=%d", 3);
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010098d:	85 c0                	test   %eax,%eax
f010098f:	78 1d                	js     f01009ae <monitor+0x170>
f0100991:	e9 ff fe ff ff       	jmp    f0100895 <monitor+0x57>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100996:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100999:	89 44 24 04          	mov    %eax,0x4(%esp)
f010099d:	c7 04 24 9d 1d 10 f0 	movl   $0xf0101d9d,(%esp)
f01009a4:	e8 53 00 00 00       	call   f01009fc <cprintf>
f01009a9:	e9 e7 fe ff ff       	jmp    f0100895 <monitor+0x57>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009ae:	83 c4 6c             	add    $0x6c,%esp
f01009b1:	5b                   	pop    %ebx
f01009b2:	5e                   	pop    %esi
f01009b3:	5f                   	pop    %edi
f01009b4:	5d                   	pop    %ebp
f01009b5:	c3                   	ret    

f01009b6 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009b6:	55                   	push   %ebp
f01009b7:	89 e5                	mov    %esp,%ebp
f01009b9:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01009bf:	89 04 24             	mov    %eax,(%esp)
f01009c2:	e8 8a fc ff ff       	call   f0100651 <cputchar>
	*cnt++;
}
f01009c7:	c9                   	leave  
f01009c8:	c3                   	ret    

f01009c9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009c9:	55                   	push   %ebp
f01009ca:	89 e5                	mov    %esp,%ebp
f01009cc:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009cf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009d6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01009e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009e4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009eb:	c7 04 24 b6 09 10 f0 	movl   $0xf01009b6,(%esp)
f01009f2:	e8 b7 04 00 00       	call   f0100eae <vprintfmt>
	return cnt;
}
f01009f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009fa:	c9                   	leave  
f01009fb:	c3                   	ret    

f01009fc <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009fc:	55                   	push   %ebp
f01009fd:	89 e5                	mov    %esp,%ebp
f01009ff:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a02:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a05:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a09:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a0c:	89 04 24             	mov    %eax,(%esp)
f0100a0f:	e8 b5 ff ff ff       	call   f01009c9 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a14:	c9                   	leave  
f0100a15:	c3                   	ret    

f0100a16 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a16:	55                   	push   %ebp
f0100a17:	89 e5                	mov    %esp,%ebp
f0100a19:	57                   	push   %edi
f0100a1a:	56                   	push   %esi
f0100a1b:	53                   	push   %ebx
f0100a1c:	83 ec 10             	sub    $0x10,%esp
f0100a1f:	89 c6                	mov    %eax,%esi
f0100a21:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a24:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a27:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a2a:	8b 1a                	mov    (%edx),%ebx
f0100a2c:	8b 01                	mov    (%ecx),%eax
f0100a2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a31:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a38:	eb 77                	jmp    f0100ab1 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a3d:	01 d8                	add    %ebx,%eax
f0100a3f:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a44:	99                   	cltd   
f0100a45:	f7 f9                	idiv   %ecx
f0100a47:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a49:	eb 01                	jmp    f0100a4c <stab_binsearch+0x36>
			m--;
f0100a4b:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a4c:	39 d9                	cmp    %ebx,%ecx
f0100a4e:	7c 1d                	jl     f0100a6d <stab_binsearch+0x57>
f0100a50:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a53:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a58:	39 fa                	cmp    %edi,%edx
f0100a5a:	75 ef                	jne    f0100a4b <stab_binsearch+0x35>
f0100a5c:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a5f:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a62:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a66:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a69:	73 18                	jae    f0100a83 <stab_binsearch+0x6d>
f0100a6b:	eb 05                	jmp    f0100a72 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a6d:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a70:	eb 3f                	jmp    f0100ab1 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a72:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a75:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a77:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a7a:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a81:	eb 2e                	jmp    f0100ab1 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a83:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a86:	73 15                	jae    f0100a9d <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a88:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a8b:	48                   	dec    %eax
f0100a8c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a8f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a92:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a94:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a9b:	eb 14                	jmp    f0100ab1 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a9d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100aa0:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100aa3:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100aa5:	ff 45 0c             	incl   0xc(%ebp)
f0100aa8:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aaa:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100ab1:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100ab4:	7e 84                	jle    f0100a3a <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ab6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100aba:	75 0d                	jne    f0100ac9 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100abc:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100abf:	8b 00                	mov    (%eax),%eax
f0100ac1:	48                   	dec    %eax
f0100ac2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ac5:	89 07                	mov    %eax,(%edi)
f0100ac7:	eb 22                	jmp    f0100aeb <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ac9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100acc:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ace:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100ad1:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad3:	eb 01                	jmp    f0100ad6 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100ad5:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad6:	39 c1                	cmp    %eax,%ecx
f0100ad8:	7d 0c                	jge    f0100ae6 <stab_binsearch+0xd0>
f0100ada:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100add:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100ae2:	39 fa                	cmp    %edi,%edx
f0100ae4:	75 ef                	jne    f0100ad5 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ae6:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100ae9:	89 07                	mov    %eax,(%edi)
	}
}
f0100aeb:	83 c4 10             	add    $0x10,%esp
f0100aee:	5b                   	pop    %ebx
f0100aef:	5e                   	pop    %esi
f0100af0:	5f                   	pop    %edi
f0100af1:	5d                   	pop    %ebp
f0100af2:	c3                   	ret    

f0100af3 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100af3:	55                   	push   %ebp
f0100af4:	89 e5                	mov    %esp,%ebp
f0100af6:	57                   	push   %edi
f0100af7:	56                   	push   %esi
f0100af8:	53                   	push   %ebx
f0100af9:	83 ec 3c             	sub    $0x3c,%esp
f0100afc:	8b 75 08             	mov    0x8(%ebp),%esi
f0100aff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b02:	c7 03 24 1f 10 f0    	movl   $0xf0101f24,(%ebx)
	info->eip_line = 0;
f0100b08:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b0f:	c7 43 08 24 1f 10 f0 	movl   $0xf0101f24,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b16:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b1d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b20:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b27:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b2d:	76 12                	jbe    f0100b41 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b2f:	b8 44 74 10 f0       	mov    $0xf0107444,%eax
f0100b34:	3d 19 5b 10 f0       	cmp    $0xf0105b19,%eax
f0100b39:	0f 86 cd 01 00 00    	jbe    f0100d0c <debuginfo_eip+0x219>
f0100b3f:	eb 1c                	jmp    f0100b5d <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b41:	c7 44 24 08 2e 1f 10 	movl   $0xf0101f2e,0x8(%esp)
f0100b48:	f0 
f0100b49:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b50:	00 
f0100b51:	c7 04 24 3b 1f 10 f0 	movl   $0xf0101f3b,(%esp)
f0100b58:	e8 9b f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b5d:	80 3d 43 74 10 f0 00 	cmpb   $0x0,0xf0107443
f0100b64:	0f 85 a9 01 00 00    	jne    f0100d13 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b6a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b71:	b8 18 5b 10 f0       	mov    $0xf0105b18,%eax
f0100b76:	2d 70 21 10 f0       	sub    $0xf0102170,%eax
f0100b7b:	c1 f8 02             	sar    $0x2,%eax
f0100b7e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b84:	83 e8 01             	sub    $0x1,%eax
f0100b87:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b8a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b8e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b95:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b98:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b9b:	b8 70 21 10 f0       	mov    $0xf0102170,%eax
f0100ba0:	e8 71 fe ff ff       	call   f0100a16 <stab_binsearch>
	if (lfile == 0)
f0100ba5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ba8:	85 c0                	test   %eax,%eax
f0100baa:	0f 84 6a 01 00 00    	je     f0100d1a <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bb0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bb6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bb9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bbd:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bc4:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bc7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bca:	b8 70 21 10 f0       	mov    $0xf0102170,%eax
f0100bcf:	e8 42 fe ff ff       	call   f0100a16 <stab_binsearch>

	if (lfun <= rfun) {
f0100bd4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bd7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bda:	39 d0                	cmp    %edx,%eax
f0100bdc:	7f 3d                	jg     f0100c1b <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bde:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100be1:	8d b9 70 21 10 f0    	lea    -0xfefde90(%ecx),%edi
f0100be7:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bea:	8b 89 70 21 10 f0    	mov    -0xfefde90(%ecx),%ecx
f0100bf0:	bf 44 74 10 f0       	mov    $0xf0107444,%edi
f0100bf5:	81 ef 19 5b 10 f0    	sub    $0xf0105b19,%edi
f0100bfb:	39 f9                	cmp    %edi,%ecx
f0100bfd:	73 09                	jae    f0100c08 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bff:	81 c1 19 5b 10 f0    	add    $0xf0105b19,%ecx
f0100c05:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c08:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c0b:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c0e:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c11:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c13:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c16:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c19:	eb 0f                	jmp    f0100c2a <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c1b:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c1e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c21:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c24:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c27:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c2a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c31:	00 
f0100c32:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c35:	89 04 24             	mov    %eax,(%esp)
f0100c38:	e8 0e 09 00 00       	call   f010154b <strfind>
f0100c3d:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c40:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c43:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c47:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c4e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c51:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c54:	b8 70 21 10 f0       	mov    $0xf0102170,%eax
f0100c59:	e8 b8 fd ff ff       	call   f0100a16 <stab_binsearch>
	if (lline <= rline) 
f0100c5e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100c61:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0100c64:	0f 8f b7 00 00 00    	jg     f0100d21 <debuginfo_eip+0x22e>
    		info->eip_line = stabs[rline].n_desc;
f0100c6a:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c6d:	0f b7 80 76 21 10 f0 	movzwl -0xfefde8a(%eax),%eax
f0100c74:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c7a:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c7d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c80:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c83:	81 c2 70 21 10 f0    	add    $0xf0102170,%edx
f0100c89:	eb 06                	jmp    f0100c91 <debuginfo_eip+0x19e>
f0100c8b:	83 e8 01             	sub    $0x1,%eax
f0100c8e:	83 ea 0c             	sub    $0xc,%edx
f0100c91:	89 c6                	mov    %eax,%esi
f0100c93:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100c96:	7f 33                	jg     f0100ccb <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0100c98:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c9c:	80 f9 84             	cmp    $0x84,%cl
f0100c9f:	74 0b                	je     f0100cac <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100ca1:	80 f9 64             	cmp    $0x64,%cl
f0100ca4:	75 e5                	jne    f0100c8b <debuginfo_eip+0x198>
f0100ca6:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100caa:	74 df                	je     f0100c8b <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cac:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100caf:	8b 86 70 21 10 f0    	mov    -0xfefde90(%esi),%eax
f0100cb5:	ba 44 74 10 f0       	mov    $0xf0107444,%edx
f0100cba:	81 ea 19 5b 10 f0    	sub    $0xf0105b19,%edx
f0100cc0:	39 d0                	cmp    %edx,%eax
f0100cc2:	73 07                	jae    f0100ccb <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cc4:	05 19 5b 10 f0       	add    $0xf0105b19,%eax
f0100cc9:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ccb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cce:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cd1:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cd6:	39 ca                	cmp    %ecx,%edx
f0100cd8:	7d 53                	jge    f0100d2d <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0100cda:	8d 42 01             	lea    0x1(%edx),%eax
f0100cdd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100ce0:	89 c2                	mov    %eax,%edx
f0100ce2:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100ce5:	05 70 21 10 f0       	add    $0xf0102170,%eax
f0100cea:	89 ce                	mov    %ecx,%esi
f0100cec:	eb 04                	jmp    f0100cf2 <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100cee:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cf2:	39 d6                	cmp    %edx,%esi
f0100cf4:	7e 32                	jle    f0100d28 <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cf6:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100cfa:	83 c2 01             	add    $0x1,%edx
f0100cfd:	83 c0 0c             	add    $0xc,%eax
f0100d00:	80 f9 a0             	cmp    $0xa0,%cl
f0100d03:	74 e9                	je     f0100cee <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d05:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d0a:	eb 21                	jmp    f0100d2d <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d0c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d11:	eb 1a                	jmp    f0100d2d <debuginfo_eip+0x23a>
f0100d13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d18:	eb 13                	jmp    f0100d2d <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d1f:	eb 0c                	jmp    f0100d2d <debuginfo_eip+0x23a>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline) 
    		info->eip_line = stabs[rline].n_desc;
	else 
    		return -1;
f0100d21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d26:	eb 05                	jmp    f0100d2d <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d28:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d2d:	83 c4 3c             	add    $0x3c,%esp
f0100d30:	5b                   	pop    %ebx
f0100d31:	5e                   	pop    %esi
f0100d32:	5f                   	pop    %edi
f0100d33:	5d                   	pop    %ebp
f0100d34:	c3                   	ret    
f0100d35:	66 90                	xchg   %ax,%ax
f0100d37:	66 90                	xchg   %ax,%ax
f0100d39:	66 90                	xchg   %ax,%ax
f0100d3b:	66 90                	xchg   %ax,%ax
f0100d3d:	66 90                	xchg   %ax,%ax
f0100d3f:	90                   	nop

f0100d40 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d40:	55                   	push   %ebp
f0100d41:	89 e5                	mov    %esp,%ebp
f0100d43:	57                   	push   %edi
f0100d44:	56                   	push   %esi
f0100d45:	53                   	push   %ebx
f0100d46:	83 ec 3c             	sub    $0x3c,%esp
f0100d49:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d4c:	89 d7                	mov    %edx,%edi
f0100d4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d51:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d54:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d57:	89 c3                	mov    %eax,%ebx
f0100d59:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d5c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d5f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d62:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d67:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d6a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d6d:	39 d9                	cmp    %ebx,%ecx
f0100d6f:	72 05                	jb     f0100d76 <printnum+0x36>
f0100d71:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d74:	77 69                	ja     f0100ddf <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d76:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d79:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d7d:	83 ee 01             	sub    $0x1,%esi
f0100d80:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d84:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d88:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d8c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d90:	89 c3                	mov    %eax,%ebx
f0100d92:	89 d6                	mov    %edx,%esi
f0100d94:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d97:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d9a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d9e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100da2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100da5:	89 04 24             	mov    %eax,(%esp)
f0100da8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dab:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100daf:	e8 bc 09 00 00       	call   f0101770 <__udivdi3>
f0100db4:	89 d9                	mov    %ebx,%ecx
f0100db6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100dba:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100dbe:	89 04 24             	mov    %eax,(%esp)
f0100dc1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100dc5:	89 fa                	mov    %edi,%edx
f0100dc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dca:	e8 71 ff ff ff       	call   f0100d40 <printnum>
f0100dcf:	eb 1b                	jmp    f0100dec <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dd1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dd5:	8b 45 18             	mov    0x18(%ebp),%eax
f0100dd8:	89 04 24             	mov    %eax,(%esp)
f0100ddb:	ff d3                	call   *%ebx
f0100ddd:	eb 03                	jmp    f0100de2 <printnum+0xa2>
f0100ddf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100de2:	83 ee 01             	sub    $0x1,%esi
f0100de5:	85 f6                	test   %esi,%esi
f0100de7:	7f e8                	jg     f0100dd1 <printnum+0x91>
f0100de9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dec:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100df0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100df4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100df7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100dfa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dfe:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e02:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e05:	89 04 24             	mov    %eax,(%esp)
f0100e08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e0b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e0f:	e8 8c 0a 00 00       	call   f01018a0 <__umoddi3>
f0100e14:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e18:	0f be 80 49 1f 10 f0 	movsbl -0xfefe0b7(%eax),%eax
f0100e1f:	89 04 24             	mov    %eax,(%esp)
f0100e22:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e25:	ff d0                	call   *%eax
}
f0100e27:	83 c4 3c             	add    $0x3c,%esp
f0100e2a:	5b                   	pop    %ebx
f0100e2b:	5e                   	pop    %esi
f0100e2c:	5f                   	pop    %edi
f0100e2d:	5d                   	pop    %ebp
f0100e2e:	c3                   	ret    

f0100e2f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e2f:	55                   	push   %ebp
f0100e30:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e32:	83 fa 01             	cmp    $0x1,%edx
f0100e35:	7e 0e                	jle    f0100e45 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e37:	8b 10                	mov    (%eax),%edx
f0100e39:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e3c:	89 08                	mov    %ecx,(%eax)
f0100e3e:	8b 02                	mov    (%edx),%eax
f0100e40:	8b 52 04             	mov    0x4(%edx),%edx
f0100e43:	eb 22                	jmp    f0100e67 <getuint+0x38>
	else if (lflag)
f0100e45:	85 d2                	test   %edx,%edx
f0100e47:	74 10                	je     f0100e59 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e49:	8b 10                	mov    (%eax),%edx
f0100e4b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e4e:	89 08                	mov    %ecx,(%eax)
f0100e50:	8b 02                	mov    (%edx),%eax
f0100e52:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e57:	eb 0e                	jmp    f0100e67 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e59:	8b 10                	mov    (%eax),%edx
f0100e5b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e5e:	89 08                	mov    %ecx,(%eax)
f0100e60:	8b 02                	mov    (%edx),%eax
f0100e62:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e67:	5d                   	pop    %ebp
f0100e68:	c3                   	ret    

f0100e69 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e69:	55                   	push   %ebp
f0100e6a:	89 e5                	mov    %esp,%ebp
f0100e6c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e6f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e73:	8b 10                	mov    (%eax),%edx
f0100e75:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e78:	73 0a                	jae    f0100e84 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e7a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e7d:	89 08                	mov    %ecx,(%eax)
f0100e7f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e82:	88 02                	mov    %al,(%edx)
}
f0100e84:	5d                   	pop    %ebp
f0100e85:	c3                   	ret    

f0100e86 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e86:	55                   	push   %ebp
f0100e87:	89 e5                	mov    %esp,%ebp
f0100e89:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e8c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e8f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e93:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e96:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e9d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ea1:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ea4:	89 04 24             	mov    %eax,(%esp)
f0100ea7:	e8 02 00 00 00       	call   f0100eae <vprintfmt>
	va_end(ap);
}
f0100eac:	c9                   	leave  
f0100ead:	c3                   	ret    

f0100eae <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100eae:	55                   	push   %ebp
f0100eaf:	89 e5                	mov    %esp,%ebp
f0100eb1:	57                   	push   %edi
f0100eb2:	56                   	push   %esi
f0100eb3:	53                   	push   %ebx
f0100eb4:	83 ec 3c             	sub    $0x3c,%esp
f0100eb7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100eba:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100ebd:	eb 14                	jmp    f0100ed3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ebf:	85 c0                	test   %eax,%eax
f0100ec1:	0f 84 b3 03 00 00    	je     f010127a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100ec7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ecb:	89 04 24             	mov    %eax,(%esp)
f0100ece:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ed1:	89 f3                	mov    %esi,%ebx
f0100ed3:	8d 73 01             	lea    0x1(%ebx),%esi
f0100ed6:	0f b6 03             	movzbl (%ebx),%eax
f0100ed9:	83 f8 25             	cmp    $0x25,%eax
f0100edc:	75 e1                	jne    f0100ebf <vprintfmt+0x11>
f0100ede:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100ee2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100ee9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100ef0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100ef7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100efc:	eb 1d                	jmp    f0100f1b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100efe:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f00:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100f04:	eb 15                	jmp    f0100f1b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f06:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f08:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100f0c:	eb 0d                	jmp    f0100f1b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f11:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f14:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f1b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100f1e:	0f b6 0e             	movzbl (%esi),%ecx
f0100f21:	0f b6 c1             	movzbl %cl,%eax
f0100f24:	83 e9 23             	sub    $0x23,%ecx
f0100f27:	80 f9 55             	cmp    $0x55,%cl
f0100f2a:	0f 87 2a 03 00 00    	ja     f010125a <vprintfmt+0x3ac>
f0100f30:	0f b6 c9             	movzbl %cl,%ecx
f0100f33:	ff 24 8d e0 1f 10 f0 	jmp    *-0xfefe020(,%ecx,4)
f0100f3a:	89 de                	mov    %ebx,%esi
f0100f3c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f41:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f44:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f48:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f4b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f4e:	83 fb 09             	cmp    $0x9,%ebx
f0100f51:	77 36                	ja     f0100f89 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f53:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f56:	eb e9                	jmp    f0100f41 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f58:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f5b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f5e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f61:	8b 00                	mov    (%eax),%eax
f0100f63:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f66:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f68:	eb 22                	jmp    f0100f8c <vprintfmt+0xde>
f0100f6a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f6d:	85 c9                	test   %ecx,%ecx
f0100f6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f74:	0f 49 c1             	cmovns %ecx,%eax
f0100f77:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f7a:	89 de                	mov    %ebx,%esi
f0100f7c:	eb 9d                	jmp    f0100f1b <vprintfmt+0x6d>
f0100f7e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f80:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100f87:	eb 92                	jmp    f0100f1b <vprintfmt+0x6d>
f0100f89:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100f8c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f90:	79 89                	jns    f0100f1b <vprintfmt+0x6d>
f0100f92:	e9 77 ff ff ff       	jmp    f0100f0e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f97:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f9a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f9c:	e9 7a ff ff ff       	jmp    f0100f1b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fa1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa4:	8d 50 04             	lea    0x4(%eax),%edx
f0100fa7:	89 55 14             	mov    %edx,0x14(%ebp)
f0100faa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fae:	8b 00                	mov    (%eax),%eax
f0100fb0:	89 04 24             	mov    %eax,(%esp)
f0100fb3:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100fb6:	e9 18 ff ff ff       	jmp    f0100ed3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fbb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fbe:	8d 50 04             	lea    0x4(%eax),%edx
f0100fc1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fc4:	8b 00                	mov    (%eax),%eax
f0100fc6:	99                   	cltd   
f0100fc7:	31 d0                	xor    %edx,%eax
f0100fc9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fcb:	83 f8 07             	cmp    $0x7,%eax
f0100fce:	7f 0b                	jg     f0100fdb <vprintfmt+0x12d>
f0100fd0:	8b 14 85 40 21 10 f0 	mov    -0xfefdec0(,%eax,4),%edx
f0100fd7:	85 d2                	test   %edx,%edx
f0100fd9:	75 20                	jne    f0100ffb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100fdb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fdf:	c7 44 24 08 61 1f 10 	movl   $0xf0101f61,0x8(%esp)
f0100fe6:	f0 
f0100fe7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100feb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fee:	89 04 24             	mov    %eax,(%esp)
f0100ff1:	e8 90 fe ff ff       	call   f0100e86 <printfmt>
f0100ff6:	e9 d8 fe ff ff       	jmp    f0100ed3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100ffb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fff:	c7 44 24 08 6a 1d 10 	movl   $0xf0101d6a,0x8(%esp)
f0101006:	f0 
f0101007:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010100b:	8b 45 08             	mov    0x8(%ebp),%eax
f010100e:	89 04 24             	mov    %eax,(%esp)
f0101011:	e8 70 fe ff ff       	call   f0100e86 <printfmt>
f0101016:	e9 b8 fe ff ff       	jmp    f0100ed3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010101b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010101e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101021:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101024:	8b 45 14             	mov    0x14(%ebp),%eax
f0101027:	8d 50 04             	lea    0x4(%eax),%edx
f010102a:	89 55 14             	mov    %edx,0x14(%ebp)
f010102d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010102f:	85 f6                	test   %esi,%esi
f0101031:	b8 5a 1f 10 f0       	mov    $0xf0101f5a,%eax
f0101036:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0101039:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010103d:	0f 84 97 00 00 00    	je     f01010da <vprintfmt+0x22c>
f0101043:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101047:	0f 8e 9b 00 00 00    	jle    f01010e8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010104d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101051:	89 34 24             	mov    %esi,(%esp)
f0101054:	e8 9f 03 00 00       	call   f01013f8 <strnlen>
f0101059:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010105c:	29 c2                	sub    %eax,%edx
f010105e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0101061:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101065:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101068:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010106b:	8b 75 08             	mov    0x8(%ebp),%esi
f010106e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101071:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101073:	eb 0f                	jmp    f0101084 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0101075:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101079:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010107c:	89 04 24             	mov    %eax,(%esp)
f010107f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101081:	83 eb 01             	sub    $0x1,%ebx
f0101084:	85 db                	test   %ebx,%ebx
f0101086:	7f ed                	jg     f0101075 <vprintfmt+0x1c7>
f0101088:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010108b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010108e:	85 d2                	test   %edx,%edx
f0101090:	b8 00 00 00 00       	mov    $0x0,%eax
f0101095:	0f 49 c2             	cmovns %edx,%eax
f0101098:	29 c2                	sub    %eax,%edx
f010109a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010109d:	89 d7                	mov    %edx,%edi
f010109f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010a2:	eb 50                	jmp    f01010f4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010a4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01010a8:	74 1e                	je     f01010c8 <vprintfmt+0x21a>
f01010aa:	0f be d2             	movsbl %dl,%edx
f01010ad:	83 ea 20             	sub    $0x20,%edx
f01010b0:	83 fa 5e             	cmp    $0x5e,%edx
f01010b3:	76 13                	jbe    f01010c8 <vprintfmt+0x21a>
					putch('?', putdat);
f01010b5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010bc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010c3:	ff 55 08             	call   *0x8(%ebp)
f01010c6:	eb 0d                	jmp    f01010d5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01010c8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010cb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010cf:	89 04 24             	mov    %eax,(%esp)
f01010d2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010d5:	83 ef 01             	sub    $0x1,%edi
f01010d8:	eb 1a                	jmp    f01010f4 <vprintfmt+0x246>
f01010da:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010dd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010e0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010e6:	eb 0c                	jmp    f01010f4 <vprintfmt+0x246>
f01010e8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010eb:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010ee:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010f4:	83 c6 01             	add    $0x1,%esi
f01010f7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010fb:	0f be c2             	movsbl %dl,%eax
f01010fe:	85 c0                	test   %eax,%eax
f0101100:	74 27                	je     f0101129 <vprintfmt+0x27b>
f0101102:	85 db                	test   %ebx,%ebx
f0101104:	78 9e                	js     f01010a4 <vprintfmt+0x1f6>
f0101106:	83 eb 01             	sub    $0x1,%ebx
f0101109:	79 99                	jns    f01010a4 <vprintfmt+0x1f6>
f010110b:	89 f8                	mov    %edi,%eax
f010110d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101110:	8b 75 08             	mov    0x8(%ebp),%esi
f0101113:	89 c3                	mov    %eax,%ebx
f0101115:	eb 1a                	jmp    f0101131 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101117:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010111b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101122:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101124:	83 eb 01             	sub    $0x1,%ebx
f0101127:	eb 08                	jmp    f0101131 <vprintfmt+0x283>
f0101129:	89 fb                	mov    %edi,%ebx
f010112b:	8b 75 08             	mov    0x8(%ebp),%esi
f010112e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101131:	85 db                	test   %ebx,%ebx
f0101133:	7f e2                	jg     f0101117 <vprintfmt+0x269>
f0101135:	89 75 08             	mov    %esi,0x8(%ebp)
f0101138:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010113b:	e9 93 fd ff ff       	jmp    f0100ed3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101140:	83 fa 01             	cmp    $0x1,%edx
f0101143:	7e 16                	jle    f010115b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101145:	8b 45 14             	mov    0x14(%ebp),%eax
f0101148:	8d 50 08             	lea    0x8(%eax),%edx
f010114b:	89 55 14             	mov    %edx,0x14(%ebp)
f010114e:	8b 50 04             	mov    0x4(%eax),%edx
f0101151:	8b 00                	mov    (%eax),%eax
f0101153:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101156:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101159:	eb 32                	jmp    f010118d <vprintfmt+0x2df>
	else if (lflag)
f010115b:	85 d2                	test   %edx,%edx
f010115d:	74 18                	je     f0101177 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010115f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101162:	8d 50 04             	lea    0x4(%eax),%edx
f0101165:	89 55 14             	mov    %edx,0x14(%ebp)
f0101168:	8b 30                	mov    (%eax),%esi
f010116a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010116d:	89 f0                	mov    %esi,%eax
f010116f:	c1 f8 1f             	sar    $0x1f,%eax
f0101172:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101175:	eb 16                	jmp    f010118d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0101177:	8b 45 14             	mov    0x14(%ebp),%eax
f010117a:	8d 50 04             	lea    0x4(%eax),%edx
f010117d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101180:	8b 30                	mov    (%eax),%esi
f0101182:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101185:	89 f0                	mov    %esi,%eax
f0101187:	c1 f8 1f             	sar    $0x1f,%eax
f010118a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010118d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101190:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101193:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101198:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010119c:	0f 89 80 00 00 00    	jns    f0101222 <vprintfmt+0x374>
				putch('-', putdat);
f01011a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011a6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01011ad:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011b0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011b3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01011b6:	f7 d8                	neg    %eax
f01011b8:	83 d2 00             	adc    $0x0,%edx
f01011bb:	f7 da                	neg    %edx
			}
			base = 10;
f01011bd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011c2:	eb 5e                	jmp    f0101222 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011c4:	8d 45 14             	lea    0x14(%ebp),%eax
f01011c7:	e8 63 fc ff ff       	call   f0100e2f <getuint>
			base = 10;
f01011cc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011d1:	eb 4f                	jmp    f0101222 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint (&ap, lflag);
f01011d3:	8d 45 14             	lea    0x14(%ebp),%eax
f01011d6:	e8 54 fc ff ff       	call   f0100e2f <getuint>
			base = 8;
f01011db:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011e0:	eb 40                	jmp    f0101222 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f01011e2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011e6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011ed:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011f0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011f4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011fb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101201:	8d 50 04             	lea    0x4(%eax),%edx
f0101204:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101207:	8b 00                	mov    (%eax),%eax
f0101209:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010120e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101213:	eb 0d                	jmp    f0101222 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101215:	8d 45 14             	lea    0x14(%ebp),%eax
f0101218:	e8 12 fc ff ff       	call   f0100e2f <getuint>
			base = 16;
f010121d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101222:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0101226:	89 74 24 10          	mov    %esi,0x10(%esp)
f010122a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010122d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101231:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101235:	89 04 24             	mov    %eax,(%esp)
f0101238:	89 54 24 04          	mov    %edx,0x4(%esp)
f010123c:	89 fa                	mov    %edi,%edx
f010123e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101241:	e8 fa fa ff ff       	call   f0100d40 <printnum>
			break;
f0101246:	e9 88 fc ff ff       	jmp    f0100ed3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010124b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010124f:	89 04 24             	mov    %eax,(%esp)
f0101252:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101255:	e9 79 fc ff ff       	jmp    f0100ed3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010125a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010125e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101265:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101268:	89 f3                	mov    %esi,%ebx
f010126a:	eb 03                	jmp    f010126f <vprintfmt+0x3c1>
f010126c:	83 eb 01             	sub    $0x1,%ebx
f010126f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101273:	75 f7                	jne    f010126c <vprintfmt+0x3be>
f0101275:	e9 59 fc ff ff       	jmp    f0100ed3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010127a:	83 c4 3c             	add    $0x3c,%esp
f010127d:	5b                   	pop    %ebx
f010127e:	5e                   	pop    %esi
f010127f:	5f                   	pop    %edi
f0101280:	5d                   	pop    %ebp
f0101281:	c3                   	ret    

f0101282 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101282:	55                   	push   %ebp
f0101283:	89 e5                	mov    %esp,%ebp
f0101285:	83 ec 28             	sub    $0x28,%esp
f0101288:	8b 45 08             	mov    0x8(%ebp),%eax
f010128b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010128e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101291:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101295:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101298:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010129f:	85 c0                	test   %eax,%eax
f01012a1:	74 30                	je     f01012d3 <vsnprintf+0x51>
f01012a3:	85 d2                	test   %edx,%edx
f01012a5:	7e 2c                	jle    f01012d3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01012aa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012ae:	8b 45 10             	mov    0x10(%ebp),%eax
f01012b1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012b5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012bc:	c7 04 24 69 0e 10 f0 	movl   $0xf0100e69,(%esp)
f01012c3:	e8 e6 fb ff ff       	call   f0100eae <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012cb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012d1:	eb 05                	jmp    f01012d8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012d3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012d8:	c9                   	leave  
f01012d9:	c3                   	ret    

f01012da <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012da:	55                   	push   %ebp
f01012db:	89 e5                	mov    %esp,%ebp
f01012dd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012e0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012e3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012e7:	8b 45 10             	mov    0x10(%ebp),%eax
f01012ea:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012ee:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01012f8:	89 04 24             	mov    %eax,(%esp)
f01012fb:	e8 82 ff ff ff       	call   f0101282 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101300:	c9                   	leave  
f0101301:	c3                   	ret    
f0101302:	66 90                	xchg   %ax,%ax
f0101304:	66 90                	xchg   %ax,%ax
f0101306:	66 90                	xchg   %ax,%ax
f0101308:	66 90                	xchg   %ax,%ax
f010130a:	66 90                	xchg   %ax,%ax
f010130c:	66 90                	xchg   %ax,%ax
f010130e:	66 90                	xchg   %ax,%ax

f0101310 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101310:	55                   	push   %ebp
f0101311:	89 e5                	mov    %esp,%ebp
f0101313:	57                   	push   %edi
f0101314:	56                   	push   %esi
f0101315:	53                   	push   %ebx
f0101316:	83 ec 1c             	sub    $0x1c,%esp
f0101319:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010131c:	85 c0                	test   %eax,%eax
f010131e:	74 10                	je     f0101330 <readline+0x20>
		cprintf("%s", prompt);
f0101320:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101324:	c7 04 24 6a 1d 10 f0 	movl   $0xf0101d6a,(%esp)
f010132b:	e8 cc f6 ff ff       	call   f01009fc <cprintf>

	i = 0;
	echoing = iscons(0);
f0101330:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101337:	e8 36 f3 ff ff       	call   f0100672 <iscons>
f010133c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010133e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101343:	e8 19 f3 ff ff       	call   f0100661 <getchar>
f0101348:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010134a:	85 c0                	test   %eax,%eax
f010134c:	79 17                	jns    f0101365 <readline+0x55>
			cprintf("read error: %e\n", c);
f010134e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101352:	c7 04 24 60 21 10 f0 	movl   $0xf0102160,(%esp)
f0101359:	e8 9e f6 ff ff       	call   f01009fc <cprintf>
			return NULL;
f010135e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101363:	eb 6d                	jmp    f01013d2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101365:	83 f8 7f             	cmp    $0x7f,%eax
f0101368:	74 05                	je     f010136f <readline+0x5f>
f010136a:	83 f8 08             	cmp    $0x8,%eax
f010136d:	75 19                	jne    f0101388 <readline+0x78>
f010136f:	85 f6                	test   %esi,%esi
f0101371:	7e 15                	jle    f0101388 <readline+0x78>
			if (echoing)
f0101373:	85 ff                	test   %edi,%edi
f0101375:	74 0c                	je     f0101383 <readline+0x73>
				cputchar('\b');
f0101377:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010137e:	e8 ce f2 ff ff       	call   f0100651 <cputchar>
			i--;
f0101383:	83 ee 01             	sub    $0x1,%esi
f0101386:	eb bb                	jmp    f0101343 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101388:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010138e:	7f 1c                	jg     f01013ac <readline+0x9c>
f0101390:	83 fb 1f             	cmp    $0x1f,%ebx
f0101393:	7e 17                	jle    f01013ac <readline+0x9c>
			if (echoing)
f0101395:	85 ff                	test   %edi,%edi
f0101397:	74 08                	je     f01013a1 <readline+0x91>
				cputchar(c);
f0101399:	89 1c 24             	mov    %ebx,(%esp)
f010139c:	e8 b0 f2 ff ff       	call   f0100651 <cputchar>
			buf[i++] = c;
f01013a1:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01013a7:	8d 76 01             	lea    0x1(%esi),%esi
f01013aa:	eb 97                	jmp    f0101343 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01013ac:	83 fb 0d             	cmp    $0xd,%ebx
f01013af:	74 05                	je     f01013b6 <readline+0xa6>
f01013b1:	83 fb 0a             	cmp    $0xa,%ebx
f01013b4:	75 8d                	jne    f0101343 <readline+0x33>
			if (echoing)
f01013b6:	85 ff                	test   %edi,%edi
f01013b8:	74 0c                	je     f01013c6 <readline+0xb6>
				cputchar('\n');
f01013ba:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013c1:	e8 8b f2 ff ff       	call   f0100651 <cputchar>
			buf[i] = 0;
f01013c6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01013cd:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01013d2:	83 c4 1c             	add    $0x1c,%esp
f01013d5:	5b                   	pop    %ebx
f01013d6:	5e                   	pop    %esi
f01013d7:	5f                   	pop    %edi
f01013d8:	5d                   	pop    %ebp
f01013d9:	c3                   	ret    
f01013da:	66 90                	xchg   %ax,%ax
f01013dc:	66 90                	xchg   %ax,%ax
f01013de:	66 90                	xchg   %ax,%ax

f01013e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013e0:	55                   	push   %ebp
f01013e1:	89 e5                	mov    %esp,%ebp
f01013e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013eb:	eb 03                	jmp    f01013f0 <strlen+0x10>
		n++;
f01013ed:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013f0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013f4:	75 f7                	jne    f01013ed <strlen+0xd>
		n++;
	return n;
}
f01013f6:	5d                   	pop    %ebp
f01013f7:	c3                   	ret    

f01013f8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013f8:	55                   	push   %ebp
f01013f9:	89 e5                	mov    %esp,%ebp
f01013fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013fe:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101401:	b8 00 00 00 00       	mov    $0x0,%eax
f0101406:	eb 03                	jmp    f010140b <strnlen+0x13>
		n++;
f0101408:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010140b:	39 d0                	cmp    %edx,%eax
f010140d:	74 06                	je     f0101415 <strnlen+0x1d>
f010140f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101413:	75 f3                	jne    f0101408 <strnlen+0x10>
		n++;
	return n;
}
f0101415:	5d                   	pop    %ebp
f0101416:	c3                   	ret    

f0101417 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101417:	55                   	push   %ebp
f0101418:	89 e5                	mov    %esp,%ebp
f010141a:	53                   	push   %ebx
f010141b:	8b 45 08             	mov    0x8(%ebp),%eax
f010141e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101421:	89 c2                	mov    %eax,%edx
f0101423:	83 c2 01             	add    $0x1,%edx
f0101426:	83 c1 01             	add    $0x1,%ecx
f0101429:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010142d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101430:	84 db                	test   %bl,%bl
f0101432:	75 ef                	jne    f0101423 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101434:	5b                   	pop    %ebx
f0101435:	5d                   	pop    %ebp
f0101436:	c3                   	ret    

f0101437 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101437:	55                   	push   %ebp
f0101438:	89 e5                	mov    %esp,%ebp
f010143a:	53                   	push   %ebx
f010143b:	83 ec 08             	sub    $0x8,%esp
f010143e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101441:	89 1c 24             	mov    %ebx,(%esp)
f0101444:	e8 97 ff ff ff       	call   f01013e0 <strlen>
	strcpy(dst + len, src);
f0101449:	8b 55 0c             	mov    0xc(%ebp),%edx
f010144c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101450:	01 d8                	add    %ebx,%eax
f0101452:	89 04 24             	mov    %eax,(%esp)
f0101455:	e8 bd ff ff ff       	call   f0101417 <strcpy>
	return dst;
}
f010145a:	89 d8                	mov    %ebx,%eax
f010145c:	83 c4 08             	add    $0x8,%esp
f010145f:	5b                   	pop    %ebx
f0101460:	5d                   	pop    %ebp
f0101461:	c3                   	ret    

f0101462 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101462:	55                   	push   %ebp
f0101463:	89 e5                	mov    %esp,%ebp
f0101465:	56                   	push   %esi
f0101466:	53                   	push   %ebx
f0101467:	8b 75 08             	mov    0x8(%ebp),%esi
f010146a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010146d:	89 f3                	mov    %esi,%ebx
f010146f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101472:	89 f2                	mov    %esi,%edx
f0101474:	eb 0f                	jmp    f0101485 <strncpy+0x23>
		*dst++ = *src;
f0101476:	83 c2 01             	add    $0x1,%edx
f0101479:	0f b6 01             	movzbl (%ecx),%eax
f010147c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010147f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101482:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101485:	39 da                	cmp    %ebx,%edx
f0101487:	75 ed                	jne    f0101476 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101489:	89 f0                	mov    %esi,%eax
f010148b:	5b                   	pop    %ebx
f010148c:	5e                   	pop    %esi
f010148d:	5d                   	pop    %ebp
f010148e:	c3                   	ret    

f010148f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010148f:	55                   	push   %ebp
f0101490:	89 e5                	mov    %esp,%ebp
f0101492:	56                   	push   %esi
f0101493:	53                   	push   %ebx
f0101494:	8b 75 08             	mov    0x8(%ebp),%esi
f0101497:	8b 55 0c             	mov    0xc(%ebp),%edx
f010149a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010149d:	89 f0                	mov    %esi,%eax
f010149f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014a3:	85 c9                	test   %ecx,%ecx
f01014a5:	75 0b                	jne    f01014b2 <strlcpy+0x23>
f01014a7:	eb 1d                	jmp    f01014c6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01014a9:	83 c0 01             	add    $0x1,%eax
f01014ac:	83 c2 01             	add    $0x1,%edx
f01014af:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014b2:	39 d8                	cmp    %ebx,%eax
f01014b4:	74 0b                	je     f01014c1 <strlcpy+0x32>
f01014b6:	0f b6 0a             	movzbl (%edx),%ecx
f01014b9:	84 c9                	test   %cl,%cl
f01014bb:	75 ec                	jne    f01014a9 <strlcpy+0x1a>
f01014bd:	89 c2                	mov    %eax,%edx
f01014bf:	eb 02                	jmp    f01014c3 <strlcpy+0x34>
f01014c1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01014c3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01014c6:	29 f0                	sub    %esi,%eax
}
f01014c8:	5b                   	pop    %ebx
f01014c9:	5e                   	pop    %esi
f01014ca:	5d                   	pop    %ebp
f01014cb:	c3                   	ret    

f01014cc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014cc:	55                   	push   %ebp
f01014cd:	89 e5                	mov    %esp,%ebp
f01014cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014d5:	eb 06                	jmp    f01014dd <strcmp+0x11>
		p++, q++;
f01014d7:	83 c1 01             	add    $0x1,%ecx
f01014da:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014dd:	0f b6 01             	movzbl (%ecx),%eax
f01014e0:	84 c0                	test   %al,%al
f01014e2:	74 04                	je     f01014e8 <strcmp+0x1c>
f01014e4:	3a 02                	cmp    (%edx),%al
f01014e6:	74 ef                	je     f01014d7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014e8:	0f b6 c0             	movzbl %al,%eax
f01014eb:	0f b6 12             	movzbl (%edx),%edx
f01014ee:	29 d0                	sub    %edx,%eax
}
f01014f0:	5d                   	pop    %ebp
f01014f1:	c3                   	ret    

f01014f2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014f2:	55                   	push   %ebp
f01014f3:	89 e5                	mov    %esp,%ebp
f01014f5:	53                   	push   %ebx
f01014f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014fc:	89 c3                	mov    %eax,%ebx
f01014fe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101501:	eb 06                	jmp    f0101509 <strncmp+0x17>
		n--, p++, q++;
f0101503:	83 c0 01             	add    $0x1,%eax
f0101506:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101509:	39 d8                	cmp    %ebx,%eax
f010150b:	74 15                	je     f0101522 <strncmp+0x30>
f010150d:	0f b6 08             	movzbl (%eax),%ecx
f0101510:	84 c9                	test   %cl,%cl
f0101512:	74 04                	je     f0101518 <strncmp+0x26>
f0101514:	3a 0a                	cmp    (%edx),%cl
f0101516:	74 eb                	je     f0101503 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101518:	0f b6 00             	movzbl (%eax),%eax
f010151b:	0f b6 12             	movzbl (%edx),%edx
f010151e:	29 d0                	sub    %edx,%eax
f0101520:	eb 05                	jmp    f0101527 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101522:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101527:	5b                   	pop    %ebx
f0101528:	5d                   	pop    %ebp
f0101529:	c3                   	ret    

f010152a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010152a:	55                   	push   %ebp
f010152b:	89 e5                	mov    %esp,%ebp
f010152d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101530:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101534:	eb 07                	jmp    f010153d <strchr+0x13>
		if (*s == c)
f0101536:	38 ca                	cmp    %cl,%dl
f0101538:	74 0f                	je     f0101549 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010153a:	83 c0 01             	add    $0x1,%eax
f010153d:	0f b6 10             	movzbl (%eax),%edx
f0101540:	84 d2                	test   %dl,%dl
f0101542:	75 f2                	jne    f0101536 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101544:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101549:	5d                   	pop    %ebp
f010154a:	c3                   	ret    

f010154b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010154b:	55                   	push   %ebp
f010154c:	89 e5                	mov    %esp,%ebp
f010154e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101551:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101555:	eb 07                	jmp    f010155e <strfind+0x13>
		if (*s == c)
f0101557:	38 ca                	cmp    %cl,%dl
f0101559:	74 0a                	je     f0101565 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010155b:	83 c0 01             	add    $0x1,%eax
f010155e:	0f b6 10             	movzbl (%eax),%edx
f0101561:	84 d2                	test   %dl,%dl
f0101563:	75 f2                	jne    f0101557 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101565:	5d                   	pop    %ebp
f0101566:	c3                   	ret    

f0101567 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101567:	55                   	push   %ebp
f0101568:	89 e5                	mov    %esp,%ebp
f010156a:	57                   	push   %edi
f010156b:	56                   	push   %esi
f010156c:	53                   	push   %ebx
f010156d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101570:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101573:	85 c9                	test   %ecx,%ecx
f0101575:	74 36                	je     f01015ad <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101577:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010157d:	75 28                	jne    f01015a7 <memset+0x40>
f010157f:	f6 c1 03             	test   $0x3,%cl
f0101582:	75 23                	jne    f01015a7 <memset+0x40>
		c &= 0xFF;
f0101584:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101588:	89 d3                	mov    %edx,%ebx
f010158a:	c1 e3 08             	shl    $0x8,%ebx
f010158d:	89 d6                	mov    %edx,%esi
f010158f:	c1 e6 18             	shl    $0x18,%esi
f0101592:	89 d0                	mov    %edx,%eax
f0101594:	c1 e0 10             	shl    $0x10,%eax
f0101597:	09 f0                	or     %esi,%eax
f0101599:	09 c2                	or     %eax,%edx
f010159b:	89 d0                	mov    %edx,%eax
f010159d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010159f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015a2:	fc                   	cld    
f01015a3:	f3 ab                	rep stos %eax,%es:(%edi)
f01015a5:	eb 06                	jmp    f01015ad <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015aa:	fc                   	cld    
f01015ab:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015ad:	89 f8                	mov    %edi,%eax
f01015af:	5b                   	pop    %ebx
f01015b0:	5e                   	pop    %esi
f01015b1:	5f                   	pop    %edi
f01015b2:	5d                   	pop    %ebp
f01015b3:	c3                   	ret    

f01015b4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015b4:	55                   	push   %ebp
f01015b5:	89 e5                	mov    %esp,%ebp
f01015b7:	57                   	push   %edi
f01015b8:	56                   	push   %esi
f01015b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015bc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015bf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015c2:	39 c6                	cmp    %eax,%esi
f01015c4:	73 35                	jae    f01015fb <memmove+0x47>
f01015c6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015c9:	39 d0                	cmp    %edx,%eax
f01015cb:	73 2e                	jae    f01015fb <memmove+0x47>
		s += n;
		d += n;
f01015cd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01015d0:	89 d6                	mov    %edx,%esi
f01015d2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015d4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015da:	75 13                	jne    f01015ef <memmove+0x3b>
f01015dc:	f6 c1 03             	test   $0x3,%cl
f01015df:	75 0e                	jne    f01015ef <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015e1:	83 ef 04             	sub    $0x4,%edi
f01015e4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015e7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01015ea:	fd                   	std    
f01015eb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015ed:	eb 09                	jmp    f01015f8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015ef:	83 ef 01             	sub    $0x1,%edi
f01015f2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015f5:	fd                   	std    
f01015f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015f8:	fc                   	cld    
f01015f9:	eb 1d                	jmp    f0101618 <memmove+0x64>
f01015fb:	89 f2                	mov    %esi,%edx
f01015fd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015ff:	f6 c2 03             	test   $0x3,%dl
f0101602:	75 0f                	jne    f0101613 <memmove+0x5f>
f0101604:	f6 c1 03             	test   $0x3,%cl
f0101607:	75 0a                	jne    f0101613 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101609:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010160c:	89 c7                	mov    %eax,%edi
f010160e:	fc                   	cld    
f010160f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101611:	eb 05                	jmp    f0101618 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101613:	89 c7                	mov    %eax,%edi
f0101615:	fc                   	cld    
f0101616:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101618:	5e                   	pop    %esi
f0101619:	5f                   	pop    %edi
f010161a:	5d                   	pop    %ebp
f010161b:	c3                   	ret    

f010161c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010161c:	55                   	push   %ebp
f010161d:	89 e5                	mov    %esp,%ebp
f010161f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101622:	8b 45 10             	mov    0x10(%ebp),%eax
f0101625:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101629:	8b 45 0c             	mov    0xc(%ebp),%eax
f010162c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101630:	8b 45 08             	mov    0x8(%ebp),%eax
f0101633:	89 04 24             	mov    %eax,(%esp)
f0101636:	e8 79 ff ff ff       	call   f01015b4 <memmove>
}
f010163b:	c9                   	leave  
f010163c:	c3                   	ret    

f010163d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010163d:	55                   	push   %ebp
f010163e:	89 e5                	mov    %esp,%ebp
f0101640:	56                   	push   %esi
f0101641:	53                   	push   %ebx
f0101642:	8b 55 08             	mov    0x8(%ebp),%edx
f0101645:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101648:	89 d6                	mov    %edx,%esi
f010164a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010164d:	eb 1a                	jmp    f0101669 <memcmp+0x2c>
		if (*s1 != *s2)
f010164f:	0f b6 02             	movzbl (%edx),%eax
f0101652:	0f b6 19             	movzbl (%ecx),%ebx
f0101655:	38 d8                	cmp    %bl,%al
f0101657:	74 0a                	je     f0101663 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101659:	0f b6 c0             	movzbl %al,%eax
f010165c:	0f b6 db             	movzbl %bl,%ebx
f010165f:	29 d8                	sub    %ebx,%eax
f0101661:	eb 0f                	jmp    f0101672 <memcmp+0x35>
		s1++, s2++;
f0101663:	83 c2 01             	add    $0x1,%edx
f0101666:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101669:	39 f2                	cmp    %esi,%edx
f010166b:	75 e2                	jne    f010164f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010166d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101672:	5b                   	pop    %ebx
f0101673:	5e                   	pop    %esi
f0101674:	5d                   	pop    %ebp
f0101675:	c3                   	ret    

f0101676 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101676:	55                   	push   %ebp
f0101677:	89 e5                	mov    %esp,%ebp
f0101679:	8b 45 08             	mov    0x8(%ebp),%eax
f010167c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010167f:	89 c2                	mov    %eax,%edx
f0101681:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101684:	eb 07                	jmp    f010168d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101686:	38 08                	cmp    %cl,(%eax)
f0101688:	74 07                	je     f0101691 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010168a:	83 c0 01             	add    $0x1,%eax
f010168d:	39 d0                	cmp    %edx,%eax
f010168f:	72 f5                	jb     f0101686 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101691:	5d                   	pop    %ebp
f0101692:	c3                   	ret    

f0101693 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101693:	55                   	push   %ebp
f0101694:	89 e5                	mov    %esp,%ebp
f0101696:	57                   	push   %edi
f0101697:	56                   	push   %esi
f0101698:	53                   	push   %ebx
f0101699:	8b 55 08             	mov    0x8(%ebp),%edx
f010169c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010169f:	eb 03                	jmp    f01016a4 <strtol+0x11>
		s++;
f01016a1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016a4:	0f b6 0a             	movzbl (%edx),%ecx
f01016a7:	80 f9 09             	cmp    $0x9,%cl
f01016aa:	74 f5                	je     f01016a1 <strtol+0xe>
f01016ac:	80 f9 20             	cmp    $0x20,%cl
f01016af:	74 f0                	je     f01016a1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016b1:	80 f9 2b             	cmp    $0x2b,%cl
f01016b4:	75 0a                	jne    f01016c0 <strtol+0x2d>
		s++;
f01016b6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01016b9:	bf 00 00 00 00       	mov    $0x0,%edi
f01016be:	eb 11                	jmp    f01016d1 <strtol+0x3e>
f01016c0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016c5:	80 f9 2d             	cmp    $0x2d,%cl
f01016c8:	75 07                	jne    f01016d1 <strtol+0x3e>
		s++, neg = 1;
f01016ca:	8d 52 01             	lea    0x1(%edx),%edx
f01016cd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016d1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01016d6:	75 15                	jne    f01016ed <strtol+0x5a>
f01016d8:	80 3a 30             	cmpb   $0x30,(%edx)
f01016db:	75 10                	jne    f01016ed <strtol+0x5a>
f01016dd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016e1:	75 0a                	jne    f01016ed <strtol+0x5a>
		s += 2, base = 16;
f01016e3:	83 c2 02             	add    $0x2,%edx
f01016e6:	b8 10 00 00 00       	mov    $0x10,%eax
f01016eb:	eb 10                	jmp    f01016fd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01016ed:	85 c0                	test   %eax,%eax
f01016ef:	75 0c                	jne    f01016fd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016f1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016f3:	80 3a 30             	cmpb   $0x30,(%edx)
f01016f6:	75 05                	jne    f01016fd <strtol+0x6a>
		s++, base = 8;
f01016f8:	83 c2 01             	add    $0x1,%edx
f01016fb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01016fd:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101702:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101705:	0f b6 0a             	movzbl (%edx),%ecx
f0101708:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010170b:	89 f0                	mov    %esi,%eax
f010170d:	3c 09                	cmp    $0x9,%al
f010170f:	77 08                	ja     f0101719 <strtol+0x86>
			dig = *s - '0';
f0101711:	0f be c9             	movsbl %cl,%ecx
f0101714:	83 e9 30             	sub    $0x30,%ecx
f0101717:	eb 20                	jmp    f0101739 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101719:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010171c:	89 f0                	mov    %esi,%eax
f010171e:	3c 19                	cmp    $0x19,%al
f0101720:	77 08                	ja     f010172a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101722:	0f be c9             	movsbl %cl,%ecx
f0101725:	83 e9 57             	sub    $0x57,%ecx
f0101728:	eb 0f                	jmp    f0101739 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010172a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010172d:	89 f0                	mov    %esi,%eax
f010172f:	3c 19                	cmp    $0x19,%al
f0101731:	77 16                	ja     f0101749 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101733:	0f be c9             	movsbl %cl,%ecx
f0101736:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101739:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010173c:	7d 0f                	jge    f010174d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010173e:	83 c2 01             	add    $0x1,%edx
f0101741:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101745:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101747:	eb bc                	jmp    f0101705 <strtol+0x72>
f0101749:	89 d8                	mov    %ebx,%eax
f010174b:	eb 02                	jmp    f010174f <strtol+0xbc>
f010174d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010174f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101753:	74 05                	je     f010175a <strtol+0xc7>
		*endptr = (char *) s;
f0101755:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101758:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010175a:	f7 d8                	neg    %eax
f010175c:	85 ff                	test   %edi,%edi
f010175e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101761:	5b                   	pop    %ebx
f0101762:	5e                   	pop    %esi
f0101763:	5f                   	pop    %edi
f0101764:	5d                   	pop    %ebp
f0101765:	c3                   	ret    
f0101766:	66 90                	xchg   %ax,%ax
f0101768:	66 90                	xchg   %ax,%ax
f010176a:	66 90                	xchg   %ax,%ax
f010176c:	66 90                	xchg   %ax,%ax
f010176e:	66 90                	xchg   %ax,%ax

f0101770 <__udivdi3>:
f0101770:	55                   	push   %ebp
f0101771:	57                   	push   %edi
f0101772:	56                   	push   %esi
f0101773:	83 ec 0c             	sub    $0xc,%esp
f0101776:	8b 44 24 28          	mov    0x28(%esp),%eax
f010177a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010177e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101782:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101786:	85 c0                	test   %eax,%eax
f0101788:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010178c:	89 ea                	mov    %ebp,%edx
f010178e:	89 0c 24             	mov    %ecx,(%esp)
f0101791:	75 2d                	jne    f01017c0 <__udivdi3+0x50>
f0101793:	39 e9                	cmp    %ebp,%ecx
f0101795:	77 61                	ja     f01017f8 <__udivdi3+0x88>
f0101797:	85 c9                	test   %ecx,%ecx
f0101799:	89 ce                	mov    %ecx,%esi
f010179b:	75 0b                	jne    f01017a8 <__udivdi3+0x38>
f010179d:	b8 01 00 00 00       	mov    $0x1,%eax
f01017a2:	31 d2                	xor    %edx,%edx
f01017a4:	f7 f1                	div    %ecx
f01017a6:	89 c6                	mov    %eax,%esi
f01017a8:	31 d2                	xor    %edx,%edx
f01017aa:	89 e8                	mov    %ebp,%eax
f01017ac:	f7 f6                	div    %esi
f01017ae:	89 c5                	mov    %eax,%ebp
f01017b0:	89 f8                	mov    %edi,%eax
f01017b2:	f7 f6                	div    %esi
f01017b4:	89 ea                	mov    %ebp,%edx
f01017b6:	83 c4 0c             	add    $0xc,%esp
f01017b9:	5e                   	pop    %esi
f01017ba:	5f                   	pop    %edi
f01017bb:	5d                   	pop    %ebp
f01017bc:	c3                   	ret    
f01017bd:	8d 76 00             	lea    0x0(%esi),%esi
f01017c0:	39 e8                	cmp    %ebp,%eax
f01017c2:	77 24                	ja     f01017e8 <__udivdi3+0x78>
f01017c4:	0f bd e8             	bsr    %eax,%ebp
f01017c7:	83 f5 1f             	xor    $0x1f,%ebp
f01017ca:	75 3c                	jne    f0101808 <__udivdi3+0x98>
f01017cc:	8b 74 24 04          	mov    0x4(%esp),%esi
f01017d0:	39 34 24             	cmp    %esi,(%esp)
f01017d3:	0f 86 9f 00 00 00    	jbe    f0101878 <__udivdi3+0x108>
f01017d9:	39 d0                	cmp    %edx,%eax
f01017db:	0f 82 97 00 00 00    	jb     f0101878 <__udivdi3+0x108>
f01017e1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017e8:	31 d2                	xor    %edx,%edx
f01017ea:	31 c0                	xor    %eax,%eax
f01017ec:	83 c4 0c             	add    $0xc,%esp
f01017ef:	5e                   	pop    %esi
f01017f0:	5f                   	pop    %edi
f01017f1:	5d                   	pop    %ebp
f01017f2:	c3                   	ret    
f01017f3:	90                   	nop
f01017f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017f8:	89 f8                	mov    %edi,%eax
f01017fa:	f7 f1                	div    %ecx
f01017fc:	31 d2                	xor    %edx,%edx
f01017fe:	83 c4 0c             	add    $0xc,%esp
f0101801:	5e                   	pop    %esi
f0101802:	5f                   	pop    %edi
f0101803:	5d                   	pop    %ebp
f0101804:	c3                   	ret    
f0101805:	8d 76 00             	lea    0x0(%esi),%esi
f0101808:	89 e9                	mov    %ebp,%ecx
f010180a:	8b 3c 24             	mov    (%esp),%edi
f010180d:	d3 e0                	shl    %cl,%eax
f010180f:	89 c6                	mov    %eax,%esi
f0101811:	b8 20 00 00 00       	mov    $0x20,%eax
f0101816:	29 e8                	sub    %ebp,%eax
f0101818:	89 c1                	mov    %eax,%ecx
f010181a:	d3 ef                	shr    %cl,%edi
f010181c:	89 e9                	mov    %ebp,%ecx
f010181e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101822:	8b 3c 24             	mov    (%esp),%edi
f0101825:	09 74 24 08          	or     %esi,0x8(%esp)
f0101829:	89 d6                	mov    %edx,%esi
f010182b:	d3 e7                	shl    %cl,%edi
f010182d:	89 c1                	mov    %eax,%ecx
f010182f:	89 3c 24             	mov    %edi,(%esp)
f0101832:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101836:	d3 ee                	shr    %cl,%esi
f0101838:	89 e9                	mov    %ebp,%ecx
f010183a:	d3 e2                	shl    %cl,%edx
f010183c:	89 c1                	mov    %eax,%ecx
f010183e:	d3 ef                	shr    %cl,%edi
f0101840:	09 d7                	or     %edx,%edi
f0101842:	89 f2                	mov    %esi,%edx
f0101844:	89 f8                	mov    %edi,%eax
f0101846:	f7 74 24 08          	divl   0x8(%esp)
f010184a:	89 d6                	mov    %edx,%esi
f010184c:	89 c7                	mov    %eax,%edi
f010184e:	f7 24 24             	mull   (%esp)
f0101851:	39 d6                	cmp    %edx,%esi
f0101853:	89 14 24             	mov    %edx,(%esp)
f0101856:	72 30                	jb     f0101888 <__udivdi3+0x118>
f0101858:	8b 54 24 04          	mov    0x4(%esp),%edx
f010185c:	89 e9                	mov    %ebp,%ecx
f010185e:	d3 e2                	shl    %cl,%edx
f0101860:	39 c2                	cmp    %eax,%edx
f0101862:	73 05                	jae    f0101869 <__udivdi3+0xf9>
f0101864:	3b 34 24             	cmp    (%esp),%esi
f0101867:	74 1f                	je     f0101888 <__udivdi3+0x118>
f0101869:	89 f8                	mov    %edi,%eax
f010186b:	31 d2                	xor    %edx,%edx
f010186d:	e9 7a ff ff ff       	jmp    f01017ec <__udivdi3+0x7c>
f0101872:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101878:	31 d2                	xor    %edx,%edx
f010187a:	b8 01 00 00 00       	mov    $0x1,%eax
f010187f:	e9 68 ff ff ff       	jmp    f01017ec <__udivdi3+0x7c>
f0101884:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101888:	8d 47 ff             	lea    -0x1(%edi),%eax
f010188b:	31 d2                	xor    %edx,%edx
f010188d:	83 c4 0c             	add    $0xc,%esp
f0101890:	5e                   	pop    %esi
f0101891:	5f                   	pop    %edi
f0101892:	5d                   	pop    %ebp
f0101893:	c3                   	ret    
f0101894:	66 90                	xchg   %ax,%ax
f0101896:	66 90                	xchg   %ax,%ax
f0101898:	66 90                	xchg   %ax,%ax
f010189a:	66 90                	xchg   %ax,%ax
f010189c:	66 90                	xchg   %ax,%ax
f010189e:	66 90                	xchg   %ax,%ax

f01018a0 <__umoddi3>:
f01018a0:	55                   	push   %ebp
f01018a1:	57                   	push   %edi
f01018a2:	56                   	push   %esi
f01018a3:	83 ec 14             	sub    $0x14,%esp
f01018a6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01018aa:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01018ae:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01018b2:	89 c7                	mov    %eax,%edi
f01018b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018b8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01018bc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01018c0:	89 34 24             	mov    %esi,(%esp)
f01018c3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018c7:	85 c0                	test   %eax,%eax
f01018c9:	89 c2                	mov    %eax,%edx
f01018cb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018cf:	75 17                	jne    f01018e8 <__umoddi3+0x48>
f01018d1:	39 fe                	cmp    %edi,%esi
f01018d3:	76 4b                	jbe    f0101920 <__umoddi3+0x80>
f01018d5:	89 c8                	mov    %ecx,%eax
f01018d7:	89 fa                	mov    %edi,%edx
f01018d9:	f7 f6                	div    %esi
f01018db:	89 d0                	mov    %edx,%eax
f01018dd:	31 d2                	xor    %edx,%edx
f01018df:	83 c4 14             	add    $0x14,%esp
f01018e2:	5e                   	pop    %esi
f01018e3:	5f                   	pop    %edi
f01018e4:	5d                   	pop    %ebp
f01018e5:	c3                   	ret    
f01018e6:	66 90                	xchg   %ax,%ax
f01018e8:	39 f8                	cmp    %edi,%eax
f01018ea:	77 54                	ja     f0101940 <__umoddi3+0xa0>
f01018ec:	0f bd e8             	bsr    %eax,%ebp
f01018ef:	83 f5 1f             	xor    $0x1f,%ebp
f01018f2:	75 5c                	jne    f0101950 <__umoddi3+0xb0>
f01018f4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01018f8:	39 3c 24             	cmp    %edi,(%esp)
f01018fb:	0f 87 e7 00 00 00    	ja     f01019e8 <__umoddi3+0x148>
f0101901:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101905:	29 f1                	sub    %esi,%ecx
f0101907:	19 c7                	sbb    %eax,%edi
f0101909:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010190d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101911:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101915:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101919:	83 c4 14             	add    $0x14,%esp
f010191c:	5e                   	pop    %esi
f010191d:	5f                   	pop    %edi
f010191e:	5d                   	pop    %ebp
f010191f:	c3                   	ret    
f0101920:	85 f6                	test   %esi,%esi
f0101922:	89 f5                	mov    %esi,%ebp
f0101924:	75 0b                	jne    f0101931 <__umoddi3+0x91>
f0101926:	b8 01 00 00 00       	mov    $0x1,%eax
f010192b:	31 d2                	xor    %edx,%edx
f010192d:	f7 f6                	div    %esi
f010192f:	89 c5                	mov    %eax,%ebp
f0101931:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101935:	31 d2                	xor    %edx,%edx
f0101937:	f7 f5                	div    %ebp
f0101939:	89 c8                	mov    %ecx,%eax
f010193b:	f7 f5                	div    %ebp
f010193d:	eb 9c                	jmp    f01018db <__umoddi3+0x3b>
f010193f:	90                   	nop
f0101940:	89 c8                	mov    %ecx,%eax
f0101942:	89 fa                	mov    %edi,%edx
f0101944:	83 c4 14             	add    $0x14,%esp
f0101947:	5e                   	pop    %esi
f0101948:	5f                   	pop    %edi
f0101949:	5d                   	pop    %ebp
f010194a:	c3                   	ret    
f010194b:	90                   	nop
f010194c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101950:	8b 04 24             	mov    (%esp),%eax
f0101953:	be 20 00 00 00       	mov    $0x20,%esi
f0101958:	89 e9                	mov    %ebp,%ecx
f010195a:	29 ee                	sub    %ebp,%esi
f010195c:	d3 e2                	shl    %cl,%edx
f010195e:	89 f1                	mov    %esi,%ecx
f0101960:	d3 e8                	shr    %cl,%eax
f0101962:	89 e9                	mov    %ebp,%ecx
f0101964:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101968:	8b 04 24             	mov    (%esp),%eax
f010196b:	09 54 24 04          	or     %edx,0x4(%esp)
f010196f:	89 fa                	mov    %edi,%edx
f0101971:	d3 e0                	shl    %cl,%eax
f0101973:	89 f1                	mov    %esi,%ecx
f0101975:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101979:	8b 44 24 10          	mov    0x10(%esp),%eax
f010197d:	d3 ea                	shr    %cl,%edx
f010197f:	89 e9                	mov    %ebp,%ecx
f0101981:	d3 e7                	shl    %cl,%edi
f0101983:	89 f1                	mov    %esi,%ecx
f0101985:	d3 e8                	shr    %cl,%eax
f0101987:	89 e9                	mov    %ebp,%ecx
f0101989:	09 f8                	or     %edi,%eax
f010198b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010198f:	f7 74 24 04          	divl   0x4(%esp)
f0101993:	d3 e7                	shl    %cl,%edi
f0101995:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101999:	89 d7                	mov    %edx,%edi
f010199b:	f7 64 24 08          	mull   0x8(%esp)
f010199f:	39 d7                	cmp    %edx,%edi
f01019a1:	89 c1                	mov    %eax,%ecx
f01019a3:	89 14 24             	mov    %edx,(%esp)
f01019a6:	72 2c                	jb     f01019d4 <__umoddi3+0x134>
f01019a8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01019ac:	72 22                	jb     f01019d0 <__umoddi3+0x130>
f01019ae:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01019b2:	29 c8                	sub    %ecx,%eax
f01019b4:	19 d7                	sbb    %edx,%edi
f01019b6:	89 e9                	mov    %ebp,%ecx
f01019b8:	89 fa                	mov    %edi,%edx
f01019ba:	d3 e8                	shr    %cl,%eax
f01019bc:	89 f1                	mov    %esi,%ecx
f01019be:	d3 e2                	shl    %cl,%edx
f01019c0:	89 e9                	mov    %ebp,%ecx
f01019c2:	d3 ef                	shr    %cl,%edi
f01019c4:	09 d0                	or     %edx,%eax
f01019c6:	89 fa                	mov    %edi,%edx
f01019c8:	83 c4 14             	add    $0x14,%esp
f01019cb:	5e                   	pop    %esi
f01019cc:	5f                   	pop    %edi
f01019cd:	5d                   	pop    %ebp
f01019ce:	c3                   	ret    
f01019cf:	90                   	nop
f01019d0:	39 d7                	cmp    %edx,%edi
f01019d2:	75 da                	jne    f01019ae <__umoddi3+0x10e>
f01019d4:	8b 14 24             	mov    (%esp),%edx
f01019d7:	89 c1                	mov    %eax,%ecx
f01019d9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01019dd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01019e1:	eb cb                	jmp    f01019ae <__umoddi3+0x10e>
f01019e3:	90                   	nop
f01019e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019e8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01019ec:	0f 82 0f ff ff ff    	jb     f0101901 <__umoddi3+0x61>
f01019f2:	e9 1a ff ff ff       	jmp    f0101911 <__umoddi3+0x71>
