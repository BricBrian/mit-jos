
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
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 70 89 11 f0       	mov    $0xf0118970,%eax
f010004b:	2d 00 83 11 f0       	sub    $0xf0118300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 83 11 f0 	movl   $0xf0118300,(%esp)
f0100063:	e8 2f 3b 00 00       	call   f0103b97 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 92 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 40 10 f0 	movl   $0xf0104040,(%esp)
f010007c:	e8 b3 2f 00 00       	call   f0103034 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 82 14 00 00       	call   f0101508 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 33 0b 00 00       	call   f0100bc5 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 89 11 f0 00 	cmpl   $0x0,0xf0118960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 89 11 f0    	mov    %esi,0xf0118960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 5b 40 10 f0 	movl   $0xf010405b,(%esp)
f01000c8:	e8 67 2f 00 00       	call   f0103034 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 28 2f 00 00       	call   f0103001 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 d4 50 10 f0 	movl   $0xf01050d4,(%esp)
f01000e0:	e8 4f 2f 00 00       	call   f0103034 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 d4 0a 00 00       	call   f0100bc5 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 73 40 10 f0 	movl   $0xf0104073,(%esp)
f0100112:	e8 1d 2f 00 00       	call   f0103034 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 db 2e 00 00       	call   f0103001 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 d4 50 10 f0 	movl   $0xf01050d4,(%esp)
f010012d:	e8 02 2f 00 00       	call   f0103034 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 85 11 f0       	mov    0xf0118524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 85 11 f0    	mov    %ecx,0xf0118524
f0100179:	88 90 20 83 11 f0    	mov    %dl,-0xfee7ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 85 11 f0 00 	movl   $0x0,0xf0118524
f010018e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 ef 00 00 00    	je     f010029d <kbd_proc_data+0xfd>
f01001ae:	b2 60                	mov    $0x60,%dl
f01001b0:	ec                   	in     (%dx),%al
f01001b1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b3:	3c e0                	cmp    $0xe0,%al
f01001b5:	75 0d                	jne    f01001c4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001b7:	83 0d 00 83 11 f0 40 	orl    $0x40,0xf0118300
		return 0;
f01001be:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001c3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c4:	55                   	push   %ebp
f01001c5:	89 e5                	mov    %esp,%ebp
f01001c7:	53                   	push   %ebx
f01001c8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001cb:	84 c0                	test   %al,%al
f01001cd:	79 37                	jns    f0100206 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cf:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f01001d5:	89 cb                	mov    %ecx,%ebx
f01001d7:	83 e3 40             	and    $0x40,%ebx
f01001da:	83 e0 7f             	and    $0x7f,%eax
f01001dd:	85 db                	test   %ebx,%ebx
f01001df:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e2:	0f b6 d2             	movzbl %dl,%edx
f01001e5:	0f b6 82 e0 41 10 f0 	movzbl -0xfefbe20(%edx),%eax
f01001ec:	83 c8 40             	or     $0x40,%eax
f01001ef:	0f b6 c0             	movzbl %al,%eax
f01001f2:	f7 d0                	not    %eax
f01001f4:	21 c1                	and    %eax,%ecx
f01001f6:	89 0d 00 83 11 f0    	mov    %ecx,0xf0118300
		return 0;
f01001fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100201:	e9 9d 00 00 00       	jmp    f01002a3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100206:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f010020c:	f6 c1 40             	test   $0x40,%cl
f010020f:	74 0e                	je     f010021f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100211:	83 c8 80             	or     $0xffffff80,%eax
f0100214:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100216:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100219:	89 0d 00 83 11 f0    	mov    %ecx,0xf0118300
	}

	shift |= shiftcode[data];
f010021f:	0f b6 d2             	movzbl %dl,%edx
f0100222:	0f b6 82 e0 41 10 f0 	movzbl -0xfefbe20(%edx),%eax
f0100229:	0b 05 00 83 11 f0    	or     0xf0118300,%eax
	shift ^= togglecode[data];
f010022f:	0f b6 8a e0 40 10 f0 	movzbl -0xfefbf20(%edx),%ecx
f0100236:	31 c8                	xor    %ecx,%eax
f0100238:	a3 00 83 11 f0       	mov    %eax,0xf0118300

	c = charcode[shift & (CTL | SHIFT)][data];
f010023d:	89 c1                	mov    %eax,%ecx
f010023f:	83 e1 03             	and    $0x3,%ecx
f0100242:	8b 0c 8d c0 40 10 f0 	mov    -0xfefbf40(,%ecx,4),%ecx
f0100249:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100250:	a8 08                	test   $0x8,%al
f0100252:	74 1b                	je     f010026f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100254:	89 da                	mov    %ebx,%edx
f0100256:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100259:	83 f9 19             	cmp    $0x19,%ecx
f010025c:	77 05                	ja     f0100263 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010025e:	83 eb 20             	sub    $0x20,%ebx
f0100261:	eb 0c                	jmp    f010026f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100263:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100266:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100269:	83 fa 19             	cmp    $0x19,%edx
f010026c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026f:	f7 d0                	not    %eax
f0100271:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100273:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100275:	f6 c2 06             	test   $0x6,%dl
f0100278:	75 29                	jne    f01002a3 <kbd_proc_data+0x103>
f010027a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100280:	75 21                	jne    f01002a3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100282:	c7 04 24 8d 40 10 f0 	movl   $0xf010408d,(%esp)
f0100289:	e8 a6 2d 00 00       	call   f0103034 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100293:	b8 03 00 00 00       	mov    $0x3,%eax
f0100298:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100299:	89 d8                	mov    %ebx,%eax
f010029b:	eb 06                	jmp    f01002a3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010029d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002a3:	83 c4 14             	add    $0x14,%esp
f01002a6:	5b                   	pop    %ebx
f01002a7:	5d                   	pop    %ebp
f01002a8:	c3                   	ret    

f01002a9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002a9:	55                   	push   %ebp
f01002aa:	89 e5                	mov    %esp,%ebp
f01002ac:	57                   	push   %edi
f01002ad:	56                   	push   %esi
f01002ae:	53                   	push   %ebx
f01002af:	83 ec 1c             	sub    $0x1c,%esp
f01002b2:	89 c7                	mov    %eax,%edi
f01002b4:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002b9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002be:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c3:	eb 06                	jmp    f01002cb <cons_putc+0x22>
f01002c5:	89 ca                	mov    %ecx,%edx
f01002c7:	ec                   	in     (%dx),%al
f01002c8:	ec                   	in     (%dx),%al
f01002c9:	ec                   	in     (%dx),%al
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	89 f2                	mov    %esi,%edx
f01002cd:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ce:	a8 20                	test   $0x20,%al
f01002d0:	75 05                	jne    f01002d7 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d2:	83 eb 01             	sub    $0x1,%ebx
f01002d5:	75 ee                	jne    f01002c5 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002d7:	89 f8                	mov    %edi,%eax
f01002d9:	0f b6 c0             	movzbl %al,%eax
f01002dc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002df:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002e4:	ee                   	out    %al,(%dx)
f01002e5:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ea:	be 79 03 00 00       	mov    $0x379,%esi
f01002ef:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002f4:	eb 06                	jmp    f01002fc <cons_putc+0x53>
f01002f6:	89 ca                	mov    %ecx,%edx
f01002f8:	ec                   	in     (%dx),%al
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	ec                   	in     (%dx),%al
f01002fb:	ec                   	in     (%dx),%al
f01002fc:	89 f2                	mov    %esi,%edx
f01002fe:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002ff:	84 c0                	test   %al,%al
f0100301:	78 05                	js     f0100308 <cons_putc+0x5f>
f0100303:	83 eb 01             	sub    $0x1,%ebx
f0100306:	75 ee                	jne    f01002f6 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100308:	ba 78 03 00 00       	mov    $0x378,%edx
f010030d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100311:	ee                   	out    %al,(%dx)
f0100312:	b2 7a                	mov    $0x7a,%dl
f0100314:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100319:	ee                   	out    %al,(%dx)
f010031a:	b8 08 00 00 00       	mov    $0x8,%eax
f010031f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100328:	89 f8                	mov    %edi,%eax
f010032a:	80 cc 07             	or     $0x7,%ah
f010032d:	85 d2                	test   %edx,%edx
f010032f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	0f b6 c0             	movzbl %al,%eax
f0100337:	83 f8 09             	cmp    $0x9,%eax
f010033a:	74 76                	je     f01003b2 <cons_putc+0x109>
f010033c:	83 f8 09             	cmp    $0x9,%eax
f010033f:	7f 0a                	jg     f010034b <cons_putc+0xa2>
f0100341:	83 f8 08             	cmp    $0x8,%eax
f0100344:	74 16                	je     f010035c <cons_putc+0xb3>
f0100346:	e9 9b 00 00 00       	jmp    f01003e6 <cons_putc+0x13d>
f010034b:	83 f8 0a             	cmp    $0xa,%eax
f010034e:	66 90                	xchg   %ax,%ax
f0100350:	74 3a                	je     f010038c <cons_putc+0xe3>
f0100352:	83 f8 0d             	cmp    $0xd,%eax
f0100355:	74 3d                	je     f0100394 <cons_putc+0xeb>
f0100357:	e9 8a 00 00 00       	jmp    f01003e6 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f010035c:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f0100363:	66 85 c0             	test   %ax,%ax
f0100366:	0f 84 e5 00 00 00    	je     f0100451 <cons_putc+0x1a8>
			crt_pos--;
f010036c:	83 e8 01             	sub    $0x1,%eax
f010036f:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100375:	0f b7 c0             	movzwl %ax,%eax
f0100378:	66 81 e7 00 ff       	and    $0xff00,%di
f010037d:	83 cf 20             	or     $0x20,%edi
f0100380:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
f0100386:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010038a:	eb 78                	jmp    f0100404 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038c:	66 83 05 28 85 11 f0 	addw   $0x50,0xf0118528
f0100393:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100394:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f010039b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a1:	c1 e8 16             	shr    $0x16,%eax
f01003a4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a7:	c1 e0 04             	shl    $0x4,%eax
f01003aa:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
f01003b0:	eb 52                	jmp    f0100404 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f01003b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b7:	e8 ed fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c1:	e8 e3 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003c6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cb:	e8 d9 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003d0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d5:	e8 cf fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003da:	b8 20 00 00 00       	mov    $0x20,%eax
f01003df:	e8 c5 fe ff ff       	call   f01002a9 <cons_putc>
f01003e4:	eb 1e                	jmp    f0100404 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e6:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f01003ed:	8d 50 01             	lea    0x1(%eax),%edx
f01003f0:	66 89 15 28 85 11 f0 	mov    %dx,0xf0118528
f01003f7:	0f b7 c0             	movzwl %ax,%eax
f01003fa:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
f0100400:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100404:	66 81 3d 28 85 11 f0 	cmpw   $0x7cf,0xf0118528
f010040b:	cf 07 
f010040d:	76 42                	jbe    f0100451 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040f:	a1 2c 85 11 f0       	mov    0xf011852c,%eax
f0100414:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010041b:	00 
f010041c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100422:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100426:	89 04 24             	mov    %eax,(%esp)
f0100429:	e8 b6 37 00 00       	call   f0103be4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010042e:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100434:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100439:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043f:	83 c0 01             	add    $0x1,%eax
f0100442:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100447:	75 f0                	jne    f0100439 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 28 85 11 f0 	subw   $0x50,0xf0118528
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 30 85 11 f0    	mov    0xf0118530,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 28 85 11 f0 	movzwl 0xf0118528,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	83 c4 1c             	add    $0x1c,%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 34 85 11 f0 00 	cmpb   $0x0,0xf0118534
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f010049b:	e8 bc fc ff ff       	call   f010015c <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004ae:	e8 a9 fc ff ff       	call   f010015c <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 20 85 11 f0       	mov    0xf0118520,%eax
f01004ca:	3b 05 24 85 11 f0    	cmp    0xf0118524,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 20 85 11 f0    	mov    %edx,0xf0118520
f01004db:	0f b6 88 20 83 11 f0 	movzbl -0xfee7ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 20 85 11 f0 00 	movl   $0x0,0xf0118520
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 30 85 11 f0 b4 	movl   $0x3b4,0xf0118530
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 30 85 11 f0 d4 	movl   $0x3d4,0xf0118530
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 0d 30 85 11 f0    	mov    0xf0118530,%ecx
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 ca                	mov    %ecx,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 f0             	movzbl %al,%esi
f0100563:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 ca                	mov    %ecx,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 3d 2c 85 11 f0    	mov    %edi,0xf011852c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100577:	0f b6 d8             	movzbl %al,%ebx
f010057a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010057c:	66 89 35 28 85 11 f0 	mov    %si,0xf0118528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100583:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100588:	b8 00 00 00 00       	mov    $0x0,%eax
f010058d:	89 f2                	mov    %esi,%edx
f010058f:	ee                   	out    %al,(%dx)
f0100590:	b2 fb                	mov    $0xfb,%dl
f0100592:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100597:	ee                   	out    %al,(%dx)
f0100598:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059d:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a2:	89 da                	mov    %ebx,%edx
f01005a4:	ee                   	out    %al,(%dx)
f01005a5:	b2 f9                	mov    $0xf9,%dl
f01005a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ac:	ee                   	out    %al,(%dx)
f01005ad:	b2 fb                	mov    $0xfb,%dl
f01005af:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 fc                	mov    $0xfc,%dl
f01005b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 f9                	mov    $0xf9,%dl
f01005bf:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c5:	b2 fd                	mov    $0xfd,%dl
f01005c7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c8:	3c ff                	cmp    $0xff,%al
f01005ca:	0f 95 c1             	setne  %cl
f01005cd:	88 0d 34 85 11 f0    	mov    %cl,0xf0118534
f01005d3:	89 f2                	mov    %esi,%edx
f01005d5:	ec                   	in     (%dx),%al
f01005d6:	89 da                	mov    %ebx,%edx
f01005d8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d9:	84 c9                	test   %cl,%cl
f01005db:	75 0c                	jne    f01005e9 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005dd:	c7 04 24 99 40 10 f0 	movl   $0xf0104099,(%esp)
f01005e4:	e8 4b 2a 00 00       	call   f0103034 <cprintf>
}
f01005e9:	83 c4 1c             	add    $0x1c,%esp
f01005ec:	5b                   	pop    %ebx
f01005ed:	5e                   	pop    %esi
f01005ee:	5f                   	pop    %edi
f01005ef:	5d                   	pop    %ebp
f01005f0:	c3                   	ret    

f01005f1 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f1:	55                   	push   %ebp
f01005f2:	89 e5                	mov    %esp,%ebp
f01005f4:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fa:	e8 aa fc ff ff       	call   f01002a9 <cons_putc>
}
f01005ff:	c9                   	leave  
f0100600:	c3                   	ret    

f0100601 <getchar>:

int
getchar(void)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100607:	e8 a9 fe ff ff       	call   f01004b5 <cons_getc>
f010060c:	85 c0                	test   %eax,%eax
f010060e:	74 f7                	je     f0100607 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100610:	c9                   	leave  
f0100611:	c3                   	ret    

f0100612 <iscons>:

int
iscons(int fdnum)
{
f0100612:	55                   	push   %ebp
f0100613:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100615:	b8 01 00 00 00       	mov    $0x1,%eax
f010061a:	5d                   	pop    %ebp
f010061b:	c3                   	ret    
f010061c:	66 90                	xchg   %ax,%ax
f010061e:	66 90                	xchg   %ax,%ax

f0100620 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100626:	c7 44 24 08 e0 42 10 	movl   $0xf01042e0,0x8(%esp)
f010062d:	f0 
f010062e:	c7 44 24 04 fe 42 10 	movl   $0xf01042fe,0x4(%esp)
f0100635:	f0 
f0100636:	c7 04 24 03 43 10 f0 	movl   $0xf0104303,(%esp)
f010063d:	e8 f2 29 00 00       	call   f0103034 <cprintf>
f0100642:	c7 44 24 08 50 44 10 	movl   $0xf0104450,0x8(%esp)
f0100649:	f0 
f010064a:	c7 44 24 04 0c 43 10 	movl   $0xf010430c,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 03 43 10 f0 	movl   $0xf0104303,(%esp)
f0100659:	e8 d6 29 00 00       	call   f0103034 <cprintf>
f010065e:	c7 44 24 08 78 44 10 	movl   $0xf0104478,0x8(%esp)
f0100665:	f0 
f0100666:	c7 44 24 04 15 43 10 	movl   $0xf0104315,0x4(%esp)
f010066d:	f0 
f010066e:	c7 04 24 03 43 10 f0 	movl   $0xf0104303,(%esp)
f0100675:	e8 ba 29 00 00       	call   f0103034 <cprintf>
	return 0;
}
f010067a:	b8 00 00 00 00       	mov    $0x0,%eax
f010067f:	c9                   	leave  
f0100680:	c3                   	ret    

f0100681 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100687:	c7 04 24 22 43 10 f0 	movl   $0xf0104322,(%esp)
f010068e:	e8 a1 29 00 00       	call   f0103034 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100693:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010069a:	00 
f010069b:	c7 04 24 ac 44 10 f0 	movl   $0xf01044ac,(%esp)
f01006a2:	e8 8d 29 00 00       	call   f0103034 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ae:	00 
f01006af:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b6:	f0 
f01006b7:	c7 04 24 d4 44 10 f0 	movl   $0xf01044d4,(%esp)
f01006be:	e8 71 29 00 00       	call   f0103034 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c3:	c7 44 24 08 27 40 10 	movl   $0x104027,0x8(%esp)
f01006ca:	00 
f01006cb:	c7 44 24 04 27 40 10 	movl   $0xf0104027,0x4(%esp)
f01006d2:	f0 
f01006d3:	c7 04 24 f8 44 10 f0 	movl   $0xf01044f8,(%esp)
f01006da:	e8 55 29 00 00       	call   f0103034 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	c7 44 24 08 00 83 11 	movl   $0x118300,0x8(%esp)
f01006e6:	00 
f01006e7:	c7 44 24 04 00 83 11 	movl   $0xf0118300,0x4(%esp)
f01006ee:	f0 
f01006ef:	c7 04 24 1c 45 10 f0 	movl   $0xf010451c,(%esp)
f01006f6:	e8 39 29 00 00       	call   f0103034 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006fb:	c7 44 24 08 70 89 11 	movl   $0x118970,0x8(%esp)
f0100702:	00 
f0100703:	c7 44 24 04 70 89 11 	movl   $0xf0118970,0x4(%esp)
f010070a:	f0 
f010070b:	c7 04 24 40 45 10 f0 	movl   $0xf0104540,(%esp)
f0100712:	e8 1d 29 00 00       	call   f0103034 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100717:	b8 6f 8d 11 f0       	mov    $0xf0118d6f,%eax
f010071c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100721:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100726:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010072c:	85 c0                	test   %eax,%eax
f010072e:	0f 48 c2             	cmovs  %edx,%eax
f0100731:	c1 f8 0a             	sar    $0xa,%eax
f0100734:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100738:	c7 04 24 64 45 10 f0 	movl   $0xf0104564,(%esp)
f010073f:	e8 f0 28 00 00       	call   f0103034 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100744:	b8 00 00 00 00       	mov    $0x0,%eax
f0100749:	c9                   	leave  
f010074a:	c3                   	ret    

f010074b <mon_showmappings>:

int
mon_showmappings(int args, char **argv, struct Trapframe *tf)
{
f010074b:	55                   	push   %ebp
f010074c:	89 e5                	mov    %esp,%ebp
f010074e:	57                   	push   %edi
f010074f:	56                   	push   %esi
f0100750:	53                   	push   %ebx
f0100751:	81 ec 4c 01 00 00    	sub    $0x14c,%esp
f0100757:	8b 55 0c             	mov    0xc(%ebp),%edx
    char flag[1 << 8] = {
f010075a:	8d bd e8 fe ff ff    	lea    -0x118(%ebp),%edi
f0100760:	b9 40 00 00 00       	mov    $0x40,%ecx
f0100765:	b8 00 00 00 00       	mov    $0x0,%eax
f010076a:	f3 ab                	rep stos %eax,%es:(%edi)
f010076c:	c6 85 e8 fe ff ff 2d 	movb   $0x2d,-0x118(%ebp)
f0100773:	c6 85 ea fe ff ff 57 	movb   $0x57,-0x116(%ebp)
f010077a:	c6 85 ec fe ff ff 55 	movb   $0x55,-0x114(%ebp)
f0100781:	c6 85 08 ff ff ff 41 	movb   $0x41,-0xf8(%ebp)
f0100788:	c6 85 28 ff ff ff 44 	movb   $0x44,-0xd8(%ebp)
f010078f:	c6 85 68 ff ff ff 53 	movb   $0x53,-0x98(%ebp)
        [PTE_A] = 'A',
        [PTE_D] = 'D',
        [PTE_PS] = 'S'
    };

    char *arg1 = argv[1];
f0100796:	8b 42 04             	mov    0x4(%edx),%eax
    char *arg2 = argv[2];
f0100799:	8b 72 08             	mov    0x8(%edx),%esi
    char *arg3 = argv[3];
f010079c:	8b 52 0c             	mov    0xc(%edx),%edx
    char *endptr;
    if (arg1 == NULL || arg2 == NULL || arg3) {
f010079f:	85 c0                	test   %eax,%eax
f01007a1:	74 08                	je     f01007ab <mon_showmappings+0x60>
f01007a3:	85 f6                	test   %esi,%esi
f01007a5:	74 04                	je     f01007ab <mon_showmappings+0x60>
f01007a7:	85 d2                	test   %edx,%edx
f01007a9:	74 11                	je     f01007bc <mon_showmappings+0x71>
        cprintf("we need exactly two arguments!\n");
f01007ab:	c7 04 24 90 45 10 f0 	movl   $0xf0104590,(%esp)
f01007b2:	e8 7d 28 00 00       	call   f0103034 <cprintf>
        return 0;
f01007b7:	e9 4a 03 00 00       	jmp    f0100b06 <mon_showmappings+0x3bb>
    }
    uintptr_t va_l = strtol(arg1, &endptr, 16);
f01007bc:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01007c3:	00 
f01007c4:	8d 95 e4 fe ff ff    	lea    -0x11c(%ebp),%edx
f01007ca:	89 54 24 04          	mov    %edx,0x4(%esp)
f01007ce:	89 04 24             	mov    %eax,(%esp)
f01007d1:	e8 ed 34 00 00       	call   f0103cc3 <strtol>
f01007d6:	89 c3                	mov    %eax,%ebx
    if (*endptr) {
f01007d8:	8b 85 e4 fe ff ff    	mov    -0x11c(%ebp),%eax
f01007de:	80 38 00             	cmpb   $0x0,(%eax)
f01007e1:	74 11                	je     f01007f4 <mon_showmappings+0xa9>
        cprintf("argument's format error!\n");
f01007e3:	c7 04 24 3b 43 10 f0 	movl   $0xf010433b,(%esp)
f01007ea:	e8 45 28 00 00       	call   f0103034 <cprintf>
        return 0;
f01007ef:	e9 12 03 00 00       	jmp    f0100b06 <mon_showmappings+0x3bb>
    }
    uintptr_t va_r = strtol(arg2, &endptr, 16);
f01007f4:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01007fb:	00 
f01007fc:	8d 85 e4 fe ff ff    	lea    -0x11c(%ebp),%eax
f0100802:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100806:	89 34 24             	mov    %esi,(%esp)
f0100809:	e8 b5 34 00 00       	call   f0103cc3 <strtol>
f010080e:	89 85 d4 fe ff ff    	mov    %eax,-0x12c(%ebp)
    if (*endptr) {
f0100814:	8b 85 e4 fe ff ff    	mov    -0x11c(%ebp),%eax
f010081a:	80 38 00             	cmpb   $0x0,(%eax)
f010081d:	74 11                	je     f0100830 <mon_showmappings+0xe5>
        cprintf("argument's format error!\n");
f010081f:	c7 04 24 3b 43 10 f0 	movl   $0xf010433b,(%esp)
f0100826:	e8 09 28 00 00       	call   f0103034 <cprintf>
        return 0;
f010082b:	e9 d6 02 00 00       	jmp    f0100b06 <mon_showmappings+0x3bb>
    }
    if (va_l > va_r) {
f0100830:	3b 9d d4 fe ff ff    	cmp    -0x12c(%ebp),%ebx
f0100836:	76 11                	jbe    f0100849 <mon_showmappings+0xfe>
        cprintf("the first argument should not larger than the second argument!\n");
f0100838:	c7 04 24 b0 45 10 f0 	movl   $0xf01045b0,(%esp)
f010083f:	e8 f0 27 00 00       	call   f0103034 <cprintf>
        return 0;
f0100844:	e9 bd 02 00 00       	jmp    f0100b06 <mon_showmappings+0x3bb>
    }

    pde_t *pgdir = (pde_t *) PGADDR(PDX(UVPT), PDX(UVPT), 0);   // 这里直接用 kern_pgdir 也可以
    cprintf("      va range         entry      flag           pa range      \n");
f0100849:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100850:	e8 df 27 00 00       	call   f0103034 <cprintf>
    cprintf("---------------------------------------------------------------\n");
f0100855:	c7 04 24 34 46 10 f0 	movl   $0xf0104634,(%esp)
f010085c:	e8 d3 27 00 00       	call   f0103034 <cprintf>
f0100861:	89 de                	mov    %ebx,%esi
    while (va_l <= va_r) {
        pde_t pde = pgdir[PDX(va_l)];
f0100863:	89 f3                	mov    %esi,%ebx
f0100865:	c1 eb 16             	shr    $0x16,%ebx
f0100868:	8b 04 9d 00 d0 7b ef 	mov    -0x10843000(,%ebx,4),%eax
        if (pde & PTE_P) {
f010086f:	a8 01                	test   $0x1,%al
f0100871:	0f 84 7d 02 00 00    	je     f0100af4 <mon_showmappings+0x3a9>
            char bit_w = flag[pde & PTE_W];
f0100877:	89 c2                	mov    %eax,%edx
f0100879:	83 e2 02             	and    $0x2,%edx
f010087c:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f0100883:	ff 
f0100884:	88 8d d3 fe ff ff    	mov    %cl,-0x12d(%ebp)
            char bit_u = flag[pde & PTE_U];
f010088a:	89 c2                	mov    %eax,%edx
f010088c:	83 e2 04             	and    $0x4,%edx
f010088f:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f0100896:	ff 
f0100897:	88 8d d2 fe ff ff    	mov    %cl,-0x12e(%ebp)
            char bit_a = flag[pde & PTE_A];
f010089d:	89 c2                	mov    %eax,%edx
f010089f:	83 e2 20             	and    $0x20,%edx
f01008a2:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f01008a9:	ff 
f01008aa:	88 8d d1 fe ff ff    	mov    %cl,-0x12f(%ebp)
            char bit_d = flag[pde & PTE_D];
f01008b0:	89 c2                	mov    %eax,%edx
f01008b2:	83 e2 40             	and    $0x40,%edx
f01008b5:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f01008bc:	ff 
f01008bd:	88 8d d0 fe ff ff    	mov    %cl,-0x130(%ebp)
            char bit_s = flag[pde & PTE_PS];
f01008c3:	89 c2                	mov    %eax,%edx
f01008c5:	81 e2 80 00 00 00    	and    $0x80,%edx
f01008cb:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f01008d2:	ff 
f01008d3:	88 8d cf fe ff ff    	mov    %cl,-0x131(%ebp)
            pde = PTE_ADDR(pde);
f01008d9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008de:	89 c7                	mov    %eax,%edi
            if (va_l < KERNBASE) {
f01008e0:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01008e6:	0f 87 81 01 00 00    	ja     f0100a6d <mon_showmappings+0x322>
                cprintf("[%08x - %08x]", va_l, va_l + PTSIZE - 1);
f01008ec:	8d 86 ff ff 3f 00    	lea    0x3fffff(%esi),%eax
f01008f2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01008fa:	c7 04 24 74 43 10 f0 	movl   $0xf0104374,(%esp)
f0100901:	e8 2e 27 00 00       	call   f0103034 <cprintf>
                cprintf(" PDE[%03x] --%c%c%c--%c%cP\n", PDX(va_l), bit_s, bit_d, bit_a, bit_u, bit_w);
f0100906:	0f be 85 d3 fe ff ff 	movsbl -0x12d(%ebp),%eax
f010090d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100911:	0f be 85 d2 fe ff ff 	movsbl -0x12e(%ebp),%eax
f0100918:	89 44 24 14          	mov    %eax,0x14(%esp)
f010091c:	0f be 85 d1 fe ff ff 	movsbl -0x12f(%ebp),%eax
f0100923:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100927:	0f be 85 d0 fe ff ff 	movsbl -0x130(%ebp),%eax
f010092e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100932:	0f be 85 cf fe ff ff 	movsbl -0x131(%ebp),%eax
f0100939:	89 44 24 08          	mov    %eax,0x8(%esp)
f010093d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100941:	c7 04 24 55 43 10 f0 	movl   $0xf0104355,(%esp)
f0100948:	e8 e7 26 00 00       	call   f0103034 <cprintf>
                pte_t *pte = (pte_t *) (pde + KERNBASE);
		size_t i;
                for (i = 0; i != 1024 && va_l <= va_r; va_l += PGSIZE, ++i) {
f010094d:	bb 00 00 00 00       	mov    $0x0,%ebx
                    if (pte[i] & PTE_P) {
f0100952:	8b 84 9f 00 00 00 f0 	mov    -0x10000000(%edi,%ebx,4),%eax
f0100959:	a8 01                	test   $0x1,%al
f010095b:	0f 84 e6 00 00 00    	je     f0100a47 <mon_showmappings+0x2fc>
                        bit_w = flag[pte[i] & PTE_W];
f0100961:	89 c2                	mov    %eax,%edx
f0100963:	83 e2 02             	and    $0x2,%edx
f0100966:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f010096d:	ff 
f010096e:	88 8d d3 fe ff ff    	mov    %cl,-0x12d(%ebp)
                        bit_u = flag[pte[i] & PTE_U];
f0100974:	89 c2                	mov    %eax,%edx
f0100976:	83 e2 04             	and    $0x4,%edx
f0100979:	0f b6 94 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%edx
f0100980:	ff 
f0100981:	88 95 d2 fe ff ff    	mov    %dl,-0x12e(%ebp)
                        bit_a = flag[pte[i] & PTE_A];
f0100987:	89 c2                	mov    %eax,%edx
f0100989:	83 e2 20             	and    $0x20,%edx
f010098c:	0f b6 8c 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%ecx
f0100993:	ff 
f0100994:	88 8d d1 fe ff ff    	mov    %cl,-0x12f(%ebp)
                        bit_d = flag[pte[i] & PTE_D];
f010099a:	89 c2                	mov    %eax,%edx
f010099c:	83 e2 40             	and    $0x40,%edx
f010099f:	0f b6 94 15 e8 fe ff 	movzbl -0x118(%ebp,%edx,1),%edx
f01009a6:	ff 
f01009a7:	88 95 d0 fe ff ff    	mov    %dl,-0x130(%ebp)
                        bit_s = flag[pte[i] & PTE_PS];
f01009ad:	25 80 00 00 00       	and    $0x80,%eax
f01009b2:	0f b6 84 05 e8 fe ff 	movzbl -0x118(%ebp,%eax,1),%eax
f01009b9:	ff 
f01009ba:	88 85 cf fe ff ff    	mov    %al,-0x131(%ebp)
f01009c0:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
                        cprintf(" |-[%08x - %08x]", va_l, va_l + PGSIZE - 1);   
f01009c6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009ca:	89 74 24 04          	mov    %esi,0x4(%esp)
f01009ce:	c7 04 24 71 43 10 f0 	movl   $0xf0104371,(%esp)
f01009d5:	e8 5a 26 00 00       	call   f0103034 <cprintf>
                        cprintf(" PTE[%03x] --%c%c%c--%c%cP", i, bit_s, bit_d, bit_a, bit_u, bit_w);
f01009da:	0f be 85 d3 fe ff ff 	movsbl -0x12d(%ebp),%eax
f01009e1:	89 44 24 18          	mov    %eax,0x18(%esp)
f01009e5:	0f be 85 d2 fe ff ff 	movsbl -0x12e(%ebp),%eax
f01009ec:	89 44 24 14          	mov    %eax,0x14(%esp)
f01009f0:	0f be 85 d1 fe ff ff 	movsbl -0x12f(%ebp),%eax
f01009f7:	89 44 24 10          	mov    %eax,0x10(%esp)
f01009fb:	0f be 85 d0 fe ff ff 	movsbl -0x130(%ebp),%eax
f0100a02:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a06:	0f be 85 cf fe ff ff 	movsbl -0x131(%ebp),%eax
f0100a0d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a11:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100a15:	c7 04 24 82 43 10 f0 	movl   $0xf0104382,(%esp)
f0100a1c:	e8 13 26 00 00       	call   f0103034 <cprintf>
                        cprintf(" [%08x - %08x]\n", PTE_ADDR(pte[i]), PTE_ADDR(pte[i]) + PGSIZE - 1);           
f0100a21:	8b 84 9f 00 00 00 f0 	mov    -0x10000000(%edi,%ebx,4),%eax
f0100a28:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a2d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100a33:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a3b:	c7 04 24 9d 43 10 f0 	movl   $0xf010439d,(%esp)
f0100a42:	e8 ed 25 00 00       	call   f0103034 <cprintf>
            if (va_l < KERNBASE) {
                cprintf("[%08x - %08x]", va_l, va_l + PTSIZE - 1);
                cprintf(" PDE[%03x] --%c%c%c--%c%cP\n", PDX(va_l), bit_s, bit_d, bit_a, bit_u, bit_w);
                pte_t *pte = (pte_t *) (pde + KERNBASE);
		size_t i;
                for (i = 0; i != 1024 && va_l <= va_r; va_l += PGSIZE, ++i) {
f0100a47:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100a4d:	83 c3 01             	add    $0x1,%ebx
f0100a50:	39 b5 d4 fe ff ff    	cmp    %esi,-0x12c(%ebp)
f0100a56:	0f 82 9e 00 00 00    	jb     f0100afa <mon_showmappings+0x3af>
f0100a5c:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0100a62:	0f 85 ea fe ff ff    	jne    f0100952 <mon_showmappings+0x207>
f0100a68:	e9 8d 00 00 00       	jmp    f0100afa <mon_showmappings+0x3af>
                        cprintf(" [%08x - %08x]\n", PTE_ADDR(pte[i]), PTE_ADDR(pte[i]) + PGSIZE - 1);           
                    }
                }
                continue;
            }
            cprintf("[%08x - %08x]", va_l, va_l + PTSIZE - 1, PDX(va_l));
f0100a6d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100a71:	8d 86 ff ff 3f 00    	lea    0x3fffff(%esi),%eax
f0100a77:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a7b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a7f:	c7 04 24 74 43 10 f0 	movl   $0xf0104374,(%esp)
f0100a86:	e8 a9 25 00 00       	call   f0103034 <cprintf>
            cprintf(" PDE[%03x] --%c%c%c--%c%cP", PDX(va_l), bit_s, bit_d, bit_a, bit_u, bit_w);
f0100a8b:	0f be 85 d3 fe ff ff 	movsbl -0x12d(%ebp),%eax
f0100a92:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100a96:	0f be 85 d2 fe ff ff 	movsbl -0x12e(%ebp),%eax
f0100a9d:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100aa1:	0f be 85 d1 fe ff ff 	movsbl -0x12f(%ebp),%eax
f0100aa8:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100aac:	0f be 85 d0 fe ff ff 	movsbl -0x130(%ebp),%eax
f0100ab3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ab7:	0f be 85 cf fe ff ff 	movsbl -0x131(%ebp),%eax
f0100abe:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ac2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ac6:	c7 04 24 ad 43 10 f0 	movl   $0xf01043ad,(%esp)
f0100acd:	e8 62 25 00 00       	call   f0103034 <cprintf>
            cprintf(" [%08x - %08x]\n", pde, pde + PTSIZE - 1);
f0100ad2:	8d 87 ff ff 3f 00    	lea    0x3fffff(%edi),%eax
f0100ad8:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100adc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ae0:	c7 04 24 9d 43 10 f0 	movl   $0xf010439d,(%esp)
f0100ae7:	e8 48 25 00 00       	call   f0103034 <cprintf>
            if (va_l == 0xffc00000) {
f0100aec:	81 fe 00 00 c0 ff    	cmp    $0xffc00000,%esi
f0100af2:	74 12                	je     f0100b06 <mon_showmappings+0x3bb>
                break;
            }
        }
        va_l += PTSIZE;
f0100af4:	81 c6 00 00 40 00    	add    $0x400000,%esi
    }

    pde_t *pgdir = (pde_t *) PGADDR(PDX(UVPT), PDX(UVPT), 0);   // 这里直接用 kern_pgdir 也可以
    cprintf("      va range         entry      flag           pa range      \n");
    cprintf("---------------------------------------------------------------\n");
    while (va_l <= va_r) {
f0100afa:	39 b5 d4 fe ff ff    	cmp    %esi,-0x12c(%ebp)
f0100b00:	0f 83 5d fd ff ff    	jae    f0100863 <mon_showmappings+0x118>
            }
        }
        va_l += PTSIZE;
    }
    return 0;
}
f0100b06:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b0b:	81 c4 4c 01 00 00    	add    $0x14c,%esp
f0100b11:	5b                   	pop    %ebx
f0100b12:	5e                   	pop    %esi
f0100b13:	5f                   	pop    %edi
f0100b14:	5d                   	pop    %ebp
f0100b15:	c3                   	ret    

f0100b16 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100b16:	55                   	push   %ebp
f0100b17:	89 e5                	mov    %esp,%ebp
f0100b19:	57                   	push   %edi
f0100b1a:	56                   	push   %esi
f0100b1b:	53                   	push   %ebx
f0100b1c:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	int i;
	uint32_t eip;
	uint32_t* ebp = (uint32_t *)read_ebp();
f0100b1f:	89 ee                	mov    %ebp,%esi

	while (ebp) {
f0100b21:	e9 8a 00 00 00       	jmp    f0100bb0 <mon_backtrace+0x9a>
		eip = *(ebp + 1);
f0100b26:	8b 46 04             	mov    0x4(%esi),%eax
f0100b29:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		cprintf("ebp %x eip %x args", ebp, eip);
f0100b2c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100b30:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b34:	c7 04 24 c8 43 10 f0 	movl   $0xf01043c8,(%esp)
f0100b3b:	e8 f4 24 00 00       	call   f0103034 <cprintf>
		uint32_t *args = ebp + 2;
f0100b40:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100b43:	8d 7e 1c             	lea    0x1c(%esi),%edi
		for (i = 0; i < 5; i++) {
			uint32_t argi = args[i];
			cprintf(" %08x ", argi);
f0100b46:	8b 03                	mov    (%ebx),%eax
f0100b48:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b4c:	c7 04 24 db 43 10 f0 	movl   $0xf01043db,(%esp)
f0100b53:	e8 dc 24 00 00       	call   f0103034 <cprintf>
f0100b58:	83 c3 04             	add    $0x4,%ebx

	while (ebp) {
		eip = *(ebp + 1);
		cprintf("ebp %x eip %x args", ebp, eip);
		uint32_t *args = ebp + 2;
		for (i = 0; i < 5; i++) {
f0100b5b:	39 fb                	cmp    %edi,%ebx
f0100b5d:	75 e7                	jne    f0100b46 <mon_backtrace+0x30>
			uint32_t argi = args[i];
			cprintf(" %08x ", argi);
		}
		cprintf("\n");
f0100b5f:	c7 04 24 d4 50 10 f0 	movl   $0xf01050d4,(%esp)
f0100b66:	e8 c9 24 00 00       	call   f0103034 <cprintf>
		struct Eipdebuginfo debug_info;
		debuginfo_eip(eip, &debug_info);
f0100b6b:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100b6e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b72:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b75:	89 3c 24             	mov    %edi,(%esp)
f0100b78:	e8 ae 25 00 00       	call   f010312b <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",
f0100b7d:	89 f8                	mov    %edi,%eax
f0100b7f:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100b82:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100b86:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b89:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100b8d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b90:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b94:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100b97:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100b9b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100b9e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ba2:	c7 04 24 e2 43 10 f0 	movl   $0xf01043e2,(%esp)
f0100ba9:	e8 86 24 00 00       	call   f0103034 <cprintf>
			debug_info.eip_file, 
			debug_info.eip_line, 				
			debug_info.eip_fn_namelen,
			debug_info.eip_fn_name, 
			eip - debug_info.eip_fn_addr);
		ebp = (uint32_t *) *ebp;
f0100bae:	8b 36                	mov    (%esi),%esi
	// Your code here.
	int i;
	uint32_t eip;
	uint32_t* ebp = (uint32_t *)read_ebp();

	while (ebp) {
f0100bb0:	85 f6                	test   %esi,%esi
f0100bb2:	0f 85 6e ff ff ff    	jne    f0100b26 <mon_backtrace+0x10>
			debug_info.eip_fn_name, 
			eip - debug_info.eip_fn_addr);
		ebp = (uint32_t *) *ebp;
	}
	return 0;
}
f0100bb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bbd:	83 c4 4c             	add    $0x4c,%esp
f0100bc0:	5b                   	pop    %ebx
f0100bc1:	5e                   	pop    %esi
f0100bc2:	5f                   	pop    %edi
f0100bc3:	5d                   	pop    %ebp
f0100bc4:	c3                   	ret    

f0100bc5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100bc5:	55                   	push   %ebp
f0100bc6:	89 e5                	mov    %esp,%ebp
f0100bc8:	57                   	push   %edi
f0100bc9:	56                   	push   %esi
f0100bca:	53                   	push   %ebx
f0100bcb:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;
	unsigned int i = 0x00646c72;
f0100bce:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
	cprintf("Welcome to the JOS kernel monitor!\n");
f0100bd5:	c7 04 24 78 46 10 f0 	movl   $0xf0104678,(%esp)
f0100bdc:	e8 53 24 00 00       	call   f0103034 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100be1:	c7 04 24 9c 46 10 f0 	movl   $0xf010469c,(%esp)
f0100be8:	e8 47 24 00 00       	call   f0103034 <cprintf>
	cprintf("\033[0;32;40m H%x Wo%s", 57616, &i);
f0100bed:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100bf0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100bf4:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f0100bfb:	00 
f0100bfc:	c7 04 24 f3 43 10 f0 	movl   $0xf01043f3,(%esp)
f0100c03:	e8 2c 24 00 00       	call   f0103034 <cprintf>
	cprintf("x=%d y=%d", 3);
f0100c08:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0100c0f:	00 
f0100c10:	c7 04 24 07 44 10 f0 	movl   $0xf0104407,(%esp)
f0100c17:	e8 18 24 00 00       	call   f0103034 <cprintf>
	while (1) {
		buf = readline("K> ");
f0100c1c:	c7 04 24 11 44 10 f0 	movl   $0xf0104411,(%esp)
f0100c23:	e8 18 2d 00 00       	call   f0103940 <readline>
f0100c28:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100c2a:	85 c0                	test   %eax,%eax
f0100c2c:	74 ee                	je     f0100c1c <monitor+0x57>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100c2e:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100c35:	be 00 00 00 00       	mov    $0x0,%esi
f0100c3a:	eb 0a                	jmp    f0100c46 <monitor+0x81>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100c3c:	c6 03 00             	movb   $0x0,(%ebx)
f0100c3f:	89 f7                	mov    %esi,%edi
f0100c41:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100c44:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100c46:	0f b6 03             	movzbl (%ebx),%eax
f0100c49:	84 c0                	test   %al,%al
f0100c4b:	74 63                	je     f0100cb0 <monitor+0xeb>
f0100c4d:	0f be c0             	movsbl %al,%eax
f0100c50:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c54:	c7 04 24 15 44 10 f0 	movl   $0xf0104415,(%esp)
f0100c5b:	e8 fa 2e 00 00       	call   f0103b5a <strchr>
f0100c60:	85 c0                	test   %eax,%eax
f0100c62:	75 d8                	jne    f0100c3c <monitor+0x77>
			*buf++ = 0;
		if (*buf == 0)
f0100c64:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100c67:	74 47                	je     f0100cb0 <monitor+0xeb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100c69:	83 fe 0f             	cmp    $0xf,%esi
f0100c6c:	75 16                	jne    f0100c84 <monitor+0xbf>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100c6e:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100c75:	00 
f0100c76:	c7 04 24 1a 44 10 f0 	movl   $0xf010441a,(%esp)
f0100c7d:	e8 b2 23 00 00       	call   f0103034 <cprintf>
f0100c82:	eb 98                	jmp    f0100c1c <monitor+0x57>
			return 0;
		}
		argv[argc++] = buf;
f0100c84:	8d 7e 01             	lea    0x1(%esi),%edi
f0100c87:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f0100c8b:	eb 03                	jmp    f0100c90 <monitor+0xcb>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100c8d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100c90:	0f b6 03             	movzbl (%ebx),%eax
f0100c93:	84 c0                	test   %al,%al
f0100c95:	74 ad                	je     f0100c44 <monitor+0x7f>
f0100c97:	0f be c0             	movsbl %al,%eax
f0100c9a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c9e:	c7 04 24 15 44 10 f0 	movl   $0xf0104415,(%esp)
f0100ca5:	e8 b0 2e 00 00       	call   f0103b5a <strchr>
f0100caa:	85 c0                	test   %eax,%eax
f0100cac:	74 df                	je     f0100c8d <monitor+0xc8>
f0100cae:	eb 94                	jmp    f0100c44 <monitor+0x7f>
			buf++;
	}
	argv[argc] = 0;
f0100cb0:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f0100cb7:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100cb8:	85 f6                	test   %esi,%esi
f0100cba:	0f 84 5c ff ff ff    	je     f0100c1c <monitor+0x57>
f0100cc0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cc5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100cc8:	8b 04 85 e0 46 10 f0 	mov    -0xfefb920(,%eax,4),%eax
f0100ccf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cd3:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100cd6:	89 04 24             	mov    %eax,(%esp)
f0100cd9:	e8 1e 2e 00 00       	call   f0103afc <strcmp>
f0100cde:	85 c0                	test   %eax,%eax
f0100ce0:	75 24                	jne    f0100d06 <monitor+0x141>
			return commands[i].func(argc, argv, tf);
f0100ce2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ce5:	8b 55 08             	mov    0x8(%ebp),%edx
f0100ce8:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100cec:	8d 4d a4             	lea    -0x5c(%ebp),%ecx
f0100cef:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100cf3:	89 34 24             	mov    %esi,(%esp)
f0100cf6:	ff 14 85 e8 46 10 f0 	call   *-0xfefb918(,%eax,4)
	cprintf("\033[0;32;40m H%x Wo%s", 57616, &i);
	cprintf("x=%d y=%d", 3);
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100cfd:	85 c0                	test   %eax,%eax
f0100cff:	78 25                	js     f0100d26 <monitor+0x161>
f0100d01:	e9 16 ff ff ff       	jmp    f0100c1c <monitor+0x57>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100d06:	83 c3 01             	add    $0x1,%ebx
f0100d09:	83 fb 03             	cmp    $0x3,%ebx
f0100d0c:	75 b7                	jne    f0100cc5 <monitor+0x100>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100d0e:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100d11:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d15:	c7 04 24 37 44 10 f0 	movl   $0xf0104437,(%esp)
f0100d1c:	e8 13 23 00 00       	call   f0103034 <cprintf>
f0100d21:	e9 f6 fe ff ff       	jmp    f0100c1c <monitor+0x57>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100d26:	83 c4 6c             	add    $0x6c,%esp
f0100d29:	5b                   	pop    %ebx
f0100d2a:	5e                   	pop    %esi
f0100d2b:	5f                   	pop    %edi
f0100d2c:	5d                   	pop    %ebp
f0100d2d:	c3                   	ret    
f0100d2e:	66 90                	xchg   %ax,%ax

f0100d30 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100d30:	55                   	push   %ebp
f0100d31:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100d33:	83 3d 38 85 11 f0 00 	cmpl   $0x0,0xf0118538
f0100d3a:	75 11                	jne    f0100d4d <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100d3c:	ba 6f 99 11 f0       	mov    $0xf011996f,%edx
f0100d41:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100d47:	89 15 38 85 11 f0    	mov    %edx,0xf0118538
	
	if (n != 0) {
		char *next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
		return next;
	} else return nextfree;
f0100d4d:	8b 15 38 85 11 f0    	mov    0xf0118538,%edx
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	
	if (n != 0) {
f0100d53:	85 c0                	test   %eax,%eax
f0100d55:	74 11                	je     f0100d68 <boot_alloc+0x38>
		char *next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
f0100d57:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100d5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100d63:	a3 38 85 11 f0       	mov    %eax,0xf0118538
		return next;
	} else return nextfree;

	return NULL;
}
f0100d68:	89 d0                	mov    %edx,%eax
f0100d6a:	5d                   	pop    %ebp
f0100d6b:	c3                   	ret    

f0100d6c <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d6c:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100d72:	c1 f8 03             	sar    $0x3,%eax
f0100d75:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d78:	89 c2                	mov    %eax,%edx
f0100d7a:	c1 ea 0c             	shr    $0xc,%edx
f0100d7d:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100d83:	72 26                	jb     f0100dab <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100d85:	55                   	push   %ebp
f0100d86:	89 e5                	mov    %esp,%ebp
f0100d88:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d8f:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f0100d96:	f0 
f0100d97:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d9e:	00 
f0100d9f:	c7 04 24 44 4e 10 f0 	movl   $0xf0104e44,(%esp)
f0100da6:	e8 e9 f2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100dab:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100db0:	c3                   	ret    

f0100db1 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100db1:	89 d1                	mov    %edx,%ecx
f0100db3:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100db6:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100db9:	a8 01                	test   $0x1,%al
f0100dbb:	74 5d                	je     f0100e1a <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100dbd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dc2:	89 c1                	mov    %eax,%ecx
f0100dc4:	c1 e9 0c             	shr    $0xc,%ecx
f0100dc7:	3b 0d 64 89 11 f0    	cmp    0xf0118964,%ecx
f0100dcd:	72 26                	jb     f0100df5 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100dcf:	55                   	push   %ebp
f0100dd0:	89 e5                	mov    %esp,%ebp
f0100dd2:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dd5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dd9:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f0100de0:	f0 
f0100de1:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f0100de8:	00 
f0100de9:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0100df0:	e8 9f f2 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100df5:	c1 ea 0c             	shr    $0xc,%edx
f0100df8:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100dfe:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100e05:	89 c2                	mov    %eax,%edx
f0100e07:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100e0a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100e0f:	85 d2                	test   %edx,%edx
f0100e11:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100e16:	0f 44 c2             	cmove  %edx,%eax
f0100e19:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100e1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100e1f:	c3                   	ret    

f0100e20 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100e20:	55                   	push   %ebp
f0100e21:	89 e5                	mov    %esp,%ebp
f0100e23:	57                   	push   %edi
f0100e24:	56                   	push   %esi
f0100e25:	53                   	push   %ebx
f0100e26:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e29:	84 c0                	test   %al,%al
f0100e2b:	0f 85 15 03 00 00    	jne    f0101146 <check_page_free_list+0x326>
f0100e31:	e9 22 03 00 00       	jmp    f0101158 <check_page_free_list+0x338>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100e36:	c7 44 24 08 28 47 10 	movl   $0xf0104728,0x8(%esp)
f0100e3d:	f0 
f0100e3e:	c7 44 24 04 24 02 00 	movl   $0x224,0x4(%esp)
f0100e45:	00 
f0100e46:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0100e4d:	e8 42 f2 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e52:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e55:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e58:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e5b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e5e:	89 c2                	mov    %eax,%edx
f0100e60:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e66:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100e6c:	0f 95 c2             	setne  %dl
f0100e6f:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100e72:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100e76:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100e78:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e7c:	8b 00                	mov    (%eax),%eax
f0100e7e:	85 c0                	test   %eax,%eax
f0100e80:	75 dc                	jne    f0100e5e <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100e82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e85:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100e8b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e8e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e91:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100e93:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e96:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e9b:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ea0:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f0100ea6:	eb 63                	jmp    f0100f0b <check_page_free_list+0xeb>
f0100ea8:	89 d8                	mov    %ebx,%eax
f0100eaa:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100eb0:	c1 f8 03             	sar    $0x3,%eax
f0100eb3:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100eb6:	89 c2                	mov    %eax,%edx
f0100eb8:	c1 ea 16             	shr    $0x16,%edx
f0100ebb:	39 f2                	cmp    %esi,%edx
f0100ebd:	73 4a                	jae    f0100f09 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ebf:	89 c2                	mov    %eax,%edx
f0100ec1:	c1 ea 0c             	shr    $0xc,%edx
f0100ec4:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100eca:	72 20                	jb     f0100eec <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ecc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ed0:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f0100ed7:	f0 
f0100ed8:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100edf:	00 
f0100ee0:	c7 04 24 44 4e 10 f0 	movl   $0xf0104e44,(%esp)
f0100ee7:	e8 a8 f1 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100eec:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100ef3:	00 
f0100ef4:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100efb:	00 
	return (void *)(pa + KERNBASE);
f0100efc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f01:	89 04 24             	mov    %eax,(%esp)
f0100f04:	e8 8e 2c 00 00       	call   f0103b97 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f09:	8b 1b                	mov    (%ebx),%ebx
f0100f0b:	85 db                	test   %ebx,%ebx
f0100f0d:	75 99                	jne    f0100ea8 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100f0f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f14:	e8 17 fe ff ff       	call   f0100d30 <boot_alloc>
f0100f19:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f1c:	8b 15 3c 85 11 f0    	mov    0xf011853c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f22:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
		assert(pp < pages + npages);
f0100f28:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0100f2d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100f30:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100f33:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f36:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100f39:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f3e:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f41:	e9 97 01 00 00       	jmp    f01010dd <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f46:	39 ca                	cmp    %ecx,%edx
f0100f48:	73 24                	jae    f0100f6e <check_page_free_list+0x14e>
f0100f4a:	c7 44 24 0c 5e 4e 10 	movl   $0xf0104e5e,0xc(%esp)
f0100f51:	f0 
f0100f52:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0100f59:	f0 
f0100f5a:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
f0100f61:	00 
f0100f62:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0100f69:	e8 26 f1 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100f6e:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100f71:	72 24                	jb     f0100f97 <check_page_free_list+0x177>
f0100f73:	c7 44 24 0c 7f 4e 10 	movl   $0xf0104e7f,0xc(%esp)
f0100f7a:	f0 
f0100f7b:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0100f82:	f0 
f0100f83:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
f0100f8a:	00 
f0100f8b:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0100f92:	e8 fd f0 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f97:	89 d0                	mov    %edx,%eax
f0100f99:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100f9c:	a8 07                	test   $0x7,%al
f0100f9e:	74 24                	je     f0100fc4 <check_page_free_list+0x1a4>
f0100fa0:	c7 44 24 0c 4c 47 10 	movl   $0xf010474c,0xc(%esp)
f0100fa7:	f0 
f0100fa8:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0100faf:	f0 
f0100fb0:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
f0100fb7:	00 
f0100fb8:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0100fbf:	e8 d0 f0 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fc4:	c1 f8 03             	sar    $0x3,%eax
f0100fc7:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100fca:	85 c0                	test   %eax,%eax
f0100fcc:	75 24                	jne    f0100ff2 <check_page_free_list+0x1d2>
f0100fce:	c7 44 24 0c 93 4e 10 	movl   $0xf0104e93,0xc(%esp)
f0100fd5:	f0 
f0100fd6:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0100fdd:	f0 
f0100fde:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
f0100fe5:	00 
f0100fe6:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0100fed:	e8 a2 f0 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ff2:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ff7:	75 24                	jne    f010101d <check_page_free_list+0x1fd>
f0100ff9:	c7 44 24 0c a4 4e 10 	movl   $0xf0104ea4,0xc(%esp)
f0101000:	f0 
f0101001:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101008:	f0 
f0101009:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f0101010:	00 
f0101011:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101018:	e8 77 f0 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010101d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101022:	75 24                	jne    f0101048 <check_page_free_list+0x228>
f0101024:	c7 44 24 0c 80 47 10 	movl   $0xf0104780,0xc(%esp)
f010102b:	f0 
f010102c:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101033:	f0 
f0101034:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
f010103b:	00 
f010103c:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101043:	e8 4c f0 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101048:	3d 00 00 10 00       	cmp    $0x100000,%eax
f010104d:	75 24                	jne    f0101073 <check_page_free_list+0x253>
f010104f:	c7 44 24 0c bd 4e 10 	movl   $0xf0104ebd,0xc(%esp)
f0101056:	f0 
f0101057:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f010105e:	f0 
f010105f:	c7 44 24 04 46 02 00 	movl   $0x246,0x4(%esp)
f0101066:	00 
f0101067:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010106e:	e8 21 f0 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101073:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101078:	76 58                	jbe    f01010d2 <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010107a:	89 c3                	mov    %eax,%ebx
f010107c:	c1 eb 0c             	shr    $0xc,%ebx
f010107f:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0101082:	77 20                	ja     f01010a4 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101084:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101088:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f010108f:	f0 
f0101090:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101097:	00 
f0101098:	c7 04 24 44 4e 10 f0 	movl   $0xf0104e44,(%esp)
f010109f:	e8 f0 ef ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01010a4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010a9:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f01010ac:	76 2a                	jbe    f01010d8 <check_page_free_list+0x2b8>
f01010ae:	c7 44 24 0c a4 47 10 	movl   $0xf01047a4,0xc(%esp)
f01010b5:	f0 
f01010b6:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01010bd:	f0 
f01010be:	c7 44 24 04 47 02 00 	movl   $0x247,0x4(%esp)
f01010c5:	00 
f01010c6:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01010cd:	e8 c2 ef ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f01010d2:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f01010d6:	eb 03                	jmp    f01010db <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f01010d8:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010db:	8b 12                	mov    (%edx),%edx
f01010dd:	85 d2                	test   %edx,%edx
f01010df:	0f 85 61 fe ff ff    	jne    f0100f46 <check_page_free_list+0x126>
f01010e5:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01010e8:	85 db                	test   %ebx,%ebx
f01010ea:	7f 24                	jg     f0101110 <check_page_free_list+0x2f0>
f01010ec:	c7 44 24 0c d7 4e 10 	movl   $0xf0104ed7,0xc(%esp)
f01010f3:	f0 
f01010f4:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01010fb:	f0 
f01010fc:	c7 44 24 04 4f 02 00 	movl   $0x24f,0x4(%esp)
f0101103:	00 
f0101104:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010110b:	e8 84 ef ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0101110:	85 ff                	test   %edi,%edi
f0101112:	7f 24                	jg     f0101138 <check_page_free_list+0x318>
f0101114:	c7 44 24 0c e9 4e 10 	movl   $0xf0104ee9,0xc(%esp)
f010111b:	f0 
f010111c:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101123:	f0 
f0101124:	c7 44 24 04 50 02 00 	movl   $0x250,0x4(%esp)
f010112b:	00 
f010112c:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101133:	e8 5c ef ff ff       	call   f0100094 <_panic>
	cprintf("check_page_free_list() succeeded!\n");
f0101138:	c7 04 24 ec 47 10 f0 	movl   $0xf01047ec,(%esp)
f010113f:	e8 f0 1e 00 00       	call   f0103034 <cprintf>
f0101144:	eb 29                	jmp    f010116f <check_page_free_list+0x34f>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101146:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f010114b:	85 c0                	test   %eax,%eax
f010114d:	0f 85 ff fc ff ff    	jne    f0100e52 <check_page_free_list+0x32>
f0101153:	e9 de fc ff ff       	jmp    f0100e36 <check_page_free_list+0x16>
f0101158:	83 3d 3c 85 11 f0 00 	cmpl   $0x0,0xf011853c
f010115f:	0f 84 d1 fc ff ff    	je     f0100e36 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101165:	be 00 04 00 00       	mov    $0x400,%esi
f010116a:	e9 31 fd ff ff       	jmp    f0100ea0 <check_page_free_list+0x80>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list() succeeded!\n");
}
f010116f:	83 c4 4c             	add    $0x4c,%esp
f0101172:	5b                   	pop    %ebx
f0101173:	5e                   	pop    %esi
f0101174:	5f                   	pop    %edi
f0101175:	5d                   	pop    %ebp
f0101176:	c3                   	ret    

f0101177 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0101177:	55                   	push   %ebp
f0101178:	89 e5                	mov    %esp,%ebp
f010117a:	57                   	push   %edi
f010117b:	56                   	push   %esi
f010117c:	53                   	push   %ebx
	// 
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
f010117d:	c7 05 3c 85 11 f0 00 	movl   $0x0,0xf011853c
f0101184:	00 00 00 
//	cprintf("kern_pgdir locates at %p\n", kern_pgdir);
//	cprintf("pages locates at %p\n", pages);
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
f0101187:	b8 00 00 00 00       	mov    $0x0,%eax
f010118c:	e8 9f fb ff ff       	call   f0100d30 <boot_alloc>
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
		if(i == 0){       //Physical page 0 is in use.
			pages[i].pp_ref = 1;
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f0101191:	8b 35 40 85 11 f0    	mov    0xf0118540,%esi
	page_free_list = NULL;
//	cprintf("kern_pgdir locates at %p\n", kern_pgdir);
//	cprintf("pages locates at %p\n", pages);
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
f0101197:	05 00 00 00 10       	add    $0x10000000,%eax
f010119c:	c1 e8 0c             	shr    $0xc,%eax
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
		if(i == 0){       //Physical page 0 is in use.
			pages[i].pp_ref = 1;
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f010119f:	8d 7c 06 60          	lea    0x60(%esi,%eax,1),%edi
f01011a3:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
	int num_iohole = 96;
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
f01011a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ae:	eb 4b                	jmp    f01011fb <page_init+0x84>
		if(i == 0){       //Physical page 0 is in use.
f01011b0:	85 c0                	test   %eax,%eax
f01011b2:	75 0e                	jne    f01011c2 <page_init+0x4b>
			pages[i].pp_ref = 1;
f01011b4:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
f01011ba:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
f01011c0:	eb 36                	jmp    f01011f8 <page_init+0x81>
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f01011c2:	39 f0                	cmp    %esi,%eax
f01011c4:	72 13                	jb     f01011d9 <page_init+0x62>
f01011c6:	39 f8                	cmp    %edi,%eax
f01011c8:	73 0f                	jae    f01011d9 <page_init+0x62>
			pages[i].pp_ref = 1;
f01011ca:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
f01011d0:	66 c7 44 c2 04 01 00 	movw   $0x1,0x4(%edx,%eax,8)
f01011d7:	eb 1f                	jmp    f01011f8 <page_init+0x81>
f01011d9:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		}
		else {
			pages[i].pp_ref = 0;
f01011e0:	89 d1                	mov    %edx,%ecx
f01011e2:	03 0d 6c 89 11 f0    	add    0xf011896c,%ecx
f01011e8:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f01011ee:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f01011f0:	89 d3                	mov    %edx,%ebx
f01011f2:	03 1d 6c 89 11 f0    	add    0xf011896c,%ebx
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
	int num_iohole = 96;
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
f01011f8:	83 c0 01             	add    $0x1,%eax
f01011fb:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0101201:	72 ad                	jb     f01011b0 <page_init+0x39>
f0101203:	89 1d 3c 85 11 f0    	mov    %ebx,0xf011853c
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0101209:	5b                   	pop    %ebx
f010120a:	5e                   	pop    %esi
f010120b:	5f                   	pop    %edi
f010120c:	5d                   	pop    %ebp
f010120d:	c3                   	ret    

f010120e <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f010120e:	55                   	push   %ebp
f010120f:	89 e5                	mov    %esp,%ebp
f0101211:	53                   	push   %ebx
f0101212:	83 ec 14             	sub    $0x14,%esp
	if (page_free_list) {
f0101215:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f010121b:	85 db                	test   %ebx,%ebx
f010121d:	74 6f                	je     f010128e <page_alloc+0x80>
		struct PageInfo *result = page_free_list;
		page_free_list = page_free_list->pp_link;
f010121f:	8b 03                	mov    (%ebx),%eax
f0101221:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
		result->pp_link = NULL;
f0101226:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if (alloc_flags & ALLOC_ZERO) 
			memset(page2kva(result), 0, PGSIZE);
		return result;
f010122c:	89 d8                	mov    %ebx,%eax
{
	if (page_free_list) {
		struct PageInfo *result = page_free_list;
		page_free_list = page_free_list->pp_link;
		result->pp_link = NULL;
		if (alloc_flags & ALLOC_ZERO) 
f010122e:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101232:	74 5f                	je     f0101293 <page_alloc+0x85>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101234:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f010123a:	c1 f8 03             	sar    $0x3,%eax
f010123d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101240:	89 c2                	mov    %eax,%edx
f0101242:	c1 ea 0c             	shr    $0xc,%edx
f0101245:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f010124b:	72 20                	jb     f010126d <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010124d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101251:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f0101258:	f0 
f0101259:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101260:	00 
f0101261:	c7 04 24 44 4e 10 f0 	movl   $0xf0104e44,(%esp)
f0101268:	e8 27 ee ff ff       	call   f0100094 <_panic>
			memset(page2kva(result), 0, PGSIZE);
f010126d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101274:	00 
f0101275:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010127c:	00 
	return (void *)(pa + KERNBASE);
f010127d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101282:	89 04 24             	mov    %eax,(%esp)
f0101285:	e8 0d 29 00 00       	call   f0103b97 <memset>
		return result;
f010128a:	89 d8                	mov    %ebx,%eax
f010128c:	eb 05                	jmp    f0101293 <page_alloc+0x85>
	}
	return NULL;
f010128e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101293:	83 c4 14             	add    $0x14,%esp
f0101296:	5b                   	pop    %ebx
f0101297:	5d                   	pop    %ebp
f0101298:	c3                   	ret    

f0101299 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101299:	55                   	push   %ebp
f010129a:	89 e5                	mov    %esp,%ebp
f010129c:	8b 45 08             	mov    0x8(%ebp),%eax
	pp->pp_link = page_free_list;
f010129f:	8b 15 3c 85 11 f0    	mov    0xf011853c,%edx
f01012a5:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01012a7:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
}
f01012ac:	5d                   	pop    %ebp
f01012ad:	c3                   	ret    

f01012ae <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01012ae:	55                   	push   %ebp
f01012af:	89 e5                	mov    %esp,%ebp
f01012b1:	83 ec 04             	sub    $0x4,%esp
f01012b4:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01012b7:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01012bb:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01012be:	66 89 50 04          	mov    %dx,0x4(%eax)
f01012c2:	66 85 d2             	test   %dx,%dx
f01012c5:	75 08                	jne    f01012cf <page_decref+0x21>
		page_free(pp);
f01012c7:	89 04 24             	mov    %eax,(%esp)
f01012ca:	e8 ca ff ff ff       	call   f0101299 <page_free>
}
f01012cf:	c9                   	leave  
f01012d0:	c3                   	ret    

f01012d1 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01012d1:	55                   	push   %ebp
f01012d2:	89 e5                	mov    %esp,%ebp
f01012d4:	56                   	push   %esi
f01012d5:	53                   	push   %ebx
f01012d6:	83 ec 10             	sub    $0x10,%esp
f01012d9:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int page_off;
      	pte_t * page_base = NULL;
      	struct PageInfo* new_page = NULL;
      
      	unsigned int dic_off = PDX(va);
f01012dc:	89 f3                	mov    %esi,%ebx
f01012de:	c1 eb 16             	shr    $0x16,%ebx
      	pde_t * dic_entry_ptr = pgdir + dic_off;
f01012e1:	c1 e3 02             	shl    $0x2,%ebx
f01012e4:	03 5d 08             	add    0x8(%ebp),%ebx

      	if(!(*dic_entry_ptr & PTE_P))
f01012e7:	f6 03 01             	testb  $0x1,(%ebx)
f01012ea:	75 2c                	jne    f0101318 <pgdir_walk+0x47>
      	{
      	      if(create)
f01012ec:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01012f0:	74 6c                	je     f010135e <pgdir_walk+0x8d>
      	      {
      	             new_page = page_alloc(1);
f01012f2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01012f9:	e8 10 ff ff ff       	call   f010120e <page_alloc>
      	             if(new_page == NULL) return NULL;
f01012fe:	85 c0                	test   %eax,%eax
f0101300:	74 63                	je     f0101365 <pgdir_walk+0x94>
      	             new_page->pp_ref++;
f0101302:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101307:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f010130d:	c1 f8 03             	sar    $0x3,%eax
f0101310:	c1 e0 0c             	shl    $0xc,%eax
      	             *dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
f0101313:	83 c8 07             	or     $0x7,%eax
f0101316:	89 03                	mov    %eax,(%ebx)
      	      }
      	     else
      	         return NULL;      
      	}  
   
      	page_off = PTX(va);
f0101318:	c1 ee 0c             	shr    $0xc,%esi
f010131b:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
      	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f0101321:	8b 03                	mov    (%ebx),%eax
f0101323:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101328:	89 c2                	mov    %eax,%edx
f010132a:	c1 ea 0c             	shr    $0xc,%edx
f010132d:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0101333:	72 20                	jb     f0101355 <pgdir_walk+0x84>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101335:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101339:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f0101340:	f0 
f0101341:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f0101348:	00 
f0101349:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101350:	e8 3f ed ff ff       	call   f0100094 <_panic>
      	return &page_base[page_off];
f0101355:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f010135c:	eb 0c                	jmp    f010136a <pgdir_walk+0x99>
      	             if(new_page == NULL) return NULL;
      	             new_page->pp_ref++;
      	             *dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
      	      }
      	     else
      	         return NULL;      
f010135e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101363:	eb 05                	jmp    f010136a <pgdir_walk+0x99>
      	if(!(*dic_entry_ptr & PTE_P))
      	{
      	      if(create)
      	      {
      	             new_page = page_alloc(1);
      	             if(new_page == NULL) return NULL;
f0101365:	b8 00 00 00 00       	mov    $0x0,%eax
      	}  
   
      	page_off = PTX(va);
      	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
      	return &page_base[page_off];
}	
f010136a:	83 c4 10             	add    $0x10,%esp
f010136d:	5b                   	pop    %ebx
f010136e:	5e                   	pop    %esi
f010136f:	5d                   	pop    %ebp
f0101370:	c3                   	ret    

f0101371 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101371:	55                   	push   %ebp
f0101372:	89 e5                	mov    %esp,%ebp
f0101374:	57                   	push   %edi
f0101375:	56                   	push   %esi
f0101376:	53                   	push   %ebx
f0101377:	83 ec 2c             	sub    $0x2c,%esp
f010137a:	89 c7                	mov    %eax,%edi
f010137c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010137f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    int nadd;
    pte_t *entry = NULL;
    for(nadd = 0; nadd < size; nadd += PGSIZE)
f0101382:	bb 00 00 00 00       	mov    $0x0,%ebx
    {
        entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
        *entry = (pa | perm | PTE_P);
f0101387:	8b 45 0c             	mov    0xc(%ebp),%eax
f010138a:	83 c8 01             	or     $0x1,%eax
f010138d:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
    int nadd;
    pte_t *entry = NULL;
    for(nadd = 0; nadd < size; nadd += PGSIZE)
f0101390:	eb 24                	jmp    f01013b6 <boot_map_region+0x45>
    {
        entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
f0101392:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101399:	00 
f010139a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010139d:	01 d8                	add    %ebx,%eax
f010139f:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013a3:	89 3c 24             	mov    %edi,(%esp)
f01013a6:	e8 26 ff ff ff       	call   f01012d1 <pgdir_walk>
        *entry = (pa | perm | PTE_P);
f01013ab:	0b 75 dc             	or     -0x24(%ebp),%esi
f01013ae:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
    int nadd;
    pte_t *entry = NULL;
    for(nadd = 0; nadd < size; nadd += PGSIZE)
f01013b0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01013b6:	89 de                	mov    %ebx,%esi
f01013b8:	03 75 08             	add    0x8(%ebp),%esi
f01013bb:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01013be:	77 d2                	ja     f0101392 <boot_map_region+0x21>
        
        pa += PGSIZE;
        va += PGSIZE;
        
    }
}
f01013c0:	83 c4 2c             	add    $0x2c,%esp
f01013c3:	5b                   	pop    %ebx
f01013c4:	5e                   	pop    %esi
f01013c5:	5f                   	pop    %edi
f01013c6:	5d                   	pop    %ebp
f01013c7:	c3                   	ret    

f01013c8 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01013c8:	55                   	push   %ebp
f01013c9:	89 e5                	mov    %esp,%ebp
f01013cb:	53                   	push   %ebx
f01013cc:	83 ec 14             	sub    $0x14,%esp
f01013cf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *entry = NULL;
	struct PageInfo *result = NULL;

        entry = pgdir_walk(pgdir, va, 0);
f01013d2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01013d9:	00 
f01013da:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e4:	89 04 24             	mov    %eax,(%esp)
f01013e7:	e8 e5 fe ff ff       	call   f01012d1 <pgdir_walk>
f01013ec:	89 c2                	mov    %eax,%edx
	if(entry == NULL)
f01013ee:	85 c0                	test   %eax,%eax
f01013f0:	74 3e                	je     f0101430 <page_lookup+0x68>
		return NULL;
        if(!(*entry & PTE_P))
f01013f2:	8b 00                	mov    (%eax),%eax
f01013f4:	a8 01                	test   $0x1,%al
f01013f6:	74 3f                	je     f0101437 <page_lookup+0x6f>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013f8:	c1 e8 0c             	shr    $0xc,%eax
f01013fb:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0101401:	72 1c                	jb     f010141f <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0101403:	c7 44 24 08 10 48 10 	movl   $0xf0104810,0x8(%esp)
f010140a:	f0 
f010140b:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101412:	00 
f0101413:	c7 04 24 44 4e 10 f0 	movl   $0xf0104e44,(%esp)
f010141a:	e8 75 ec ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010141f:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
f0101425:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
                return NULL;
    
        result = pa2page(PTE_ADDR(*entry));
        if(pte_store != NULL)
f0101428:	85 db                	test   %ebx,%ebx
f010142a:	74 10                	je     f010143c <page_lookup+0x74>
        {
               *pte_store = entry;
f010142c:	89 13                	mov    %edx,(%ebx)
f010142e:	eb 0c                	jmp    f010143c <page_lookup+0x74>
	pte_t *entry = NULL;
	struct PageInfo *result = NULL;

        entry = pgdir_walk(pgdir, va, 0);
	if(entry == NULL)
		return NULL;
f0101430:	b8 00 00 00 00       	mov    $0x0,%eax
f0101435:	eb 05                	jmp    f010143c <page_lookup+0x74>
        if(!(*entry & PTE_P))
                return NULL;
f0101437:	b8 00 00 00 00       	mov    $0x0,%eax
        if(pte_store != NULL)
        {
               *pte_store = entry;
        }
        return result;	
}
f010143c:	83 c4 14             	add    $0x14,%esp
f010143f:	5b                   	pop    %ebx
f0101440:	5d                   	pop    %ebp
f0101441:	c3                   	ret    

f0101442 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101442:	55                   	push   %ebp
f0101443:	89 e5                	mov    %esp,%ebp
f0101445:	53                   	push   %ebx
f0101446:	83 ec 24             	sub    $0x24,%esp
f0101449:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte = NULL;    
f010144c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &pte);    
f0101453:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101456:	89 44 24 08          	mov    %eax,0x8(%esp)
f010145a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010145e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101461:	89 04 24             	mov    %eax,(%esp)
f0101464:	e8 5f ff ff ff       	call   f01013c8 <page_lookup>
	if(page == NULL) return ;    
f0101469:	85 c0                	test   %eax,%eax
f010146b:	74 14                	je     f0101481 <page_remove+0x3f>
        page_decref(page);
f010146d:	89 04 24             	mov    %eax,(%esp)
f0101470:	e8 39 fe ff ff       	call   f01012ae <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101475:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
	*pte = 0;
f0101478:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010147b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f0101481:	83 c4 24             	add    $0x24,%esp
f0101484:	5b                   	pop    %ebx
f0101485:	5d                   	pop    %ebp
f0101486:	c3                   	ret    

f0101487 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101487:	55                   	push   %ebp
f0101488:	89 e5                	mov    %esp,%ebp
f010148a:	57                   	push   %edi
f010148b:	56                   	push   %esi
f010148c:	53                   	push   %ebx
f010148d:	83 ec 1c             	sub    $0x1c,%esp
f0101490:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101493:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *entry = NULL;
    	entry =  pgdir_walk(pgdir, va, 1);   
f0101496:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010149d:	00 
f010149e:	8b 45 10             	mov    0x10(%ebp),%eax
f01014a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014a5:	89 1c 24             	mov    %ebx,(%esp)
f01014a8:	e8 24 fe ff ff       	call   f01012d1 <pgdir_walk>
f01014ad:	89 c6                	mov    %eax,%esi
    	if(entry == NULL) return -E_NO_MEM;
f01014af:	85 c0                	test   %eax,%eax
f01014b1:	74 48                	je     f01014fb <page_insert+0x74>

    	pp->pp_ref++;
f01014b3:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
    	if((*entry) & PTE_P)            
f01014b8:	f6 00 01             	testb  $0x1,(%eax)
f01014bb:	74 15                	je     f01014d2 <page_insert+0x4b>
f01014bd:	8b 45 10             	mov    0x10(%ebp),%eax
f01014c0:	0f 01 38             	invlpg (%eax)
    	{
    	    tlb_invalidate(pgdir, va);
    	    page_remove(pgdir, va);
f01014c3:	8b 45 10             	mov    0x10(%ebp),%eax
f01014c6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014ca:	89 1c 24             	mov    %ebx,(%esp)
f01014cd:	e8 70 ff ff ff       	call   f0101442 <page_remove>
    	}
    	*entry = (page2pa(pp) | perm | PTE_P);
f01014d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01014d5:	83 c8 01             	or     $0x1,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014d8:	2b 3d 6c 89 11 f0    	sub    0xf011896c,%edi
f01014de:	c1 ff 03             	sar    $0x3,%edi
f01014e1:	c1 e7 0c             	shl    $0xc,%edi
f01014e4:	09 c7                	or     %eax,%edi
f01014e6:	89 3e                	mov    %edi,(%esi)
    	pgdir[PDX(va)] |= perm;                 
f01014e8:	8b 45 10             	mov    0x10(%ebp),%eax
f01014eb:	c1 e8 16             	shr    $0x16,%eax
f01014ee:	8b 55 14             	mov    0x14(%ebp),%edx
f01014f1:	09 14 83             	or     %edx,(%ebx,%eax,4)
        
    	return 0;
f01014f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01014f9:	eb 05                	jmp    f0101500 <page_insert+0x79>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *entry = NULL;
    	entry =  pgdir_walk(pgdir, va, 1);   
    	if(entry == NULL) return -E_NO_MEM;
f01014fb:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    	}
    	*entry = (page2pa(pp) | perm | PTE_P);
    	pgdir[PDX(va)] |= perm;                 
        
    	return 0;
}
f0101500:	83 c4 1c             	add    $0x1c,%esp
f0101503:	5b                   	pop    %ebx
f0101504:	5e                   	pop    %esi
f0101505:	5f                   	pop    %edi
f0101506:	5d                   	pop    %ebp
f0101507:	c3                   	ret    

f0101508 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101508:	55                   	push   %ebp
f0101509:	89 e5                	mov    %esp,%ebp
f010150b:	57                   	push   %edi
f010150c:	56                   	push   %esi
f010150d:	53                   	push   %ebx
f010150e:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101511:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0101518:	e8 a7 1a 00 00       	call   f0102fc4 <mc146818_read>
f010151d:	89 c3                	mov    %eax,%ebx
f010151f:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101526:	e8 99 1a 00 00       	call   f0102fc4 <mc146818_read>
f010152b:	c1 e0 08             	shl    $0x8,%eax
f010152e:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101530:	89 d8                	mov    %ebx,%eax
f0101532:	c1 e0 0a             	shl    $0xa,%eax
f0101535:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010153b:	85 c0                	test   %eax,%eax
f010153d:	0f 48 c2             	cmovs  %edx,%eax
f0101540:	c1 f8 0c             	sar    $0xc,%eax
f0101543:	a3 40 85 11 f0       	mov    %eax,0xf0118540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101548:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010154f:	e8 70 1a 00 00       	call   f0102fc4 <mc146818_read>
f0101554:	89 c3                	mov    %eax,%ebx
f0101556:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010155d:	e8 62 1a 00 00       	call   f0102fc4 <mc146818_read>
f0101562:	c1 e0 08             	shl    $0x8,%eax
f0101565:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101567:	89 d8                	mov    %ebx,%eax
f0101569:	c1 e0 0a             	shl    $0xa,%eax
f010156c:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101572:	85 c0                	test   %eax,%eax
f0101574:	0f 48 c2             	cmovs  %edx,%eax
f0101577:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010157a:	85 c0                	test   %eax,%eax
f010157c:	74 0e                	je     f010158c <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010157e:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101584:	89 15 64 89 11 f0    	mov    %edx,0xf0118964
f010158a:	eb 0c                	jmp    f0101598 <mem_init+0x90>
	else
		npages = npages_basemem;
f010158c:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
f0101592:	89 15 64 89 11 f0    	mov    %edx,0xf0118964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101598:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010159b:	c1 e8 0a             	shr    $0xa,%eax
f010159e:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01015a2:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f01015a7:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01015aa:	c1 e8 0a             	shr    $0xa,%eax
f01015ad:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01015b1:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f01015b6:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01015b9:	c1 e8 0a             	shr    $0xa,%eax
f01015bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015c0:	c7 04 24 30 48 10 f0 	movl   $0xf0104830,(%esp)
f01015c7:	e8 68 1a 00 00       	call   f0103034 <cprintf>
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01015cc:	b8 00 10 00 00       	mov    $0x1000,%eax
f01015d1:	e8 5a f7 ff ff       	call   f0100d30 <boot_alloc>
f01015d6:	a3 68 89 11 f0       	mov    %eax,0xf0118968
	memset(kern_pgdir, 0, PGSIZE);
f01015db:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01015e2:	00 
f01015e3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01015ea:	00 
f01015eb:	89 04 24             	mov    %eax,(%esp)
f01015ee:	e8 a4 25 00 00       	call   f0103b97 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01015f3:	a1 68 89 11 f0       	mov    0xf0118968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01015f8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01015fd:	77 20                	ja     f010161f <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01015ff:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101603:	c7 44 24 08 6c 48 10 	movl   $0xf010486c,0x8(%esp)
f010160a:	f0 
f010160b:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
f0101612:	00 
f0101613:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010161a:	e8 75 ea ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010161f:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101625:	83 ca 05             	or     $0x5,%edx
f0101628:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo) * npages);
f010162e:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0101633:	c1 e0 03             	shl    $0x3,%eax
f0101636:	e8 f5 f6 ff ff       	call   f0100d30 <boot_alloc>
f010163b:	a3 6c 89 11 f0       	mov    %eax,0xf011896c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101640:	e8 32 fb ff ff       	call   f0101177 <page_init>

	check_page_free_list(1);
f0101645:	b8 01 00 00 00       	mov    $0x1,%eax
f010164a:	e8 d1 f7 ff ff       	call   f0100e20 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010164f:	83 3d 6c 89 11 f0 00 	cmpl   $0x0,0xf011896c
f0101656:	75 1c                	jne    f0101674 <mem_init+0x16c>
		panic("'pages' is a null pointer!");
f0101658:	c7 44 24 08 fa 4e 10 	movl   $0xf0104efa,0x8(%esp)
f010165f:	f0 
f0101660:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f0101667:	00 
f0101668:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010166f:	e8 20 ea ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101674:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101679:	bb 00 00 00 00       	mov    $0x0,%ebx
f010167e:	eb 05                	jmp    f0101685 <mem_init+0x17d>
		++nfree;
f0101680:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101683:	8b 00                	mov    (%eax),%eax
f0101685:	85 c0                	test   %eax,%eax
f0101687:	75 f7                	jne    f0101680 <mem_init+0x178>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101689:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101690:	e8 79 fb ff ff       	call   f010120e <page_alloc>
f0101695:	89 c7                	mov    %eax,%edi
f0101697:	85 c0                	test   %eax,%eax
f0101699:	75 24                	jne    f01016bf <mem_init+0x1b7>
f010169b:	c7 44 24 0c 15 4f 10 	movl   $0xf0104f15,0xc(%esp)
f01016a2:	f0 
f01016a3:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01016aa:	f0 
f01016ab:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f01016b2:	00 
f01016b3:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01016ba:	e8 d5 e9 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01016bf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016c6:	e8 43 fb ff ff       	call   f010120e <page_alloc>
f01016cb:	89 c6                	mov    %eax,%esi
f01016cd:	85 c0                	test   %eax,%eax
f01016cf:	75 24                	jne    f01016f5 <mem_init+0x1ed>
f01016d1:	c7 44 24 0c 2b 4f 10 	movl   $0xf0104f2b,0xc(%esp)
f01016d8:	f0 
f01016d9:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01016e0:	f0 
f01016e1:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f01016e8:	00 
f01016e9:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01016f0:	e8 9f e9 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01016f5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016fc:	e8 0d fb ff ff       	call   f010120e <page_alloc>
f0101701:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101704:	85 c0                	test   %eax,%eax
f0101706:	75 24                	jne    f010172c <mem_init+0x224>
f0101708:	c7 44 24 0c 41 4f 10 	movl   $0xf0104f41,0xc(%esp)
f010170f:	f0 
f0101710:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101717:	f0 
f0101718:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f010171f:	00 
f0101720:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101727:	e8 68 e9 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010172c:	39 f7                	cmp    %esi,%edi
f010172e:	75 24                	jne    f0101754 <mem_init+0x24c>
f0101730:	c7 44 24 0c 57 4f 10 	movl   $0xf0104f57,0xc(%esp)
f0101737:	f0 
f0101738:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f010173f:	f0 
f0101740:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f0101747:	00 
f0101748:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010174f:	e8 40 e9 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101754:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101757:	39 c6                	cmp    %eax,%esi
f0101759:	74 04                	je     f010175f <mem_init+0x257>
f010175b:	39 c7                	cmp    %eax,%edi
f010175d:	75 24                	jne    f0101783 <mem_init+0x27b>
f010175f:	c7 44 24 0c 90 48 10 	movl   $0xf0104890,0xc(%esp)
f0101766:	f0 
f0101767:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f010176e:	f0 
f010176f:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f0101776:	00 
f0101777:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010177e:	e8 11 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101783:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101789:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f010178e:	c1 e0 0c             	shl    $0xc,%eax
f0101791:	89 f9                	mov    %edi,%ecx
f0101793:	29 d1                	sub    %edx,%ecx
f0101795:	c1 f9 03             	sar    $0x3,%ecx
f0101798:	c1 e1 0c             	shl    $0xc,%ecx
f010179b:	39 c1                	cmp    %eax,%ecx
f010179d:	72 24                	jb     f01017c3 <mem_init+0x2bb>
f010179f:	c7 44 24 0c 69 4f 10 	movl   $0xf0104f69,0xc(%esp)
f01017a6:	f0 
f01017a7:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01017ae:	f0 
f01017af:	c7 44 24 04 71 02 00 	movl   $0x271,0x4(%esp)
f01017b6:	00 
f01017b7:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01017be:	e8 d1 e8 ff ff       	call   f0100094 <_panic>
f01017c3:	89 f1                	mov    %esi,%ecx
f01017c5:	29 d1                	sub    %edx,%ecx
f01017c7:	c1 f9 03             	sar    $0x3,%ecx
f01017ca:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01017cd:	39 c8                	cmp    %ecx,%eax
f01017cf:	77 24                	ja     f01017f5 <mem_init+0x2ed>
f01017d1:	c7 44 24 0c 86 4f 10 	movl   $0xf0104f86,0xc(%esp)
f01017d8:	f0 
f01017d9:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01017e0:	f0 
f01017e1:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
f01017e8:	00 
f01017e9:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01017f0:	e8 9f e8 ff ff       	call   f0100094 <_panic>
f01017f5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01017f8:	29 d1                	sub    %edx,%ecx
f01017fa:	89 ca                	mov    %ecx,%edx
f01017fc:	c1 fa 03             	sar    $0x3,%edx
f01017ff:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101802:	39 d0                	cmp    %edx,%eax
f0101804:	77 24                	ja     f010182a <mem_init+0x322>
f0101806:	c7 44 24 0c a3 4f 10 	movl   $0xf0104fa3,0xc(%esp)
f010180d:	f0 
f010180e:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101815:	f0 
f0101816:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f010181d:	00 
f010181e:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101825:	e8 6a e8 ff ff       	call   f0100094 <_panic>


	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010182a:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f010182f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101832:	c7 05 3c 85 11 f0 00 	movl   $0x0,0xf011853c
f0101839:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010183c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101843:	e8 c6 f9 ff ff       	call   f010120e <page_alloc>
f0101848:	85 c0                	test   %eax,%eax
f010184a:	74 24                	je     f0101870 <mem_init+0x368>
f010184c:	c7 44 24 0c c0 4f 10 	movl   $0xf0104fc0,0xc(%esp)
f0101853:	f0 
f0101854:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f010185b:	f0 
f010185c:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0101863:	00 
f0101864:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010186b:	e8 24 e8 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101870:	89 3c 24             	mov    %edi,(%esp)
f0101873:	e8 21 fa ff ff       	call   f0101299 <page_free>
	page_free(pp1);
f0101878:	89 34 24             	mov    %esi,(%esp)
f010187b:	e8 19 fa ff ff       	call   f0101299 <page_free>
	page_free(pp2);
f0101880:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101883:	89 04 24             	mov    %eax,(%esp)
f0101886:	e8 0e fa ff ff       	call   f0101299 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010188b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101892:	e8 77 f9 ff ff       	call   f010120e <page_alloc>
f0101897:	89 c6                	mov    %eax,%esi
f0101899:	85 c0                	test   %eax,%eax
f010189b:	75 24                	jne    f01018c1 <mem_init+0x3b9>
f010189d:	c7 44 24 0c 15 4f 10 	movl   $0xf0104f15,0xc(%esp)
f01018a4:	f0 
f01018a5:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01018ac:	f0 
f01018ad:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f01018b4:	00 
f01018b5:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01018bc:	e8 d3 e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01018c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018c8:	e8 41 f9 ff ff       	call   f010120e <page_alloc>
f01018cd:	89 c7                	mov    %eax,%edi
f01018cf:	85 c0                	test   %eax,%eax
f01018d1:	75 24                	jne    f01018f7 <mem_init+0x3ef>
f01018d3:	c7 44 24 0c 2b 4f 10 	movl   $0xf0104f2b,0xc(%esp)
f01018da:	f0 
f01018db:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01018e2:	f0 
f01018e3:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f01018ea:	00 
f01018eb:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01018f2:	e8 9d e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01018f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018fe:	e8 0b f9 ff ff       	call   f010120e <page_alloc>
f0101903:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101906:	85 c0                	test   %eax,%eax
f0101908:	75 24                	jne    f010192e <mem_init+0x426>
f010190a:	c7 44 24 0c 41 4f 10 	movl   $0xf0104f41,0xc(%esp)
f0101911:	f0 
f0101912:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101919:	f0 
f010191a:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f0101921:	00 
f0101922:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101929:	e8 66 e7 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010192e:	39 fe                	cmp    %edi,%esi
f0101930:	75 24                	jne    f0101956 <mem_init+0x44e>
f0101932:	c7 44 24 0c 57 4f 10 	movl   $0xf0104f57,0xc(%esp)
f0101939:	f0 
f010193a:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101941:	f0 
f0101942:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f0101949:	00 
f010194a:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101951:	e8 3e e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101956:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101959:	39 c7                	cmp    %eax,%edi
f010195b:	74 04                	je     f0101961 <mem_init+0x459>
f010195d:	39 c6                	cmp    %eax,%esi
f010195f:	75 24                	jne    f0101985 <mem_init+0x47d>
f0101961:	c7 44 24 0c 90 48 10 	movl   $0xf0104890,0xc(%esp)
f0101968:	f0 
f0101969:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101970:	f0 
f0101971:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f0101978:	00 
f0101979:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101980:	e8 0f e7 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101985:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010198c:	e8 7d f8 ff ff       	call   f010120e <page_alloc>
f0101991:	85 c0                	test   %eax,%eax
f0101993:	74 24                	je     f01019b9 <mem_init+0x4b1>
f0101995:	c7 44 24 0c c0 4f 10 	movl   $0xf0104fc0,0xc(%esp)
f010199c:	f0 
f010199d:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01019a4:	f0 
f01019a5:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f01019ac:	00 
f01019ad:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01019b4:	e8 db e6 ff ff       	call   f0100094 <_panic>
f01019b9:	89 f0                	mov    %esi,%eax
f01019bb:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f01019c1:	c1 f8 03             	sar    $0x3,%eax
f01019c4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019c7:	89 c2                	mov    %eax,%edx
f01019c9:	c1 ea 0c             	shr    $0xc,%edx
f01019cc:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f01019d2:	72 20                	jb     f01019f4 <mem_init+0x4ec>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01019d8:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f01019df:	f0 
f01019e0:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01019e7:	00 
f01019e8:	c7 04 24 44 4e 10 f0 	movl   $0xf0104e44,(%esp)
f01019ef:	e8 a0 e6 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01019f4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01019fb:	00 
f01019fc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101a03:	00 
	return (void *)(pa + KERNBASE);
f0101a04:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a09:	89 04 24             	mov    %eax,(%esp)
f0101a0c:	e8 86 21 00 00       	call   f0103b97 <memset>
	page_free(pp0);
f0101a11:	89 34 24             	mov    %esi,(%esp)
f0101a14:	e8 80 f8 ff ff       	call   f0101299 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101a19:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101a20:	e8 e9 f7 ff ff       	call   f010120e <page_alloc>
f0101a25:	85 c0                	test   %eax,%eax
f0101a27:	75 24                	jne    f0101a4d <mem_init+0x545>
f0101a29:	c7 44 24 0c cf 4f 10 	movl   $0xf0104fcf,0xc(%esp)
f0101a30:	f0 
f0101a31:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101a38:	f0 
f0101a39:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
f0101a40:	00 
f0101a41:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101a48:	e8 47 e6 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101a4d:	39 c6                	cmp    %eax,%esi
f0101a4f:	74 24                	je     f0101a75 <mem_init+0x56d>
f0101a51:	c7 44 24 0c ed 4f 10 	movl   $0xf0104fed,0xc(%esp)
f0101a58:	f0 
f0101a59:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101a60:	f0 
f0101a61:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f0101a68:	00 
f0101a69:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101a70:	e8 1f e6 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a75:	89 f0                	mov    %esi,%eax
f0101a77:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0101a7d:	c1 f8 03             	sar    $0x3,%eax
f0101a80:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a83:	89 c2                	mov    %eax,%edx
f0101a85:	c1 ea 0c             	shr    $0xc,%edx
f0101a88:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0101a8e:	72 20                	jb     f0101ab0 <mem_init+0x5a8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a90:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101a94:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f0101a9b:	f0 
f0101a9c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101aa3:	00 
f0101aa4:	c7 04 24 44 4e 10 f0 	movl   $0xf0104e44,(%esp)
f0101aab:	e8 e4 e5 ff ff       	call   f0100094 <_panic>
f0101ab0:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101ab6:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101abc:	80 38 00             	cmpb   $0x0,(%eax)
f0101abf:	74 24                	je     f0101ae5 <mem_init+0x5dd>
f0101ac1:	c7 44 24 0c fd 4f 10 	movl   $0xf0104ffd,0xc(%esp)
f0101ac8:	f0 
f0101ac9:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101ad0:	f0 
f0101ad1:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0101ad8:	00 
f0101ad9:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101ae0:	e8 af e5 ff ff       	call   f0100094 <_panic>
f0101ae5:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101ae8:	39 d0                	cmp    %edx,%eax
f0101aea:	75 d0                	jne    f0101abc <mem_init+0x5b4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101aec:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101aef:	a3 3c 85 11 f0       	mov    %eax,0xf011853c

	// free the pages we took
	page_free(pp0);
f0101af4:	89 34 24             	mov    %esi,(%esp)
f0101af7:	e8 9d f7 ff ff       	call   f0101299 <page_free>
	page_free(pp1);
f0101afc:	89 3c 24             	mov    %edi,(%esp)
f0101aff:	e8 95 f7 ff ff       	call   f0101299 <page_free>
	page_free(pp2);
f0101b04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b07:	89 04 24             	mov    %eax,(%esp)
f0101b0a:	e8 8a f7 ff ff       	call   f0101299 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101b0f:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101b14:	eb 05                	jmp    f0101b1b <mem_init+0x613>
		--nfree;
f0101b16:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101b19:	8b 00                	mov    (%eax),%eax
f0101b1b:	85 c0                	test   %eax,%eax
f0101b1d:	75 f7                	jne    f0101b16 <mem_init+0x60e>
		--nfree;
	assert(nfree == 0);
f0101b1f:	85 db                	test   %ebx,%ebx
f0101b21:	74 24                	je     f0101b47 <mem_init+0x63f>
f0101b23:	c7 44 24 0c 07 50 10 	movl   $0xf0105007,0xc(%esp)
f0101b2a:	f0 
f0101b2b:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101b32:	f0 
f0101b33:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f0101b3a:	00 
f0101b3b:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101b42:	e8 4d e5 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101b47:	c7 04 24 b0 48 10 f0 	movl   $0xf01048b0,(%esp)
f0101b4e:	e8 e1 14 00 00       	call   f0103034 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b53:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b5a:	e8 af f6 ff ff       	call   f010120e <page_alloc>
f0101b5f:	89 c6                	mov    %eax,%esi
f0101b61:	85 c0                	test   %eax,%eax
f0101b63:	75 24                	jne    f0101b89 <mem_init+0x681>
f0101b65:	c7 44 24 0c 15 4f 10 	movl   $0xf0104f15,0xc(%esp)
f0101b6c:	f0 
f0101b6d:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101b74:	f0 
f0101b75:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f0101b7c:	00 
f0101b7d:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101b84:	e8 0b e5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b89:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b90:	e8 79 f6 ff ff       	call   f010120e <page_alloc>
f0101b95:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b98:	85 c0                	test   %eax,%eax
f0101b9a:	75 24                	jne    f0101bc0 <mem_init+0x6b8>
f0101b9c:	c7 44 24 0c 2b 4f 10 	movl   $0xf0104f2b,0xc(%esp)
f0101ba3:	f0 
f0101ba4:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101bab:	f0 
f0101bac:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0101bb3:	00 
f0101bb4:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101bbb:	e8 d4 e4 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101bc0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bc7:	e8 42 f6 ff ff       	call   f010120e <page_alloc>
f0101bcc:	89 c3                	mov    %eax,%ebx
f0101bce:	85 c0                	test   %eax,%eax
f0101bd0:	75 24                	jne    f0101bf6 <mem_init+0x6ee>
f0101bd2:	c7 44 24 0c 41 4f 10 	movl   $0xf0104f41,0xc(%esp)
f0101bd9:	f0 
f0101bda:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101be1:	f0 
f0101be2:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0101be9:	00 
f0101bea:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101bf1:	e8 9e e4 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101bf6:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101bf9:	75 24                	jne    f0101c1f <mem_init+0x717>
f0101bfb:	c7 44 24 0c 57 4f 10 	movl   $0xf0104f57,0xc(%esp)
f0101c02:	f0 
f0101c03:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101c0a:	f0 
f0101c0b:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0101c12:	00 
f0101c13:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101c1a:	e8 75 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c1f:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101c22:	74 04                	je     f0101c28 <mem_init+0x720>
f0101c24:	39 c6                	cmp    %eax,%esi
f0101c26:	75 24                	jne    f0101c4c <mem_init+0x744>
f0101c28:	c7 44 24 0c 90 48 10 	movl   $0xf0104890,0xc(%esp)
f0101c2f:	f0 
f0101c30:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101c37:	f0 
f0101c38:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f0101c3f:	00 
f0101c40:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101c47:	e8 48 e4 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101c4c:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101c51:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101c54:	c7 05 3c 85 11 f0 00 	movl   $0x0,0xf011853c
f0101c5b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101c5e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c65:	e8 a4 f5 ff ff       	call   f010120e <page_alloc>
f0101c6a:	85 c0                	test   %eax,%eax
f0101c6c:	74 24                	je     f0101c92 <mem_init+0x78a>
f0101c6e:	c7 44 24 0c c0 4f 10 	movl   $0xf0104fc0,0xc(%esp)
f0101c75:	f0 
f0101c76:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101c7d:	f0 
f0101c7e:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101c85:	00 
f0101c86:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101c8d:	e8 02 e4 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101c92:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101c95:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c99:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101ca0:	00 
f0101ca1:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101ca6:	89 04 24             	mov    %eax,(%esp)
f0101ca9:	e8 1a f7 ff ff       	call   f01013c8 <page_lookup>
f0101cae:	85 c0                	test   %eax,%eax
f0101cb0:	74 24                	je     f0101cd6 <mem_init+0x7ce>
f0101cb2:	c7 44 24 0c d0 48 10 	movl   $0xf01048d0,0xc(%esp)
f0101cb9:	f0 
f0101cba:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101cc1:	f0 
f0101cc2:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101cc9:	00 
f0101cca:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101cd1:	e8 be e3 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101cd6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cdd:	00 
f0101cde:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ce5:	00 
f0101ce6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ce9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ced:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101cf2:	89 04 24             	mov    %eax,(%esp)
f0101cf5:	e8 8d f7 ff ff       	call   f0101487 <page_insert>
f0101cfa:	85 c0                	test   %eax,%eax
f0101cfc:	78 24                	js     f0101d22 <mem_init+0x81a>
f0101cfe:	c7 44 24 0c 08 49 10 	movl   $0xf0104908,0xc(%esp)
f0101d05:	f0 
f0101d06:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101d0d:	f0 
f0101d0e:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101d15:	00 
f0101d16:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101d1d:	e8 72 e3 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101d22:	89 34 24             	mov    %esi,(%esp)
f0101d25:	e8 6f f5 ff ff       	call   f0101299 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101d2a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d31:	00 
f0101d32:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d39:	00 
f0101d3a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101d41:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101d46:	89 04 24             	mov    %eax,(%esp)
f0101d49:	e8 39 f7 ff ff       	call   f0101487 <page_insert>
f0101d4e:	85 c0                	test   %eax,%eax
f0101d50:	74 24                	je     f0101d76 <mem_init+0x86e>
f0101d52:	c7 44 24 0c 38 49 10 	movl   $0xf0104938,0xc(%esp)
f0101d59:	f0 
f0101d5a:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101d61:	f0 
f0101d62:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101d69:	00 
f0101d6a:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101d71:	e8 1e e3 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101d76:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101d7c:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0101d81:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d84:	8b 17                	mov    (%edi),%edx
f0101d86:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d8c:	89 f1                	mov    %esi,%ecx
f0101d8e:	29 c1                	sub    %eax,%ecx
f0101d90:	89 c8                	mov    %ecx,%eax
f0101d92:	c1 f8 03             	sar    $0x3,%eax
f0101d95:	c1 e0 0c             	shl    $0xc,%eax
f0101d98:	39 c2                	cmp    %eax,%edx
f0101d9a:	74 24                	je     f0101dc0 <mem_init+0x8b8>
f0101d9c:	c7 44 24 0c 68 49 10 	movl   $0xf0104968,0xc(%esp)
f0101da3:	f0 
f0101da4:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101dab:	f0 
f0101dac:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101db3:	00 
f0101db4:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101dbb:	e8 d4 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101dc0:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dc5:	89 f8                	mov    %edi,%eax
f0101dc7:	e8 e5 ef ff ff       	call   f0100db1 <check_va2pa>
f0101dcc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101dcf:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101dd2:	c1 fa 03             	sar    $0x3,%edx
f0101dd5:	c1 e2 0c             	shl    $0xc,%edx
f0101dd8:	39 d0                	cmp    %edx,%eax
f0101dda:	74 24                	je     f0101e00 <mem_init+0x8f8>
f0101ddc:	c7 44 24 0c 90 49 10 	movl   $0xf0104990,0xc(%esp)
f0101de3:	f0 
f0101de4:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101deb:	f0 
f0101dec:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101df3:	00 
f0101df4:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101dfb:	e8 94 e2 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101e00:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e03:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e08:	74 24                	je     f0101e2e <mem_init+0x926>
f0101e0a:	c7 44 24 0c 12 50 10 	movl   $0xf0105012,0xc(%esp)
f0101e11:	f0 
f0101e12:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101e19:	f0 
f0101e1a:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101e21:	00 
f0101e22:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101e29:	e8 66 e2 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101e2e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e33:	74 24                	je     f0101e59 <mem_init+0x951>
f0101e35:	c7 44 24 0c 23 50 10 	movl   $0xf0105023,0xc(%esp)
f0101e3c:	f0 
f0101e3d:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101e44:	f0 
f0101e45:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0101e4c:	00 
f0101e4d:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101e54:	e8 3b e2 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e59:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e60:	00 
f0101e61:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e68:	00 
f0101e69:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e6d:	89 3c 24             	mov    %edi,(%esp)
f0101e70:	e8 12 f6 ff ff       	call   f0101487 <page_insert>
f0101e75:	85 c0                	test   %eax,%eax
f0101e77:	74 24                	je     f0101e9d <mem_init+0x995>
f0101e79:	c7 44 24 0c c0 49 10 	movl   $0xf01049c0,0xc(%esp)
f0101e80:	f0 
f0101e81:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101e88:	f0 
f0101e89:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101e90:	00 
f0101e91:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101e98:	e8 f7 e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e9d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ea2:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101ea7:	e8 05 ef ff ff       	call   f0100db1 <check_va2pa>
f0101eac:	89 da                	mov    %ebx,%edx
f0101eae:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101eb4:	c1 fa 03             	sar    $0x3,%edx
f0101eb7:	c1 e2 0c             	shl    $0xc,%edx
f0101eba:	39 d0                	cmp    %edx,%eax
f0101ebc:	74 24                	je     f0101ee2 <mem_init+0x9da>
f0101ebe:	c7 44 24 0c fc 49 10 	movl   $0xf01049fc,0xc(%esp)
f0101ec5:	f0 
f0101ec6:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101ecd:	f0 
f0101ece:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f0101ed5:	00 
f0101ed6:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101edd:	e8 b2 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ee2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ee7:	74 24                	je     f0101f0d <mem_init+0xa05>
f0101ee9:	c7 44 24 0c 34 50 10 	movl   $0xf0105034,0xc(%esp)
f0101ef0:	f0 
f0101ef1:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101ef8:	f0 
f0101ef9:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0101f00:	00 
f0101f01:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101f08:	e8 87 e1 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f0d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f14:	e8 f5 f2 ff ff       	call   f010120e <page_alloc>
f0101f19:	85 c0                	test   %eax,%eax
f0101f1b:	74 24                	je     f0101f41 <mem_init+0xa39>
f0101f1d:	c7 44 24 0c c0 4f 10 	movl   $0xf0104fc0,0xc(%esp)
f0101f24:	f0 
f0101f25:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101f2c:	f0 
f0101f2d:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0101f34:	00 
f0101f35:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101f3c:	e8 53 e1 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f41:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f48:	00 
f0101f49:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f50:	00 
f0101f51:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101f55:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101f5a:	89 04 24             	mov    %eax,(%esp)
f0101f5d:	e8 25 f5 ff ff       	call   f0101487 <page_insert>
f0101f62:	85 c0                	test   %eax,%eax
f0101f64:	74 24                	je     f0101f8a <mem_init+0xa82>
f0101f66:	c7 44 24 0c c0 49 10 	movl   $0xf01049c0,0xc(%esp)
f0101f6d:	f0 
f0101f6e:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101f75:	f0 
f0101f76:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101f7d:	00 
f0101f7e:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101f85:	e8 0a e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f8a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f8f:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101f94:	e8 18 ee ff ff       	call   f0100db1 <check_va2pa>
f0101f99:	89 da                	mov    %ebx,%edx
f0101f9b:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101fa1:	c1 fa 03             	sar    $0x3,%edx
f0101fa4:	c1 e2 0c             	shl    $0xc,%edx
f0101fa7:	39 d0                	cmp    %edx,%eax
f0101fa9:	74 24                	je     f0101fcf <mem_init+0xac7>
f0101fab:	c7 44 24 0c fc 49 10 	movl   $0xf01049fc,0xc(%esp)
f0101fb2:	f0 
f0101fb3:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101fba:	f0 
f0101fbb:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101fc2:	00 
f0101fc3:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101fca:	e8 c5 e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101fcf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101fd4:	74 24                	je     f0101ffa <mem_init+0xaf2>
f0101fd6:	c7 44 24 0c 34 50 10 	movl   $0xf0105034,0xc(%esp)
f0101fdd:	f0 
f0101fde:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0101fe5:	f0 
f0101fe6:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101fed:	00 
f0101fee:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0101ff5:	e8 9a e0 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ffa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102001:	e8 08 f2 ff ff       	call   f010120e <page_alloc>
f0102006:	85 c0                	test   %eax,%eax
f0102008:	74 24                	je     f010202e <mem_init+0xb26>
f010200a:	c7 44 24 0c c0 4f 10 	movl   $0xf0104fc0,0xc(%esp)
f0102011:	f0 
f0102012:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102019:	f0 
f010201a:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0102021:	00 
f0102022:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102029:	e8 66 e0 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010202e:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f0102034:	8b 02                	mov    (%edx),%eax
f0102036:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010203b:	89 c1                	mov    %eax,%ecx
f010203d:	c1 e9 0c             	shr    $0xc,%ecx
f0102040:	3b 0d 64 89 11 f0    	cmp    0xf0118964,%ecx
f0102046:	72 20                	jb     f0102068 <mem_init+0xb60>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102048:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010204c:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f0102053:	f0 
f0102054:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f010205b:	00 
f010205c:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102063:	e8 2c e0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102068:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010206d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102070:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102077:	00 
f0102078:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010207f:	00 
f0102080:	89 14 24             	mov    %edx,(%esp)
f0102083:	e8 49 f2 ff ff       	call   f01012d1 <pgdir_walk>
f0102088:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010208b:	8d 51 04             	lea    0x4(%ecx),%edx
f010208e:	39 d0                	cmp    %edx,%eax
f0102090:	74 24                	je     f01020b6 <mem_init+0xbae>
f0102092:	c7 44 24 0c 2c 4a 10 	movl   $0xf0104a2c,0xc(%esp)
f0102099:	f0 
f010209a:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01020a1:	f0 
f01020a2:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f01020a9:	00 
f01020aa:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01020b1:	e8 de df ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01020b6:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01020bd:	00 
f01020be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020c5:	00 
f01020c6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01020ca:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01020cf:	89 04 24             	mov    %eax,(%esp)
f01020d2:	e8 b0 f3 ff ff       	call   f0101487 <page_insert>
f01020d7:	85 c0                	test   %eax,%eax
f01020d9:	74 24                	je     f01020ff <mem_init+0xbf7>
f01020db:	c7 44 24 0c 6c 4a 10 	movl   $0xf0104a6c,0xc(%esp)
f01020e2:	f0 
f01020e3:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01020ea:	f0 
f01020eb:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f01020f2:	00 
f01020f3:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01020fa:	e8 95 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01020ff:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f0102105:	ba 00 10 00 00       	mov    $0x1000,%edx
f010210a:	89 f8                	mov    %edi,%eax
f010210c:	e8 a0 ec ff ff       	call   f0100db1 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102111:	89 da                	mov    %ebx,%edx
f0102113:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102119:	c1 fa 03             	sar    $0x3,%edx
f010211c:	c1 e2 0c             	shl    $0xc,%edx
f010211f:	39 d0                	cmp    %edx,%eax
f0102121:	74 24                	je     f0102147 <mem_init+0xc3f>
f0102123:	c7 44 24 0c fc 49 10 	movl   $0xf01049fc,0xc(%esp)
f010212a:	f0 
f010212b:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102132:	f0 
f0102133:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f010213a:	00 
f010213b:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102142:	e8 4d df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102147:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010214c:	74 24                	je     f0102172 <mem_init+0xc6a>
f010214e:	c7 44 24 0c 34 50 10 	movl   $0xf0105034,0xc(%esp)
f0102155:	f0 
f0102156:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f010215d:	f0 
f010215e:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0102165:	00 
f0102166:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010216d:	e8 22 df ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102172:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102179:	00 
f010217a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102181:	00 
f0102182:	89 3c 24             	mov    %edi,(%esp)
f0102185:	e8 47 f1 ff ff       	call   f01012d1 <pgdir_walk>
f010218a:	f6 00 04             	testb  $0x4,(%eax)
f010218d:	75 24                	jne    f01021b3 <mem_init+0xcab>
f010218f:	c7 44 24 0c ac 4a 10 	movl   $0xf0104aac,0xc(%esp)
f0102196:	f0 
f0102197:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f010219e:	f0 
f010219f:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f01021a6:	00 
f01021a7:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01021ae:	e8 e1 de ff ff       	call   f0100094 <_panic>
	//cprintf("pp2 %x\n", pp2);
	//cprintf("kern_pgdir %x\n", kern_pgdir);
	//cprintf("kern_pgdir[0] is %x\n", kern_pgdir[0]);
	assert(kern_pgdir[0] & PTE_U);
f01021b3:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01021b8:	f6 00 04             	testb  $0x4,(%eax)
f01021bb:	75 24                	jne    f01021e1 <mem_init+0xcd9>
f01021bd:	c7 44 24 0c 45 50 10 	movl   $0xf0105045,0xc(%esp)
f01021c4:	f0 
f01021c5:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01021cc:	f0 
f01021cd:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f01021d4:	00 
f01021d5:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01021dc:	e8 b3 de ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01021e1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021e8:	00 
f01021e9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021f0:	00 
f01021f1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01021f5:	89 04 24             	mov    %eax,(%esp)
f01021f8:	e8 8a f2 ff ff       	call   f0101487 <page_insert>
f01021fd:	85 c0                	test   %eax,%eax
f01021ff:	74 24                	je     f0102225 <mem_init+0xd1d>
f0102201:	c7 44 24 0c c0 49 10 	movl   $0xf01049c0,0xc(%esp)
f0102208:	f0 
f0102209:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102210:	f0 
f0102211:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0102218:	00 
f0102219:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102220:	e8 6f de ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102225:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010222c:	00 
f010222d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102234:	00 
f0102235:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010223a:	89 04 24             	mov    %eax,(%esp)
f010223d:	e8 8f f0 ff ff       	call   f01012d1 <pgdir_walk>
f0102242:	f6 00 02             	testb  $0x2,(%eax)
f0102245:	75 24                	jne    f010226b <mem_init+0xd63>
f0102247:	c7 44 24 0c e0 4a 10 	movl   $0xf0104ae0,0xc(%esp)
f010224e:	f0 
f010224f:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102256:	f0 
f0102257:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f010225e:	00 
f010225f:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102266:	e8 29 de ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010226b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102272:	00 
f0102273:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010227a:	00 
f010227b:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102280:	89 04 24             	mov    %eax,(%esp)
f0102283:	e8 49 f0 ff ff       	call   f01012d1 <pgdir_walk>
f0102288:	f6 00 04             	testb  $0x4,(%eax)
f010228b:	74 24                	je     f01022b1 <mem_init+0xda9>
f010228d:	c7 44 24 0c 14 4b 10 	movl   $0xf0104b14,0xc(%esp)
f0102294:	f0 
f0102295:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f010229c:	f0 
f010229d:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f01022a4:	00 
f01022a5:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01022ac:	e8 e3 dd ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01022b1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022b8:	00 
f01022b9:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01022c0:	00 
f01022c1:	89 74 24 04          	mov    %esi,0x4(%esp)
f01022c5:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01022ca:	89 04 24             	mov    %eax,(%esp)
f01022cd:	e8 b5 f1 ff ff       	call   f0101487 <page_insert>
f01022d2:	85 c0                	test   %eax,%eax
f01022d4:	78 24                	js     f01022fa <mem_init+0xdf2>
f01022d6:	c7 44 24 0c 4c 4b 10 	movl   $0xf0104b4c,0xc(%esp)
f01022dd:	f0 
f01022de:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01022e5:	f0 
f01022e6:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f01022ed:	00 
f01022ee:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01022f5:	e8 9a dd ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01022fa:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102301:	00 
f0102302:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102309:	00 
f010230a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010230d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102311:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102316:	89 04 24             	mov    %eax,(%esp)
f0102319:	e8 69 f1 ff ff       	call   f0101487 <page_insert>
f010231e:	85 c0                	test   %eax,%eax
f0102320:	74 24                	je     f0102346 <mem_init+0xe3e>
f0102322:	c7 44 24 0c 84 4b 10 	movl   $0xf0104b84,0xc(%esp)
f0102329:	f0 
f010232a:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102331:	f0 
f0102332:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0102339:	00 
f010233a:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102341:	e8 4e dd ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102346:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010234d:	00 
f010234e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102355:	00 
f0102356:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010235b:	89 04 24             	mov    %eax,(%esp)
f010235e:	e8 6e ef ff ff       	call   f01012d1 <pgdir_walk>
f0102363:	f6 00 04             	testb  $0x4,(%eax)
f0102366:	74 24                	je     f010238c <mem_init+0xe84>
f0102368:	c7 44 24 0c 14 4b 10 	movl   $0xf0104b14,0xc(%esp)
f010236f:	f0 
f0102370:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102377:	f0 
f0102378:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f010237f:	00 
f0102380:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102387:	e8 08 dd ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010238c:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f0102392:	ba 00 00 00 00       	mov    $0x0,%edx
f0102397:	89 f8                	mov    %edi,%eax
f0102399:	e8 13 ea ff ff       	call   f0100db1 <check_va2pa>
f010239e:	89 c1                	mov    %eax,%ecx
f01023a0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01023a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023a6:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f01023ac:	c1 f8 03             	sar    $0x3,%eax
f01023af:	c1 e0 0c             	shl    $0xc,%eax
f01023b2:	39 c1                	cmp    %eax,%ecx
f01023b4:	74 24                	je     f01023da <mem_init+0xed2>
f01023b6:	c7 44 24 0c c0 4b 10 	movl   $0xf0104bc0,0xc(%esp)
f01023bd:	f0 
f01023be:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01023c5:	f0 
f01023c6:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f01023cd:	00 
f01023ce:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01023d5:	e8 ba dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01023da:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023df:	89 f8                	mov    %edi,%eax
f01023e1:	e8 cb e9 ff ff       	call   f0100db1 <check_va2pa>
f01023e6:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01023e9:	74 24                	je     f010240f <mem_init+0xf07>
f01023eb:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f01023f2:	f0 
f01023f3:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01023fa:	f0 
f01023fb:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0102402:	00 
f0102403:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010240a:	e8 85 dc ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010240f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102412:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0102417:	74 24                	je     f010243d <mem_init+0xf35>
f0102419:	c7 44 24 0c 5b 50 10 	movl   $0xf010505b,0xc(%esp)
f0102420:	f0 
f0102421:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102428:	f0 
f0102429:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0102430:	00 
f0102431:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102438:	e8 57 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010243d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102442:	74 24                	je     f0102468 <mem_init+0xf60>
f0102444:	c7 44 24 0c 6c 50 10 	movl   $0xf010506c,0xc(%esp)
f010244b:	f0 
f010244c:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102453:	f0 
f0102454:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f010245b:	00 
f010245c:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102463:	e8 2c dc ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102468:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010246f:	e8 9a ed ff ff       	call   f010120e <page_alloc>
f0102474:	85 c0                	test   %eax,%eax
f0102476:	74 04                	je     f010247c <mem_init+0xf74>
f0102478:	39 c3                	cmp    %eax,%ebx
f010247a:	74 24                	je     f01024a0 <mem_init+0xf98>
f010247c:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f0102483:	f0 
f0102484:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f010248b:	f0 
f010248c:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0102493:	00 
f0102494:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010249b:	e8 f4 db ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01024a0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024a7:	00 
f01024a8:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01024ad:	89 04 24             	mov    %eax,(%esp)
f01024b0:	e8 8d ef ff ff       	call   f0101442 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01024b5:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f01024bb:	ba 00 00 00 00       	mov    $0x0,%edx
f01024c0:	89 f8                	mov    %edi,%eax
f01024c2:	e8 ea e8 ff ff       	call   f0100db1 <check_va2pa>
f01024c7:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024ca:	74 24                	je     f01024f0 <mem_init+0xfe8>
f01024cc:	c7 44 24 0c 40 4c 10 	movl   $0xf0104c40,0xc(%esp)
f01024d3:	f0 
f01024d4:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01024db:	f0 
f01024dc:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f01024e3:	00 
f01024e4:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01024eb:	e8 a4 db ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01024f0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024f5:	89 f8                	mov    %edi,%eax
f01024f7:	e8 b5 e8 ff ff       	call   f0100db1 <check_va2pa>
f01024fc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01024ff:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102505:	c1 fa 03             	sar    $0x3,%edx
f0102508:	c1 e2 0c             	shl    $0xc,%edx
f010250b:	39 d0                	cmp    %edx,%eax
f010250d:	74 24                	je     f0102533 <mem_init+0x102b>
f010250f:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f0102516:	f0 
f0102517:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f010251e:	f0 
f010251f:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0102526:	00 
f0102527:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010252e:	e8 61 db ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102533:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102536:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010253b:	74 24                	je     f0102561 <mem_init+0x1059>
f010253d:	c7 44 24 0c 12 50 10 	movl   $0xf0105012,0xc(%esp)
f0102544:	f0 
f0102545:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f010254c:	f0 
f010254d:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102554:	00 
f0102555:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010255c:	e8 33 db ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102561:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102566:	74 24                	je     f010258c <mem_init+0x1084>
f0102568:	c7 44 24 0c 6c 50 10 	movl   $0xf010506c,0xc(%esp)
f010256f:	f0 
f0102570:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102577:	f0 
f0102578:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f010257f:	00 
f0102580:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102587:	e8 08 db ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010258c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102593:	00 
f0102594:	89 3c 24             	mov    %edi,(%esp)
f0102597:	e8 a6 ee ff ff       	call   f0101442 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010259c:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f01025a2:	ba 00 00 00 00       	mov    $0x0,%edx
f01025a7:	89 f8                	mov    %edi,%eax
f01025a9:	e8 03 e8 ff ff       	call   f0100db1 <check_va2pa>
f01025ae:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025b1:	74 24                	je     f01025d7 <mem_init+0x10cf>
f01025b3:	c7 44 24 0c 40 4c 10 	movl   $0xf0104c40,0xc(%esp)
f01025ba:	f0 
f01025bb:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01025c2:	f0 
f01025c3:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f01025ca:	00 
f01025cb:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01025d2:	e8 bd da ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01025d7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01025dc:	89 f8                	mov    %edi,%eax
f01025de:	e8 ce e7 ff ff       	call   f0100db1 <check_va2pa>
f01025e3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025e6:	74 24                	je     f010260c <mem_init+0x1104>
f01025e8:	c7 44 24 0c 64 4c 10 	movl   $0xf0104c64,0xc(%esp)
f01025ef:	f0 
f01025f0:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01025f7:	f0 
f01025f8:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01025ff:	00 
f0102600:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102607:	e8 88 da ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010260c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010260f:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102614:	74 24                	je     f010263a <mem_init+0x1132>
f0102616:	c7 44 24 0c 7d 50 10 	movl   $0xf010507d,0xc(%esp)
f010261d:	f0 
f010261e:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102625:	f0 
f0102626:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f010262d:	00 
f010262e:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102635:	e8 5a da ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010263a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010263f:	74 24                	je     f0102665 <mem_init+0x115d>
f0102641:	c7 44 24 0c 6c 50 10 	movl   $0xf010506c,0xc(%esp)
f0102648:	f0 
f0102649:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102650:	f0 
f0102651:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0102658:	00 
f0102659:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102660:	e8 2f da ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102665:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010266c:	e8 9d eb ff ff       	call   f010120e <page_alloc>
f0102671:	85 c0                	test   %eax,%eax
f0102673:	74 05                	je     f010267a <mem_init+0x1172>
f0102675:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0102678:	74 24                	je     f010269e <mem_init+0x1196>
f010267a:	c7 44 24 0c 8c 4c 10 	movl   $0xf0104c8c,0xc(%esp)
f0102681:	f0 
f0102682:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102689:	f0 
f010268a:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0102691:	00 
f0102692:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102699:	e8 f6 d9 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010269e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026a5:	e8 64 eb ff ff       	call   f010120e <page_alloc>
f01026aa:	85 c0                	test   %eax,%eax
f01026ac:	74 24                	je     f01026d2 <mem_init+0x11ca>
f01026ae:	c7 44 24 0c c0 4f 10 	movl   $0xf0104fc0,0xc(%esp)
f01026b5:	f0 
f01026b6:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01026bd:	f0 
f01026be:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01026c5:	00 
f01026c6:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01026cd:	e8 c2 d9 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026d2:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01026d7:	8b 08                	mov    (%eax),%ecx
f01026d9:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01026df:	89 f2                	mov    %esi,%edx
f01026e1:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f01026e7:	c1 fa 03             	sar    $0x3,%edx
f01026ea:	c1 e2 0c             	shl    $0xc,%edx
f01026ed:	39 d1                	cmp    %edx,%ecx
f01026ef:	74 24                	je     f0102715 <mem_init+0x120d>
f01026f1:	c7 44 24 0c 68 49 10 	movl   $0xf0104968,0xc(%esp)
f01026f8:	f0 
f01026f9:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102700:	f0 
f0102701:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102708:	00 
f0102709:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102710:	e8 7f d9 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102715:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010271b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102720:	74 24                	je     f0102746 <mem_init+0x123e>
f0102722:	c7 44 24 0c 23 50 10 	movl   $0xf0105023,0xc(%esp)
f0102729:	f0 
f010272a:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102731:	f0 
f0102732:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0102739:	00 
f010273a:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102741:	e8 4e d9 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102746:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010274c:	89 34 24             	mov    %esi,(%esp)
f010274f:	e8 45 eb ff ff       	call   f0101299 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102754:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010275b:	00 
f010275c:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102763:	00 
f0102764:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102769:	89 04 24             	mov    %eax,(%esp)
f010276c:	e8 60 eb ff ff       	call   f01012d1 <pgdir_walk>
f0102771:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102774:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102777:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f010277d:	8b 7a 04             	mov    0x4(%edx),%edi
f0102780:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102786:	8b 0d 64 89 11 f0    	mov    0xf0118964,%ecx
f010278c:	89 f8                	mov    %edi,%eax
f010278e:	c1 e8 0c             	shr    $0xc,%eax
f0102791:	39 c8                	cmp    %ecx,%eax
f0102793:	72 20                	jb     f01027b5 <mem_init+0x12ad>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102795:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102799:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f01027a0:	f0 
f01027a1:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f01027a8:	00 
f01027a9:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01027b0:	e8 df d8 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01027b5:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01027bb:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f01027be:	74 24                	je     f01027e4 <mem_init+0x12dc>
f01027c0:	c7 44 24 0c 8e 50 10 	movl   $0xf010508e,0xc(%esp)
f01027c7:	f0 
f01027c8:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01027cf:	f0 
f01027d0:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f01027d7:	00 
f01027d8:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01027df:	e8 b0 d8 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01027e4:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01027eb:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027f1:	89 f0                	mov    %esi,%eax
f01027f3:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f01027f9:	c1 f8 03             	sar    $0x3,%eax
f01027fc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027ff:	89 c2                	mov    %eax,%edx
f0102801:	c1 ea 0c             	shr    $0xc,%edx
f0102804:	39 d1                	cmp    %edx,%ecx
f0102806:	77 20                	ja     f0102828 <mem_init+0x1320>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102808:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010280c:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f0102813:	f0 
f0102814:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010281b:	00 
f010281c:	c7 04 24 44 4e 10 f0 	movl   $0xf0104e44,(%esp)
f0102823:	e8 6c d8 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102828:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010282f:	00 
f0102830:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102837:	00 
	return (void *)(pa + KERNBASE);
f0102838:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010283d:	89 04 24             	mov    %eax,(%esp)
f0102840:	e8 52 13 00 00       	call   f0103b97 <memset>
	page_free(pp0);
f0102845:	89 34 24             	mov    %esi,(%esp)
f0102848:	e8 4c ea ff ff       	call   f0101299 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010284d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102854:	00 
f0102855:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010285c:	00 
f010285d:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102862:	89 04 24             	mov    %eax,(%esp)
f0102865:	e8 67 ea ff ff       	call   f01012d1 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010286a:	89 f2                	mov    %esi,%edx
f010286c:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102872:	c1 fa 03             	sar    $0x3,%edx
f0102875:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102878:	89 d0                	mov    %edx,%eax
f010287a:	c1 e8 0c             	shr    $0xc,%eax
f010287d:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0102883:	72 20                	jb     f01028a5 <mem_init+0x139d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102885:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102889:	c7 44 24 08 04 47 10 	movl   $0xf0104704,0x8(%esp)
f0102890:	f0 
f0102891:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102898:	00 
f0102899:	c7 04 24 44 4e 10 f0 	movl   $0xf0104e44,(%esp)
f01028a0:	e8 ef d7 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01028a5:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01028ab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01028ae:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01028b4:	f6 00 01             	testb  $0x1,(%eax)
f01028b7:	74 24                	je     f01028dd <mem_init+0x13d5>
f01028b9:	c7 44 24 0c a6 50 10 	movl   $0xf01050a6,0xc(%esp)
f01028c0:	f0 
f01028c1:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f01028c8:	f0 
f01028c9:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f01028d0:	00 
f01028d1:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f01028d8:	e8 b7 d7 ff ff       	call   f0100094 <_panic>
f01028dd:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01028e0:	39 d0                	cmp    %edx,%eax
f01028e2:	75 d0                	jne    f01028b4 <mem_init+0x13ac>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01028e4:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01028e9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01028ef:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f01028f5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01028f8:	a3 3c 85 11 f0       	mov    %eax,0xf011853c

	// free the pages we took
	page_free(pp0);
f01028fd:	89 34 24             	mov    %esi,(%esp)
f0102900:	e8 94 e9 ff ff       	call   f0101299 <page_free>
	page_free(pp1);
f0102905:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102908:	89 04 24             	mov    %eax,(%esp)
f010290b:	e8 89 e9 ff ff       	call   f0101299 <page_free>
	page_free(pp2);
f0102910:	89 1c 24             	mov    %ebx,(%esp)
f0102913:	e8 81 e9 ff ff       	call   f0101299 <page_free>

	cprintf("check_page() succeeded!\n");
f0102918:	c7 04 24 bd 50 10 f0 	movl   $0xf01050bd,(%esp)
f010291f:	e8 10 07 00 00       	call   f0103034 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, 
f0102924:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102929:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010292e:	77 20                	ja     f0102950 <mem_init+0x1448>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102930:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102934:	c7 44 24 08 6c 48 10 	movl   $0xf010486c,0x8(%esp)
f010293b:	f0 
f010293c:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
f0102943:	00 
f0102944:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010294b:	e8 44 d7 ff ff       	call   f0100094 <_panic>
f0102950:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102957:	00 
	return (physaddr_t)kva - KERNBASE;
f0102958:	05 00 00 00 10       	add    $0x10000000,%eax
f010295d:	89 04 24             	mov    %eax,(%esp)
f0102960:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102965:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010296a:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010296f:	e8 fd e9 ff ff       	call   f0101371 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102974:	bb 00 e0 10 f0       	mov    $0xf010e000,%ebx
f0102979:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010297f:	77 20                	ja     f01029a1 <mem_init+0x1499>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102981:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102985:	c7 44 24 08 6c 48 10 	movl   $0xf010486c,0x8(%esp)
f010298c:	f0 
f010298d:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
f0102994:	00 
f0102995:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f010299c:	e8 f3 d6 ff ff       	call   f0100094 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, 
f01029a1:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01029a8:	00 
f01029a9:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f01029b0:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01029b5:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01029ba:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01029bf:	e8 ad e9 ff ff       	call   f0101371 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, 
f01029c4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01029cb:	00 
f01029cc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029d3:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01029d8:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01029dd:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01029e2:	e8 8a e9 ff ff       	call   f0101371 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01029e7:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01029ed:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f01029f2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01029f5:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01029fc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102a01:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a04:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0102a09:	89 45 cc             	mov    %eax,-0x34(%ebp)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a0c:	89 45 c8             	mov    %eax,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102a0f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a14:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102a17:	be 00 00 00 00       	mov    $0x0,%esi
f0102a1c:	eb 6d                	jmp    f0102a8b <mem_init+0x1583>
f0102a1e:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a24:	89 f8                	mov    %edi,%eax
f0102a26:	e8 86 e3 ff ff       	call   f0100db1 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a2b:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102a32:	77 23                	ja     f0102a57 <mem_init+0x154f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a34:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102a37:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a3b:	c7 44 24 08 6c 48 10 	movl   $0xf010486c,0x8(%esp)
f0102a42:	f0 
f0102a43:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f0102a4a:	00 
f0102a4b:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102a52:	e8 3d d6 ff ff       	call   f0100094 <_panic>
f0102a57:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102a5a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102a5d:	39 c2                	cmp    %eax,%edx
f0102a5f:	74 24                	je     f0102a85 <mem_init+0x157d>
f0102a61:	c7 44 24 0c b0 4c 10 	movl   $0xf0104cb0,0xc(%esp)
f0102a68:	f0 
f0102a69:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102a70:	f0 
f0102a71:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f0102a78:	00 
f0102a79:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102a80:	e8 0f d6 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102a85:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102a8b:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0102a8e:	77 8e                	ja     f0102a1e <mem_init+0x1516>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a90:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a93:	c1 e0 0c             	shl    $0xc,%eax
f0102a96:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a99:	be 00 00 00 00       	mov    $0x0,%esi
f0102a9e:	eb 3b                	jmp    f0102adb <mem_init+0x15d3>
f0102aa0:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102aa6:	89 f8                	mov    %edi,%eax
f0102aa8:	e8 04 e3 ff ff       	call   f0100db1 <check_va2pa>
f0102aad:	39 c6                	cmp    %eax,%esi
f0102aaf:	74 24                	je     f0102ad5 <mem_init+0x15cd>
f0102ab1:	c7 44 24 0c e4 4c 10 	movl   $0xf0104ce4,0xc(%esp)
f0102ab8:	f0 
f0102ab9:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102ac0:	f0 
f0102ac1:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f0102ac8:	00 
f0102ac9:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102ad0:	e8 bf d5 ff ff       	call   f0100094 <_panic>
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102ad5:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102adb:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0102ade:	72 c0                	jb     f0102aa0 <mem_init+0x1598>
f0102ae0:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102ae5:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102aeb:	89 f2                	mov    %esi,%edx
f0102aed:	89 f8                	mov    %edi,%eax
f0102aef:	e8 bd e2 ff ff       	call   f0100db1 <check_va2pa>
f0102af4:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102af7:	39 d0                	cmp    %edx,%eax
f0102af9:	74 24                	je     f0102b1f <mem_init+0x1617>
f0102afb:	c7 44 24 0c 0c 4d 10 	movl   $0xf0104d0c,0xc(%esp)
f0102b02:	f0 
f0102b03:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102b0a:	f0 
f0102b0b:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f0102b12:	00 
f0102b13:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102b1a:	e8 75 d5 ff ff       	call   f0100094 <_panic>
f0102b1f:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102b25:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102b2b:	75 be                	jne    f0102aeb <mem_init+0x15e3>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b2d:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102b32:	89 f8                	mov    %edi,%eax
f0102b34:	e8 78 e2 ff ff       	call   f0100db1 <check_va2pa>
f0102b39:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102b3c:	75 0a                	jne    f0102b48 <mem_init+0x1640>
f0102b3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b43:	e9 f0 00 00 00       	jmp    f0102c38 <mem_init+0x1730>
f0102b48:	c7 44 24 0c 54 4d 10 	movl   $0xf0104d54,0xc(%esp)
f0102b4f:	f0 
f0102b50:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102b57:	f0 
f0102b58:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f0102b5f:	00 
f0102b60:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102b67:	e8 28 d5 ff ff       	call   f0100094 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102b6c:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102b71:	72 3c                	jb     f0102baf <mem_init+0x16a7>
f0102b73:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102b78:	76 07                	jbe    f0102b81 <mem_init+0x1679>
f0102b7a:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b7f:	75 2e                	jne    f0102baf <mem_init+0x16a7>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102b81:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102b85:	0f 85 aa 00 00 00    	jne    f0102c35 <mem_init+0x172d>
f0102b8b:	c7 44 24 0c d6 50 10 	movl   $0xf01050d6,0xc(%esp)
f0102b92:	f0 
f0102b93:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102b9a:	f0 
f0102b9b:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f0102ba2:	00 
f0102ba3:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102baa:	e8 e5 d4 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102baf:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102bb4:	76 55                	jbe    f0102c0b <mem_init+0x1703>
				assert(pgdir[i] & PTE_P);
f0102bb6:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102bb9:	f6 c2 01             	test   $0x1,%dl
f0102bbc:	75 24                	jne    f0102be2 <mem_init+0x16da>
f0102bbe:	c7 44 24 0c d6 50 10 	movl   $0xf01050d6,0xc(%esp)
f0102bc5:	f0 
f0102bc6:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102bcd:	f0 
f0102bce:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f0102bd5:	00 
f0102bd6:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102bdd:	e8 b2 d4 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102be2:	f6 c2 02             	test   $0x2,%dl
f0102be5:	75 4e                	jne    f0102c35 <mem_init+0x172d>
f0102be7:	c7 44 24 0c e7 50 10 	movl   $0xf01050e7,0xc(%esp)
f0102bee:	f0 
f0102bef:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102bf6:	f0 
f0102bf7:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f0102bfe:	00 
f0102bff:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102c06:	e8 89 d4 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102c0b:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102c0f:	74 24                	je     f0102c35 <mem_init+0x172d>
f0102c11:	c7 44 24 0c f8 50 10 	movl   $0xf01050f8,0xc(%esp)
f0102c18:	f0 
f0102c19:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102c20:	f0 
f0102c21:	c7 44 24 04 ce 02 00 	movl   $0x2ce,0x4(%esp)
f0102c28:	00 
f0102c29:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102c30:	e8 5f d4 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102c35:	83 c0 01             	add    $0x1,%eax
f0102c38:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102c3d:	0f 85 29 ff ff ff    	jne    f0102b6c <mem_init+0x1664>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102c43:	c7 04 24 84 4d 10 f0 	movl   $0xf0104d84,(%esp)
f0102c4a:	e8 e5 03 00 00       	call   f0103034 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102c4f:	a1 68 89 11 f0       	mov    0xf0118968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c54:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c59:	77 20                	ja     f0102c7b <mem_init+0x1773>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c5b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c5f:	c7 44 24 08 6c 48 10 	movl   $0xf010486c,0x8(%esp)
f0102c66:	f0 
f0102c67:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
f0102c6e:	00 
f0102c6f:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102c76:	e8 19 d4 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102c7b:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102c80:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102c83:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c88:	e8 93 e1 ff ff       	call   f0100e20 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102c8d:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c90:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c93:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102c98:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c9b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ca2:	e8 67 e5 ff ff       	call   f010120e <page_alloc>
f0102ca7:	89 c3                	mov    %eax,%ebx
f0102ca9:	85 c0                	test   %eax,%eax
f0102cab:	75 24                	jne    f0102cd1 <mem_init+0x17c9>
f0102cad:	c7 44 24 0c 15 4f 10 	movl   $0xf0104f15,0xc(%esp)
f0102cb4:	f0 
f0102cb5:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102cbc:	f0 
f0102cbd:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102cc4:	00 
f0102cc5:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102ccc:	e8 c3 d3 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102cd1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102cd8:	e8 31 e5 ff ff       	call   f010120e <page_alloc>
f0102cdd:	89 c7                	mov    %eax,%edi
f0102cdf:	85 c0                	test   %eax,%eax
f0102ce1:	75 24                	jne    f0102d07 <mem_init+0x17ff>
f0102ce3:	c7 44 24 0c 2b 4f 10 	movl   $0xf0104f2b,0xc(%esp)
f0102cea:	f0 
f0102ceb:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102cf2:	f0 
f0102cf3:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0102cfa:	00 
f0102cfb:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102d02:	e8 8d d3 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102d07:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102d0e:	e8 fb e4 ff ff       	call   f010120e <page_alloc>
f0102d13:	89 c6                	mov    %eax,%esi
f0102d15:	85 c0                	test   %eax,%eax
f0102d17:	75 24                	jne    f0102d3d <mem_init+0x1835>
f0102d19:	c7 44 24 0c 41 4f 10 	movl   $0xf0104f41,0xc(%esp)
f0102d20:	f0 
f0102d21:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102d28:	f0 
f0102d29:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0102d30:	00 
f0102d31:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102d38:	e8 57 d3 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102d3d:	89 1c 24             	mov    %ebx,(%esp)
f0102d40:	e8 54 e5 ff ff       	call   f0101299 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102d45:	89 f8                	mov    %edi,%eax
f0102d47:	e8 20 e0 ff ff       	call   f0100d6c <page2kva>
f0102d4c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d53:	00 
f0102d54:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102d5b:	00 
f0102d5c:	89 04 24             	mov    %eax,(%esp)
f0102d5f:	e8 33 0e 00 00       	call   f0103b97 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d64:	89 f0                	mov    %esi,%eax
f0102d66:	e8 01 e0 ff ff       	call   f0100d6c <page2kva>
f0102d6b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d72:	00 
f0102d73:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102d7a:	00 
f0102d7b:	89 04 24             	mov    %eax,(%esp)
f0102d7e:	e8 14 0e 00 00       	call   f0103b97 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d83:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102d8a:	00 
f0102d8b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d92:	00 
f0102d93:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102d97:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102d9c:	89 04 24             	mov    %eax,(%esp)
f0102d9f:	e8 e3 e6 ff ff       	call   f0101487 <page_insert>
	assert(pp1->pp_ref == 1);
f0102da4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102da9:	74 24                	je     f0102dcf <mem_init+0x18c7>
f0102dab:	c7 44 24 0c 12 50 10 	movl   $0xf0105012,0xc(%esp)
f0102db2:	f0 
f0102db3:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102dba:	f0 
f0102dbb:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102dc2:	00 
f0102dc3:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102dca:	e8 c5 d2 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102dcf:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102dd6:	01 01 01 
f0102dd9:	74 24                	je     f0102dff <mem_init+0x18f7>
f0102ddb:	c7 44 24 0c a4 4d 10 	movl   $0xf0104da4,0xc(%esp)
f0102de2:	f0 
f0102de3:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102dea:	f0 
f0102deb:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102df2:	00 
f0102df3:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102dfa:	e8 95 d2 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102dff:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102e06:	00 
f0102e07:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102e0e:	00 
f0102e0f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102e13:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102e18:	89 04 24             	mov    %eax,(%esp)
f0102e1b:	e8 67 e6 ff ff       	call   f0101487 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e20:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102e27:	02 02 02 
f0102e2a:	74 24                	je     f0102e50 <mem_init+0x1948>
f0102e2c:	c7 44 24 0c c8 4d 10 	movl   $0xf0104dc8,0xc(%esp)
f0102e33:	f0 
f0102e34:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102e3b:	f0 
f0102e3c:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102e43:	00 
f0102e44:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102e4b:	e8 44 d2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102e50:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e55:	74 24                	je     f0102e7b <mem_init+0x1973>
f0102e57:	c7 44 24 0c 34 50 10 	movl   $0xf0105034,0xc(%esp)
f0102e5e:	f0 
f0102e5f:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102e66:	f0 
f0102e67:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102e6e:	00 
f0102e6f:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102e76:	e8 19 d2 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102e7b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102e80:	74 24                	je     f0102ea6 <mem_init+0x199e>
f0102e82:	c7 44 24 0c 7d 50 10 	movl   $0xf010507d,0xc(%esp)
f0102e89:	f0 
f0102e8a:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102e91:	f0 
f0102e92:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f0102e99:	00 
f0102e9a:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102ea1:	e8 ee d1 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102ea6:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102ead:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102eb0:	89 f0                	mov    %esi,%eax
f0102eb2:	e8 b5 de ff ff       	call   f0100d6c <page2kva>
f0102eb7:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102ebd:	74 24                	je     f0102ee3 <mem_init+0x19db>
f0102ebf:	c7 44 24 0c ec 4d 10 	movl   $0xf0104dec,0xc(%esp)
f0102ec6:	f0 
f0102ec7:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102ece:	f0 
f0102ecf:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102ed6:	00 
f0102ed7:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102ede:	e8 b1 d1 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102ee3:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102eea:	00 
f0102eeb:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102ef0:	89 04 24             	mov    %eax,(%esp)
f0102ef3:	e8 4a e5 ff ff       	call   f0101442 <page_remove>
	assert(pp2->pp_ref == 0);
f0102ef8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102efd:	74 24                	je     f0102f23 <mem_init+0x1a1b>
f0102eff:	c7 44 24 0c 6c 50 10 	movl   $0xf010506c,0xc(%esp)
f0102f06:	f0 
f0102f07:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102f0e:	f0 
f0102f0f:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102f16:	00 
f0102f17:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102f1e:	e8 71 d1 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f23:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102f28:	8b 08                	mov    (%eax),%ecx
f0102f2a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f30:	89 da                	mov    %ebx,%edx
f0102f32:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102f38:	c1 fa 03             	sar    $0x3,%edx
f0102f3b:	c1 e2 0c             	shl    $0xc,%edx
f0102f3e:	39 d1                	cmp    %edx,%ecx
f0102f40:	74 24                	je     f0102f66 <mem_init+0x1a5e>
f0102f42:	c7 44 24 0c 68 49 10 	movl   $0xf0104968,0xc(%esp)
f0102f49:	f0 
f0102f4a:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102f51:	f0 
f0102f52:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0102f59:	00 
f0102f5a:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102f61:	e8 2e d1 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102f66:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102f6c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102f71:	74 24                	je     f0102f97 <mem_init+0x1a8f>
f0102f73:	c7 44 24 0c 23 50 10 	movl   $0xf0105023,0xc(%esp)
f0102f7a:	f0 
f0102f7b:	c7 44 24 08 6a 4e 10 	movl   $0xf0104e6a,0x8(%esp)
f0102f82:	f0 
f0102f83:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0102f8a:	00 
f0102f8b:	c7 04 24 52 4e 10 f0 	movl   $0xf0104e52,(%esp)
f0102f92:	e8 fd d0 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102f97:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102f9d:	89 1c 24             	mov    %ebx,(%esp)
f0102fa0:	e8 f4 e2 ff ff       	call   f0101299 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102fa5:	c7 04 24 18 4e 10 f0 	movl   $0xf0104e18,(%esp)
f0102fac:	e8 83 00 00 00       	call   f0103034 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102fb1:	83 c4 4c             	add    $0x4c,%esp
f0102fb4:	5b                   	pop    %ebx
f0102fb5:	5e                   	pop    %esi
f0102fb6:	5f                   	pop    %edi
f0102fb7:	5d                   	pop    %ebp
f0102fb8:	c3                   	ret    

f0102fb9 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102fb9:	55                   	push   %ebp
f0102fba:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102fbc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fbf:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102fc2:	5d                   	pop    %ebp
f0102fc3:	c3                   	ret    

f0102fc4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102fc4:	55                   	push   %ebp
f0102fc5:	89 e5                	mov    %esp,%ebp
f0102fc7:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102fcb:	ba 70 00 00 00       	mov    $0x70,%edx
f0102fd0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102fd1:	b2 71                	mov    $0x71,%dl
f0102fd3:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102fd4:	0f b6 c0             	movzbl %al,%eax
}
f0102fd7:	5d                   	pop    %ebp
f0102fd8:	c3                   	ret    

f0102fd9 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102fd9:	55                   	push   %ebp
f0102fda:	89 e5                	mov    %esp,%ebp
f0102fdc:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102fe0:	ba 70 00 00 00       	mov    $0x70,%edx
f0102fe5:	ee                   	out    %al,(%dx)
f0102fe6:	b2 71                	mov    $0x71,%dl
f0102fe8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102feb:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102fec:	5d                   	pop    %ebp
f0102fed:	c3                   	ret    

f0102fee <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102fee:	55                   	push   %ebp
f0102fef:	89 e5                	mov    %esp,%ebp
f0102ff1:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102ff4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ff7:	89 04 24             	mov    %eax,(%esp)
f0102ffa:	e8 f2 d5 ff ff       	call   f01005f1 <cputchar>
	*cnt++;
}
f0102fff:	c9                   	leave  
f0103000:	c3                   	ret    

f0103001 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103001:	55                   	push   %ebp
f0103002:	89 e5                	mov    %esp,%ebp
f0103004:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103007:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010300e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103011:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103015:	8b 45 08             	mov    0x8(%ebp),%eax
f0103018:	89 44 24 08          	mov    %eax,0x8(%esp)
f010301c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010301f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103023:	c7 04 24 ee 2f 10 f0 	movl   $0xf0102fee,(%esp)
f010302a:	e8 af 04 00 00       	call   f01034de <vprintfmt>
	return cnt;
}
f010302f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103032:	c9                   	leave  
f0103033:	c3                   	ret    

f0103034 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103034:	55                   	push   %ebp
f0103035:	89 e5                	mov    %esp,%ebp
f0103037:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010303a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010303d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103041:	8b 45 08             	mov    0x8(%ebp),%eax
f0103044:	89 04 24             	mov    %eax,(%esp)
f0103047:	e8 b5 ff ff ff       	call   f0103001 <vcprintf>
	va_end(ap);

	return cnt;
}
f010304c:	c9                   	leave  
f010304d:	c3                   	ret    

f010304e <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010304e:	55                   	push   %ebp
f010304f:	89 e5                	mov    %esp,%ebp
f0103051:	57                   	push   %edi
f0103052:	56                   	push   %esi
f0103053:	53                   	push   %ebx
f0103054:	83 ec 10             	sub    $0x10,%esp
f0103057:	89 c6                	mov    %eax,%esi
f0103059:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010305c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010305f:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103062:	8b 1a                	mov    (%edx),%ebx
f0103064:	8b 01                	mov    (%ecx),%eax
f0103066:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103069:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0103070:	eb 77                	jmp    f01030e9 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0103072:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103075:	01 d8                	add    %ebx,%eax
f0103077:	b9 02 00 00 00       	mov    $0x2,%ecx
f010307c:	99                   	cltd   
f010307d:	f7 f9                	idiv   %ecx
f010307f:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103081:	eb 01                	jmp    f0103084 <stab_binsearch+0x36>
			m--;
f0103083:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103084:	39 d9                	cmp    %ebx,%ecx
f0103086:	7c 1d                	jl     f01030a5 <stab_binsearch+0x57>
f0103088:	6b d1 0c             	imul   $0xc,%ecx,%edx
f010308b:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0103090:	39 fa                	cmp    %edi,%edx
f0103092:	75 ef                	jne    f0103083 <stab_binsearch+0x35>
f0103094:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103097:	6b d1 0c             	imul   $0xc,%ecx,%edx
f010309a:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f010309e:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01030a1:	73 18                	jae    f01030bb <stab_binsearch+0x6d>
f01030a3:	eb 05                	jmp    f01030aa <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01030a5:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f01030a8:	eb 3f                	jmp    f01030e9 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01030aa:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01030ad:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f01030af:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01030b2:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01030b9:	eb 2e                	jmp    f01030e9 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01030bb:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01030be:	73 15                	jae    f01030d5 <stab_binsearch+0x87>
			*region_right = m - 1;
f01030c0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01030c3:	48                   	dec    %eax
f01030c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01030c7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01030ca:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01030cc:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01030d3:	eb 14                	jmp    f01030e9 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01030d5:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01030d8:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f01030db:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f01030dd:	ff 45 0c             	incl   0xc(%ebp)
f01030e0:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01030e2:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01030e9:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01030ec:	7e 84                	jle    f0103072 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01030ee:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01030f2:	75 0d                	jne    f0103101 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f01030f4:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01030f7:	8b 00                	mov    (%eax),%eax
f01030f9:	48                   	dec    %eax
f01030fa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01030fd:	89 07                	mov    %eax,(%edi)
f01030ff:	eb 22                	jmp    f0103123 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103101:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103104:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103106:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103109:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010310b:	eb 01                	jmp    f010310e <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010310d:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010310e:	39 c1                	cmp    %eax,%ecx
f0103110:	7d 0c                	jge    f010311e <stab_binsearch+0xd0>
f0103112:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0103115:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010311a:	39 fa                	cmp    %edi,%edx
f010311c:	75 ef                	jne    f010310d <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f010311e:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0103121:	89 07                	mov    %eax,(%edi)
	}
}
f0103123:	83 c4 10             	add    $0x10,%esp
f0103126:	5b                   	pop    %ebx
f0103127:	5e                   	pop    %esi
f0103128:	5f                   	pop    %edi
f0103129:	5d                   	pop    %ebp
f010312a:	c3                   	ret    

f010312b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010312b:	55                   	push   %ebp
f010312c:	89 e5                	mov    %esp,%ebp
f010312e:	57                   	push   %edi
f010312f:	56                   	push   %esi
f0103130:	53                   	push   %ebx
f0103131:	83 ec 3c             	sub    $0x3c,%esp
f0103134:	8b 75 08             	mov    0x8(%ebp),%esi
f0103137:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010313a:	c7 03 06 51 10 f0    	movl   $0xf0105106,(%ebx)
	info->eip_line = 0;
f0103140:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103147:	c7 43 08 06 51 10 f0 	movl   $0xf0105106,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010314e:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103155:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103158:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010315f:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103165:	76 12                	jbe    f0103179 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103167:	b8 2b d1 10 f0       	mov    $0xf010d12b,%eax
f010316c:	3d 9d b2 10 f0       	cmp    $0xf010b29d,%eax
f0103171:	0f 86 cd 01 00 00    	jbe    f0103344 <debuginfo_eip+0x219>
f0103177:	eb 1c                	jmp    f0103195 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0103179:	c7 44 24 08 10 51 10 	movl   $0xf0105110,0x8(%esp)
f0103180:	f0 
f0103181:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103188:	00 
f0103189:	c7 04 24 1d 51 10 f0 	movl   $0xf010511d,(%esp)
f0103190:	e8 ff ce ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103195:	80 3d 2a d1 10 f0 00 	cmpb   $0x0,0xf010d12a
f010319c:	0f 85 a9 01 00 00    	jne    f010334b <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01031a2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01031a9:	b8 9c b2 10 f0       	mov    $0xf010b29c,%eax
f01031ae:	2d 50 53 10 f0       	sub    $0xf0105350,%eax
f01031b3:	c1 f8 02             	sar    $0x2,%eax
f01031b6:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01031bc:	83 e8 01             	sub    $0x1,%eax
f01031bf:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01031c2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01031c6:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01031cd:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01031d0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01031d3:	b8 50 53 10 f0       	mov    $0xf0105350,%eax
f01031d8:	e8 71 fe ff ff       	call   f010304e <stab_binsearch>
	if (lfile == 0)
f01031dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031e0:	85 c0                	test   %eax,%eax
f01031e2:	0f 84 6a 01 00 00    	je     f0103352 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01031e8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01031eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031ee:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01031f1:	89 74 24 04          	mov    %esi,0x4(%esp)
f01031f5:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01031fc:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01031ff:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103202:	b8 50 53 10 f0       	mov    $0xf0105350,%eax
f0103207:	e8 42 fe ff ff       	call   f010304e <stab_binsearch>

	if (lfun <= rfun) {
f010320c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010320f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103212:	39 d0                	cmp    %edx,%eax
f0103214:	7f 3d                	jg     f0103253 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103216:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0103219:	8d b9 50 53 10 f0    	lea    -0xfefacb0(%ecx),%edi
f010321f:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0103222:	8b 89 50 53 10 f0    	mov    -0xfefacb0(%ecx),%ecx
f0103228:	bf 2b d1 10 f0       	mov    $0xf010d12b,%edi
f010322d:	81 ef 9d b2 10 f0    	sub    $0xf010b29d,%edi
f0103233:	39 f9                	cmp    %edi,%ecx
f0103235:	73 09                	jae    f0103240 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103237:	81 c1 9d b2 10 f0    	add    $0xf010b29d,%ecx
f010323d:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103240:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103243:	8b 4f 08             	mov    0x8(%edi),%ecx
f0103246:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103249:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010324b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010324e:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0103251:	eb 0f                	jmp    f0103262 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103253:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103256:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103259:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010325c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010325f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103262:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103269:	00 
f010326a:	8b 43 08             	mov    0x8(%ebx),%eax
f010326d:	89 04 24             	mov    %eax,(%esp)
f0103270:	e8 06 09 00 00       	call   f0103b7b <strfind>
f0103275:	2b 43 08             	sub    0x8(%ebx),%eax
f0103278:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010327b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010327f:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103286:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103289:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010328c:	b8 50 53 10 f0       	mov    $0xf0105350,%eax
f0103291:	e8 b8 fd ff ff       	call   f010304e <stab_binsearch>
	if (lline <= rline) 
f0103296:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103299:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010329c:	0f 8f b7 00 00 00    	jg     f0103359 <debuginfo_eip+0x22e>
    		info->eip_line = stabs[rline].n_desc;
f01032a2:	6b c0 0c             	imul   $0xc,%eax,%eax
f01032a5:	0f b7 80 56 53 10 f0 	movzwl -0xfefacaa(%eax),%eax
f01032ac:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01032af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032b2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01032b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032b8:	6b d0 0c             	imul   $0xc,%eax,%edx
f01032bb:	81 c2 50 53 10 f0    	add    $0xf0105350,%edx
f01032c1:	eb 06                	jmp    f01032c9 <debuginfo_eip+0x19e>
f01032c3:	83 e8 01             	sub    $0x1,%eax
f01032c6:	83 ea 0c             	sub    $0xc,%edx
f01032c9:	89 c6                	mov    %eax,%esi
f01032cb:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f01032ce:	7f 33                	jg     f0103303 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f01032d0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01032d4:	80 f9 84             	cmp    $0x84,%cl
f01032d7:	74 0b                	je     f01032e4 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01032d9:	80 f9 64             	cmp    $0x64,%cl
f01032dc:	75 e5                	jne    f01032c3 <debuginfo_eip+0x198>
f01032de:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01032e2:	74 df                	je     f01032c3 <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01032e4:	6b f6 0c             	imul   $0xc,%esi,%esi
f01032e7:	8b 86 50 53 10 f0    	mov    -0xfefacb0(%esi),%eax
f01032ed:	ba 2b d1 10 f0       	mov    $0xf010d12b,%edx
f01032f2:	81 ea 9d b2 10 f0    	sub    $0xf010b29d,%edx
f01032f8:	39 d0                	cmp    %edx,%eax
f01032fa:	73 07                	jae    f0103303 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01032fc:	05 9d b2 10 f0       	add    $0xf010b29d,%eax
f0103301:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103303:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103306:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103309:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010330e:	39 ca                	cmp    %ecx,%edx
f0103310:	7d 53                	jge    f0103365 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0103312:	8d 42 01             	lea    0x1(%edx),%eax
f0103315:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103318:	89 c2                	mov    %eax,%edx
f010331a:	6b c0 0c             	imul   $0xc,%eax,%eax
f010331d:	05 50 53 10 f0       	add    $0xf0105350,%eax
f0103322:	89 ce                	mov    %ecx,%esi
f0103324:	eb 04                	jmp    f010332a <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103326:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010332a:	39 d6                	cmp    %edx,%esi
f010332c:	7e 32                	jle    f0103360 <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010332e:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0103332:	83 c2 01             	add    $0x1,%edx
f0103335:	83 c0 0c             	add    $0xc,%eax
f0103338:	80 f9 a0             	cmp    $0xa0,%cl
f010333b:	74 e9                	je     f0103326 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010333d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103342:	eb 21                	jmp    f0103365 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103344:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103349:	eb 1a                	jmp    f0103365 <debuginfo_eip+0x23a>
f010334b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103350:	eb 13                	jmp    f0103365 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103352:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103357:	eb 0c                	jmp    f0103365 <debuginfo_eip+0x23a>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline) 
    		info->eip_line = stabs[rline].n_desc;
	else 
    		return -1;
f0103359:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010335e:	eb 05                	jmp    f0103365 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103360:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103365:	83 c4 3c             	add    $0x3c,%esp
f0103368:	5b                   	pop    %ebx
f0103369:	5e                   	pop    %esi
f010336a:	5f                   	pop    %edi
f010336b:	5d                   	pop    %ebp
f010336c:	c3                   	ret    
f010336d:	66 90                	xchg   %ax,%ax
f010336f:	90                   	nop

f0103370 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103370:	55                   	push   %ebp
f0103371:	89 e5                	mov    %esp,%ebp
f0103373:	57                   	push   %edi
f0103374:	56                   	push   %esi
f0103375:	53                   	push   %ebx
f0103376:	83 ec 3c             	sub    $0x3c,%esp
f0103379:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010337c:	89 d7                	mov    %edx,%edi
f010337e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103381:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103384:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103387:	89 c3                	mov    %eax,%ebx
f0103389:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010338c:	8b 45 10             	mov    0x10(%ebp),%eax
f010338f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103392:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103397:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010339a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010339d:	39 d9                	cmp    %ebx,%ecx
f010339f:	72 05                	jb     f01033a6 <printnum+0x36>
f01033a1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01033a4:	77 69                	ja     f010340f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01033a6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01033a9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01033ad:	83 ee 01             	sub    $0x1,%esi
f01033b0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01033b4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033b8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01033bc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01033c0:	89 c3                	mov    %eax,%ebx
f01033c2:	89 d6                	mov    %edx,%esi
f01033c4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01033c7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01033ca:	89 54 24 08          	mov    %edx,0x8(%esp)
f01033ce:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01033d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033d5:	89 04 24             	mov    %eax,(%esp)
f01033d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033df:	e8 bc 09 00 00       	call   f0103da0 <__udivdi3>
f01033e4:	89 d9                	mov    %ebx,%ecx
f01033e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01033ea:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01033ee:	89 04 24             	mov    %eax,(%esp)
f01033f1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01033f5:	89 fa                	mov    %edi,%edx
f01033f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033fa:	e8 71 ff ff ff       	call   f0103370 <printnum>
f01033ff:	eb 1b                	jmp    f010341c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103401:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103405:	8b 45 18             	mov    0x18(%ebp),%eax
f0103408:	89 04 24             	mov    %eax,(%esp)
f010340b:	ff d3                	call   *%ebx
f010340d:	eb 03                	jmp    f0103412 <printnum+0xa2>
f010340f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103412:	83 ee 01             	sub    $0x1,%esi
f0103415:	85 f6                	test   %esi,%esi
f0103417:	7f e8                	jg     f0103401 <printnum+0x91>
f0103419:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010341c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103420:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103424:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103427:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010342a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010342e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103432:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103435:	89 04 24             	mov    %eax,(%esp)
f0103438:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010343b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010343f:	e8 8c 0a 00 00       	call   f0103ed0 <__umoddi3>
f0103444:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103448:	0f be 80 2b 51 10 f0 	movsbl -0xfefaed5(%eax),%eax
f010344f:	89 04 24             	mov    %eax,(%esp)
f0103452:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103455:	ff d0                	call   *%eax
}
f0103457:	83 c4 3c             	add    $0x3c,%esp
f010345a:	5b                   	pop    %ebx
f010345b:	5e                   	pop    %esi
f010345c:	5f                   	pop    %edi
f010345d:	5d                   	pop    %ebp
f010345e:	c3                   	ret    

f010345f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010345f:	55                   	push   %ebp
f0103460:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103462:	83 fa 01             	cmp    $0x1,%edx
f0103465:	7e 0e                	jle    f0103475 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103467:	8b 10                	mov    (%eax),%edx
f0103469:	8d 4a 08             	lea    0x8(%edx),%ecx
f010346c:	89 08                	mov    %ecx,(%eax)
f010346e:	8b 02                	mov    (%edx),%eax
f0103470:	8b 52 04             	mov    0x4(%edx),%edx
f0103473:	eb 22                	jmp    f0103497 <getuint+0x38>
	else if (lflag)
f0103475:	85 d2                	test   %edx,%edx
f0103477:	74 10                	je     f0103489 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103479:	8b 10                	mov    (%eax),%edx
f010347b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010347e:	89 08                	mov    %ecx,(%eax)
f0103480:	8b 02                	mov    (%edx),%eax
f0103482:	ba 00 00 00 00       	mov    $0x0,%edx
f0103487:	eb 0e                	jmp    f0103497 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103489:	8b 10                	mov    (%eax),%edx
f010348b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010348e:	89 08                	mov    %ecx,(%eax)
f0103490:	8b 02                	mov    (%edx),%eax
f0103492:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103497:	5d                   	pop    %ebp
f0103498:	c3                   	ret    

f0103499 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103499:	55                   	push   %ebp
f010349a:	89 e5                	mov    %esp,%ebp
f010349c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010349f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01034a3:	8b 10                	mov    (%eax),%edx
f01034a5:	3b 50 04             	cmp    0x4(%eax),%edx
f01034a8:	73 0a                	jae    f01034b4 <sprintputch+0x1b>
		*b->buf++ = ch;
f01034aa:	8d 4a 01             	lea    0x1(%edx),%ecx
f01034ad:	89 08                	mov    %ecx,(%eax)
f01034af:	8b 45 08             	mov    0x8(%ebp),%eax
f01034b2:	88 02                	mov    %al,(%edx)
}
f01034b4:	5d                   	pop    %ebp
f01034b5:	c3                   	ret    

f01034b6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01034b6:	55                   	push   %ebp
f01034b7:	89 e5                	mov    %esp,%ebp
f01034b9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01034bc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01034bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034c3:	8b 45 10             	mov    0x10(%ebp),%eax
f01034c6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01034ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01034d4:	89 04 24             	mov    %eax,(%esp)
f01034d7:	e8 02 00 00 00       	call   f01034de <vprintfmt>
	va_end(ap);
}
f01034dc:	c9                   	leave  
f01034dd:	c3                   	ret    

f01034de <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01034de:	55                   	push   %ebp
f01034df:	89 e5                	mov    %esp,%ebp
f01034e1:	57                   	push   %edi
f01034e2:	56                   	push   %esi
f01034e3:	53                   	push   %ebx
f01034e4:	83 ec 3c             	sub    $0x3c,%esp
f01034e7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01034ea:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01034ed:	eb 14                	jmp    f0103503 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01034ef:	85 c0                	test   %eax,%eax
f01034f1:	0f 84 b3 03 00 00    	je     f01038aa <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f01034f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034fb:	89 04 24             	mov    %eax,(%esp)
f01034fe:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103501:	89 f3                	mov    %esi,%ebx
f0103503:	8d 73 01             	lea    0x1(%ebx),%esi
f0103506:	0f b6 03             	movzbl (%ebx),%eax
f0103509:	83 f8 25             	cmp    $0x25,%eax
f010350c:	75 e1                	jne    f01034ef <vprintfmt+0x11>
f010350e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103512:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103519:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0103520:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103527:	ba 00 00 00 00       	mov    $0x0,%edx
f010352c:	eb 1d                	jmp    f010354b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010352e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103530:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103534:	eb 15                	jmp    f010354b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103536:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103538:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010353c:	eb 0d                	jmp    f010354b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010353e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103541:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103544:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010354b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010354e:	0f b6 0e             	movzbl (%esi),%ecx
f0103551:	0f b6 c1             	movzbl %cl,%eax
f0103554:	83 e9 23             	sub    $0x23,%ecx
f0103557:	80 f9 55             	cmp    $0x55,%cl
f010355a:	0f 87 2a 03 00 00    	ja     f010388a <vprintfmt+0x3ac>
f0103560:	0f b6 c9             	movzbl %cl,%ecx
f0103563:	ff 24 8d c0 51 10 f0 	jmp    *-0xfefae40(,%ecx,4)
f010356a:	89 de                	mov    %ebx,%esi
f010356c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103571:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103574:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103578:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010357b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010357e:	83 fb 09             	cmp    $0x9,%ebx
f0103581:	77 36                	ja     f01035b9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103583:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103586:	eb e9                	jmp    f0103571 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103588:	8b 45 14             	mov    0x14(%ebp),%eax
f010358b:	8d 48 04             	lea    0x4(%eax),%ecx
f010358e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103591:	8b 00                	mov    (%eax),%eax
f0103593:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103596:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103598:	eb 22                	jmp    f01035bc <vprintfmt+0xde>
f010359a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010359d:	85 c9                	test   %ecx,%ecx
f010359f:	b8 00 00 00 00       	mov    $0x0,%eax
f01035a4:	0f 49 c1             	cmovns %ecx,%eax
f01035a7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035aa:	89 de                	mov    %ebx,%esi
f01035ac:	eb 9d                	jmp    f010354b <vprintfmt+0x6d>
f01035ae:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01035b0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01035b7:	eb 92                	jmp    f010354b <vprintfmt+0x6d>
f01035b9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01035bc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01035c0:	79 89                	jns    f010354b <vprintfmt+0x6d>
f01035c2:	e9 77 ff ff ff       	jmp    f010353e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01035c7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035ca:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01035cc:	e9 7a ff ff ff       	jmp    f010354b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01035d1:	8b 45 14             	mov    0x14(%ebp),%eax
f01035d4:	8d 50 04             	lea    0x4(%eax),%edx
f01035d7:	89 55 14             	mov    %edx,0x14(%ebp)
f01035da:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035de:	8b 00                	mov    (%eax),%eax
f01035e0:	89 04 24             	mov    %eax,(%esp)
f01035e3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01035e6:	e9 18 ff ff ff       	jmp    f0103503 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01035eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01035ee:	8d 50 04             	lea    0x4(%eax),%edx
f01035f1:	89 55 14             	mov    %edx,0x14(%ebp)
f01035f4:	8b 00                	mov    (%eax),%eax
f01035f6:	99                   	cltd   
f01035f7:	31 d0                	xor    %edx,%eax
f01035f9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01035fb:	83 f8 07             	cmp    $0x7,%eax
f01035fe:	7f 0b                	jg     f010360b <vprintfmt+0x12d>
f0103600:	8b 14 85 20 53 10 f0 	mov    -0xfeface0(,%eax,4),%edx
f0103607:	85 d2                	test   %edx,%edx
f0103609:	75 20                	jne    f010362b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010360b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010360f:	c7 44 24 08 43 51 10 	movl   $0xf0105143,0x8(%esp)
f0103616:	f0 
f0103617:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010361b:	8b 45 08             	mov    0x8(%ebp),%eax
f010361e:	89 04 24             	mov    %eax,(%esp)
f0103621:	e8 90 fe ff ff       	call   f01034b6 <printfmt>
f0103626:	e9 d8 fe ff ff       	jmp    f0103503 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010362b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010362f:	c7 44 24 08 7c 4e 10 	movl   $0xf0104e7c,0x8(%esp)
f0103636:	f0 
f0103637:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010363b:	8b 45 08             	mov    0x8(%ebp),%eax
f010363e:	89 04 24             	mov    %eax,(%esp)
f0103641:	e8 70 fe ff ff       	call   f01034b6 <printfmt>
f0103646:	e9 b8 fe ff ff       	jmp    f0103503 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010364b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010364e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103651:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103654:	8b 45 14             	mov    0x14(%ebp),%eax
f0103657:	8d 50 04             	lea    0x4(%eax),%edx
f010365a:	89 55 14             	mov    %edx,0x14(%ebp)
f010365d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010365f:	85 f6                	test   %esi,%esi
f0103661:	b8 3c 51 10 f0       	mov    $0xf010513c,%eax
f0103666:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0103669:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010366d:	0f 84 97 00 00 00    	je     f010370a <vprintfmt+0x22c>
f0103673:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103677:	0f 8e 9b 00 00 00    	jle    f0103718 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010367d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103681:	89 34 24             	mov    %esi,(%esp)
f0103684:	e8 9f 03 00 00       	call   f0103a28 <strnlen>
f0103689:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010368c:	29 c2                	sub    %eax,%edx
f010368e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0103691:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103695:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103698:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010369b:	8b 75 08             	mov    0x8(%ebp),%esi
f010369e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01036a1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01036a3:	eb 0f                	jmp    f01036b4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01036a5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01036a9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01036ac:	89 04 24             	mov    %eax,(%esp)
f01036af:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01036b1:	83 eb 01             	sub    $0x1,%ebx
f01036b4:	85 db                	test   %ebx,%ebx
f01036b6:	7f ed                	jg     f01036a5 <vprintfmt+0x1c7>
f01036b8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01036bb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01036be:	85 d2                	test   %edx,%edx
f01036c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01036c5:	0f 49 c2             	cmovns %edx,%eax
f01036c8:	29 c2                	sub    %eax,%edx
f01036ca:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01036cd:	89 d7                	mov    %edx,%edi
f01036cf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01036d2:	eb 50                	jmp    f0103724 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01036d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01036d8:	74 1e                	je     f01036f8 <vprintfmt+0x21a>
f01036da:	0f be d2             	movsbl %dl,%edx
f01036dd:	83 ea 20             	sub    $0x20,%edx
f01036e0:	83 fa 5e             	cmp    $0x5e,%edx
f01036e3:	76 13                	jbe    f01036f8 <vprintfmt+0x21a>
					putch('?', putdat);
f01036e5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036ec:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01036f3:	ff 55 08             	call   *0x8(%ebp)
f01036f6:	eb 0d                	jmp    f0103705 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01036f8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01036fb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036ff:	89 04 24             	mov    %eax,(%esp)
f0103702:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103705:	83 ef 01             	sub    $0x1,%edi
f0103708:	eb 1a                	jmp    f0103724 <vprintfmt+0x246>
f010370a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010370d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103710:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103713:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103716:	eb 0c                	jmp    f0103724 <vprintfmt+0x246>
f0103718:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010371b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010371e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103721:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103724:	83 c6 01             	add    $0x1,%esi
f0103727:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010372b:	0f be c2             	movsbl %dl,%eax
f010372e:	85 c0                	test   %eax,%eax
f0103730:	74 27                	je     f0103759 <vprintfmt+0x27b>
f0103732:	85 db                	test   %ebx,%ebx
f0103734:	78 9e                	js     f01036d4 <vprintfmt+0x1f6>
f0103736:	83 eb 01             	sub    $0x1,%ebx
f0103739:	79 99                	jns    f01036d4 <vprintfmt+0x1f6>
f010373b:	89 f8                	mov    %edi,%eax
f010373d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103740:	8b 75 08             	mov    0x8(%ebp),%esi
f0103743:	89 c3                	mov    %eax,%ebx
f0103745:	eb 1a                	jmp    f0103761 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103747:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010374b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103752:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103754:	83 eb 01             	sub    $0x1,%ebx
f0103757:	eb 08                	jmp    f0103761 <vprintfmt+0x283>
f0103759:	89 fb                	mov    %edi,%ebx
f010375b:	8b 75 08             	mov    0x8(%ebp),%esi
f010375e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103761:	85 db                	test   %ebx,%ebx
f0103763:	7f e2                	jg     f0103747 <vprintfmt+0x269>
f0103765:	89 75 08             	mov    %esi,0x8(%ebp)
f0103768:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010376b:	e9 93 fd ff ff       	jmp    f0103503 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103770:	83 fa 01             	cmp    $0x1,%edx
f0103773:	7e 16                	jle    f010378b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0103775:	8b 45 14             	mov    0x14(%ebp),%eax
f0103778:	8d 50 08             	lea    0x8(%eax),%edx
f010377b:	89 55 14             	mov    %edx,0x14(%ebp)
f010377e:	8b 50 04             	mov    0x4(%eax),%edx
f0103781:	8b 00                	mov    (%eax),%eax
f0103783:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103786:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103789:	eb 32                	jmp    f01037bd <vprintfmt+0x2df>
	else if (lflag)
f010378b:	85 d2                	test   %edx,%edx
f010378d:	74 18                	je     f01037a7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010378f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103792:	8d 50 04             	lea    0x4(%eax),%edx
f0103795:	89 55 14             	mov    %edx,0x14(%ebp)
f0103798:	8b 30                	mov    (%eax),%esi
f010379a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010379d:	89 f0                	mov    %esi,%eax
f010379f:	c1 f8 1f             	sar    $0x1f,%eax
f01037a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01037a5:	eb 16                	jmp    f01037bd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01037a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01037aa:	8d 50 04             	lea    0x4(%eax),%edx
f01037ad:	89 55 14             	mov    %edx,0x14(%ebp)
f01037b0:	8b 30                	mov    (%eax),%esi
f01037b2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01037b5:	89 f0                	mov    %esi,%eax
f01037b7:	c1 f8 1f             	sar    $0x1f,%eax
f01037ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01037bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037c0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01037c3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01037c8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01037cc:	0f 89 80 00 00 00    	jns    f0103852 <vprintfmt+0x374>
				putch('-', putdat);
f01037d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01037d6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01037dd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01037e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037e3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01037e6:	f7 d8                	neg    %eax
f01037e8:	83 d2 00             	adc    $0x0,%edx
f01037eb:	f7 da                	neg    %edx
			}
			base = 10;
f01037ed:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01037f2:	eb 5e                	jmp    f0103852 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01037f4:	8d 45 14             	lea    0x14(%ebp),%eax
f01037f7:	e8 63 fc ff ff       	call   f010345f <getuint>
			base = 10;
f01037fc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103801:	eb 4f                	jmp    f0103852 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint (&ap, lflag);
f0103803:	8d 45 14             	lea    0x14(%ebp),%eax
f0103806:	e8 54 fc ff ff       	call   f010345f <getuint>
			base = 8;
f010380b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103810:	eb 40                	jmp    f0103852 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0103812:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103816:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010381d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103820:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103824:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010382b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010382e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103831:	8d 50 04             	lea    0x4(%eax),%edx
f0103834:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103837:	8b 00                	mov    (%eax),%eax
f0103839:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010383e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103843:	eb 0d                	jmp    f0103852 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103845:	8d 45 14             	lea    0x14(%ebp),%eax
f0103848:	e8 12 fc ff ff       	call   f010345f <getuint>
			base = 16;
f010384d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103852:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0103856:	89 74 24 10          	mov    %esi,0x10(%esp)
f010385a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010385d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103861:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103865:	89 04 24             	mov    %eax,(%esp)
f0103868:	89 54 24 04          	mov    %edx,0x4(%esp)
f010386c:	89 fa                	mov    %edi,%edx
f010386e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103871:	e8 fa fa ff ff       	call   f0103370 <printnum>
			break;
f0103876:	e9 88 fc ff ff       	jmp    f0103503 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010387b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010387f:	89 04 24             	mov    %eax,(%esp)
f0103882:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103885:	e9 79 fc ff ff       	jmp    f0103503 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010388a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010388e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103895:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103898:	89 f3                	mov    %esi,%ebx
f010389a:	eb 03                	jmp    f010389f <vprintfmt+0x3c1>
f010389c:	83 eb 01             	sub    $0x1,%ebx
f010389f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01038a3:	75 f7                	jne    f010389c <vprintfmt+0x3be>
f01038a5:	e9 59 fc ff ff       	jmp    f0103503 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01038aa:	83 c4 3c             	add    $0x3c,%esp
f01038ad:	5b                   	pop    %ebx
f01038ae:	5e                   	pop    %esi
f01038af:	5f                   	pop    %edi
f01038b0:	5d                   	pop    %ebp
f01038b1:	c3                   	ret    

f01038b2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01038b2:	55                   	push   %ebp
f01038b3:	89 e5                	mov    %esp,%ebp
f01038b5:	83 ec 28             	sub    $0x28,%esp
f01038b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01038bb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01038be:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01038c1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01038c5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01038c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01038cf:	85 c0                	test   %eax,%eax
f01038d1:	74 30                	je     f0103903 <vsnprintf+0x51>
f01038d3:	85 d2                	test   %edx,%edx
f01038d5:	7e 2c                	jle    f0103903 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01038d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01038da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038de:	8b 45 10             	mov    0x10(%ebp),%eax
f01038e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038e5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01038e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038ec:	c7 04 24 99 34 10 f0 	movl   $0xf0103499,(%esp)
f01038f3:	e8 e6 fb ff ff       	call   f01034de <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01038f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01038fb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01038fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103901:	eb 05                	jmp    f0103908 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103903:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103908:	c9                   	leave  
f0103909:	c3                   	ret    

f010390a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010390a:	55                   	push   %ebp
f010390b:	89 e5                	mov    %esp,%ebp
f010390d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103910:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103913:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103917:	8b 45 10             	mov    0x10(%ebp),%eax
f010391a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010391e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103921:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103925:	8b 45 08             	mov    0x8(%ebp),%eax
f0103928:	89 04 24             	mov    %eax,(%esp)
f010392b:	e8 82 ff ff ff       	call   f01038b2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103930:	c9                   	leave  
f0103931:	c3                   	ret    
f0103932:	66 90                	xchg   %ax,%ax
f0103934:	66 90                	xchg   %ax,%ax
f0103936:	66 90                	xchg   %ax,%ax
f0103938:	66 90                	xchg   %ax,%ax
f010393a:	66 90                	xchg   %ax,%ax
f010393c:	66 90                	xchg   %ax,%ax
f010393e:	66 90                	xchg   %ax,%ax

f0103940 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103940:	55                   	push   %ebp
f0103941:	89 e5                	mov    %esp,%ebp
f0103943:	57                   	push   %edi
f0103944:	56                   	push   %esi
f0103945:	53                   	push   %ebx
f0103946:	83 ec 1c             	sub    $0x1c,%esp
f0103949:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010394c:	85 c0                	test   %eax,%eax
f010394e:	74 10                	je     f0103960 <readline+0x20>
		cprintf("%s", prompt);
f0103950:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103954:	c7 04 24 7c 4e 10 f0 	movl   $0xf0104e7c,(%esp)
f010395b:	e8 d4 f6 ff ff       	call   f0103034 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103960:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103967:	e8 a6 cc ff ff       	call   f0100612 <iscons>
f010396c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010396e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103973:	e8 89 cc ff ff       	call   f0100601 <getchar>
f0103978:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010397a:	85 c0                	test   %eax,%eax
f010397c:	79 17                	jns    f0103995 <readline+0x55>
			cprintf("read error: %e\n", c);
f010397e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103982:	c7 04 24 40 53 10 f0 	movl   $0xf0105340,(%esp)
f0103989:	e8 a6 f6 ff ff       	call   f0103034 <cprintf>
			return NULL;
f010398e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103993:	eb 6d                	jmp    f0103a02 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103995:	83 f8 7f             	cmp    $0x7f,%eax
f0103998:	74 05                	je     f010399f <readline+0x5f>
f010399a:	83 f8 08             	cmp    $0x8,%eax
f010399d:	75 19                	jne    f01039b8 <readline+0x78>
f010399f:	85 f6                	test   %esi,%esi
f01039a1:	7e 15                	jle    f01039b8 <readline+0x78>
			if (echoing)
f01039a3:	85 ff                	test   %edi,%edi
f01039a5:	74 0c                	je     f01039b3 <readline+0x73>
				cputchar('\b');
f01039a7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01039ae:	e8 3e cc ff ff       	call   f01005f1 <cputchar>
			i--;
f01039b3:	83 ee 01             	sub    $0x1,%esi
f01039b6:	eb bb                	jmp    f0103973 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01039b8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01039be:	7f 1c                	jg     f01039dc <readline+0x9c>
f01039c0:	83 fb 1f             	cmp    $0x1f,%ebx
f01039c3:	7e 17                	jle    f01039dc <readline+0x9c>
			if (echoing)
f01039c5:	85 ff                	test   %edi,%edi
f01039c7:	74 08                	je     f01039d1 <readline+0x91>
				cputchar(c);
f01039c9:	89 1c 24             	mov    %ebx,(%esp)
f01039cc:	e8 20 cc ff ff       	call   f01005f1 <cputchar>
			buf[i++] = c;
f01039d1:	88 9e 60 85 11 f0    	mov    %bl,-0xfee7aa0(%esi)
f01039d7:	8d 76 01             	lea    0x1(%esi),%esi
f01039da:	eb 97                	jmp    f0103973 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01039dc:	83 fb 0d             	cmp    $0xd,%ebx
f01039df:	74 05                	je     f01039e6 <readline+0xa6>
f01039e1:	83 fb 0a             	cmp    $0xa,%ebx
f01039e4:	75 8d                	jne    f0103973 <readline+0x33>
			if (echoing)
f01039e6:	85 ff                	test   %edi,%edi
f01039e8:	74 0c                	je     f01039f6 <readline+0xb6>
				cputchar('\n');
f01039ea:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01039f1:	e8 fb cb ff ff       	call   f01005f1 <cputchar>
			buf[i] = 0;
f01039f6:	c6 86 60 85 11 f0 00 	movb   $0x0,-0xfee7aa0(%esi)
			return buf;
f01039fd:	b8 60 85 11 f0       	mov    $0xf0118560,%eax
		}
	}
}
f0103a02:	83 c4 1c             	add    $0x1c,%esp
f0103a05:	5b                   	pop    %ebx
f0103a06:	5e                   	pop    %esi
f0103a07:	5f                   	pop    %edi
f0103a08:	5d                   	pop    %ebp
f0103a09:	c3                   	ret    
f0103a0a:	66 90                	xchg   %ax,%ax
f0103a0c:	66 90                	xchg   %ax,%ax
f0103a0e:	66 90                	xchg   %ax,%ax

f0103a10 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103a10:	55                   	push   %ebp
f0103a11:	89 e5                	mov    %esp,%ebp
f0103a13:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a16:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a1b:	eb 03                	jmp    f0103a20 <strlen+0x10>
		n++;
f0103a1d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a20:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103a24:	75 f7                	jne    f0103a1d <strlen+0xd>
		n++;
	return n;
}
f0103a26:	5d                   	pop    %ebp
f0103a27:	c3                   	ret    

f0103a28 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103a28:	55                   	push   %ebp
f0103a29:	89 e5                	mov    %esp,%ebp
f0103a2b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a2e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a31:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a36:	eb 03                	jmp    f0103a3b <strnlen+0x13>
		n++;
f0103a38:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a3b:	39 d0                	cmp    %edx,%eax
f0103a3d:	74 06                	je     f0103a45 <strnlen+0x1d>
f0103a3f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103a43:	75 f3                	jne    f0103a38 <strnlen+0x10>
		n++;
	return n;
}
f0103a45:	5d                   	pop    %ebp
f0103a46:	c3                   	ret    

f0103a47 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103a47:	55                   	push   %ebp
f0103a48:	89 e5                	mov    %esp,%ebp
f0103a4a:	53                   	push   %ebx
f0103a4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a4e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103a51:	89 c2                	mov    %eax,%edx
f0103a53:	83 c2 01             	add    $0x1,%edx
f0103a56:	83 c1 01             	add    $0x1,%ecx
f0103a59:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103a5d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103a60:	84 db                	test   %bl,%bl
f0103a62:	75 ef                	jne    f0103a53 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103a64:	5b                   	pop    %ebx
f0103a65:	5d                   	pop    %ebp
f0103a66:	c3                   	ret    

f0103a67 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103a67:	55                   	push   %ebp
f0103a68:	89 e5                	mov    %esp,%ebp
f0103a6a:	53                   	push   %ebx
f0103a6b:	83 ec 08             	sub    $0x8,%esp
f0103a6e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103a71:	89 1c 24             	mov    %ebx,(%esp)
f0103a74:	e8 97 ff ff ff       	call   f0103a10 <strlen>
	strcpy(dst + len, src);
f0103a79:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a7c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103a80:	01 d8                	add    %ebx,%eax
f0103a82:	89 04 24             	mov    %eax,(%esp)
f0103a85:	e8 bd ff ff ff       	call   f0103a47 <strcpy>
	return dst;
}
f0103a8a:	89 d8                	mov    %ebx,%eax
f0103a8c:	83 c4 08             	add    $0x8,%esp
f0103a8f:	5b                   	pop    %ebx
f0103a90:	5d                   	pop    %ebp
f0103a91:	c3                   	ret    

f0103a92 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103a92:	55                   	push   %ebp
f0103a93:	89 e5                	mov    %esp,%ebp
f0103a95:	56                   	push   %esi
f0103a96:	53                   	push   %ebx
f0103a97:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a9a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103a9d:	89 f3                	mov    %esi,%ebx
f0103a9f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103aa2:	89 f2                	mov    %esi,%edx
f0103aa4:	eb 0f                	jmp    f0103ab5 <strncpy+0x23>
		*dst++ = *src;
f0103aa6:	83 c2 01             	add    $0x1,%edx
f0103aa9:	0f b6 01             	movzbl (%ecx),%eax
f0103aac:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103aaf:	80 39 01             	cmpb   $0x1,(%ecx)
f0103ab2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103ab5:	39 da                	cmp    %ebx,%edx
f0103ab7:	75 ed                	jne    f0103aa6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103ab9:	89 f0                	mov    %esi,%eax
f0103abb:	5b                   	pop    %ebx
f0103abc:	5e                   	pop    %esi
f0103abd:	5d                   	pop    %ebp
f0103abe:	c3                   	ret    

f0103abf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103abf:	55                   	push   %ebp
f0103ac0:	89 e5                	mov    %esp,%ebp
f0103ac2:	56                   	push   %esi
f0103ac3:	53                   	push   %ebx
f0103ac4:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ac7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103aca:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103acd:	89 f0                	mov    %esi,%eax
f0103acf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103ad3:	85 c9                	test   %ecx,%ecx
f0103ad5:	75 0b                	jne    f0103ae2 <strlcpy+0x23>
f0103ad7:	eb 1d                	jmp    f0103af6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103ad9:	83 c0 01             	add    $0x1,%eax
f0103adc:	83 c2 01             	add    $0x1,%edx
f0103adf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103ae2:	39 d8                	cmp    %ebx,%eax
f0103ae4:	74 0b                	je     f0103af1 <strlcpy+0x32>
f0103ae6:	0f b6 0a             	movzbl (%edx),%ecx
f0103ae9:	84 c9                	test   %cl,%cl
f0103aeb:	75 ec                	jne    f0103ad9 <strlcpy+0x1a>
f0103aed:	89 c2                	mov    %eax,%edx
f0103aef:	eb 02                	jmp    f0103af3 <strlcpy+0x34>
f0103af1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0103af3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103af6:	29 f0                	sub    %esi,%eax
}
f0103af8:	5b                   	pop    %ebx
f0103af9:	5e                   	pop    %esi
f0103afa:	5d                   	pop    %ebp
f0103afb:	c3                   	ret    

f0103afc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103afc:	55                   	push   %ebp
f0103afd:	89 e5                	mov    %esp,%ebp
f0103aff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b02:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103b05:	eb 06                	jmp    f0103b0d <strcmp+0x11>
		p++, q++;
f0103b07:	83 c1 01             	add    $0x1,%ecx
f0103b0a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103b0d:	0f b6 01             	movzbl (%ecx),%eax
f0103b10:	84 c0                	test   %al,%al
f0103b12:	74 04                	je     f0103b18 <strcmp+0x1c>
f0103b14:	3a 02                	cmp    (%edx),%al
f0103b16:	74 ef                	je     f0103b07 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b18:	0f b6 c0             	movzbl %al,%eax
f0103b1b:	0f b6 12             	movzbl (%edx),%edx
f0103b1e:	29 d0                	sub    %edx,%eax
}
f0103b20:	5d                   	pop    %ebp
f0103b21:	c3                   	ret    

f0103b22 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103b22:	55                   	push   %ebp
f0103b23:	89 e5                	mov    %esp,%ebp
f0103b25:	53                   	push   %ebx
f0103b26:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b29:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b2c:	89 c3                	mov    %eax,%ebx
f0103b2e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103b31:	eb 06                	jmp    f0103b39 <strncmp+0x17>
		n--, p++, q++;
f0103b33:	83 c0 01             	add    $0x1,%eax
f0103b36:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103b39:	39 d8                	cmp    %ebx,%eax
f0103b3b:	74 15                	je     f0103b52 <strncmp+0x30>
f0103b3d:	0f b6 08             	movzbl (%eax),%ecx
f0103b40:	84 c9                	test   %cl,%cl
f0103b42:	74 04                	je     f0103b48 <strncmp+0x26>
f0103b44:	3a 0a                	cmp    (%edx),%cl
f0103b46:	74 eb                	je     f0103b33 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b48:	0f b6 00             	movzbl (%eax),%eax
f0103b4b:	0f b6 12             	movzbl (%edx),%edx
f0103b4e:	29 d0                	sub    %edx,%eax
f0103b50:	eb 05                	jmp    f0103b57 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103b52:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103b57:	5b                   	pop    %ebx
f0103b58:	5d                   	pop    %ebp
f0103b59:	c3                   	ret    

f0103b5a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103b5a:	55                   	push   %ebp
f0103b5b:	89 e5                	mov    %esp,%ebp
f0103b5d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b60:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b64:	eb 07                	jmp    f0103b6d <strchr+0x13>
		if (*s == c)
f0103b66:	38 ca                	cmp    %cl,%dl
f0103b68:	74 0f                	je     f0103b79 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103b6a:	83 c0 01             	add    $0x1,%eax
f0103b6d:	0f b6 10             	movzbl (%eax),%edx
f0103b70:	84 d2                	test   %dl,%dl
f0103b72:	75 f2                	jne    f0103b66 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103b74:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b79:	5d                   	pop    %ebp
f0103b7a:	c3                   	ret    

f0103b7b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103b7b:	55                   	push   %ebp
f0103b7c:	89 e5                	mov    %esp,%ebp
f0103b7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b81:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b85:	eb 07                	jmp    f0103b8e <strfind+0x13>
		if (*s == c)
f0103b87:	38 ca                	cmp    %cl,%dl
f0103b89:	74 0a                	je     f0103b95 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103b8b:	83 c0 01             	add    $0x1,%eax
f0103b8e:	0f b6 10             	movzbl (%eax),%edx
f0103b91:	84 d2                	test   %dl,%dl
f0103b93:	75 f2                	jne    f0103b87 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0103b95:	5d                   	pop    %ebp
f0103b96:	c3                   	ret    

f0103b97 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103b97:	55                   	push   %ebp
f0103b98:	89 e5                	mov    %esp,%ebp
f0103b9a:	57                   	push   %edi
f0103b9b:	56                   	push   %esi
f0103b9c:	53                   	push   %ebx
f0103b9d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103ba0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103ba3:	85 c9                	test   %ecx,%ecx
f0103ba5:	74 36                	je     f0103bdd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103ba7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103bad:	75 28                	jne    f0103bd7 <memset+0x40>
f0103baf:	f6 c1 03             	test   $0x3,%cl
f0103bb2:	75 23                	jne    f0103bd7 <memset+0x40>
		c &= 0xFF;
f0103bb4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103bb8:	89 d3                	mov    %edx,%ebx
f0103bba:	c1 e3 08             	shl    $0x8,%ebx
f0103bbd:	89 d6                	mov    %edx,%esi
f0103bbf:	c1 e6 18             	shl    $0x18,%esi
f0103bc2:	89 d0                	mov    %edx,%eax
f0103bc4:	c1 e0 10             	shl    $0x10,%eax
f0103bc7:	09 f0                	or     %esi,%eax
f0103bc9:	09 c2                	or     %eax,%edx
f0103bcb:	89 d0                	mov    %edx,%eax
f0103bcd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103bcf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103bd2:	fc                   	cld    
f0103bd3:	f3 ab                	rep stos %eax,%es:(%edi)
f0103bd5:	eb 06                	jmp    f0103bdd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103bd7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bda:	fc                   	cld    
f0103bdb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103bdd:	89 f8                	mov    %edi,%eax
f0103bdf:	5b                   	pop    %ebx
f0103be0:	5e                   	pop    %esi
f0103be1:	5f                   	pop    %edi
f0103be2:	5d                   	pop    %ebp
f0103be3:	c3                   	ret    

f0103be4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103be4:	55                   	push   %ebp
f0103be5:	89 e5                	mov    %esp,%ebp
f0103be7:	57                   	push   %edi
f0103be8:	56                   	push   %esi
f0103be9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bec:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103bef:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103bf2:	39 c6                	cmp    %eax,%esi
f0103bf4:	73 35                	jae    f0103c2b <memmove+0x47>
f0103bf6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103bf9:	39 d0                	cmp    %edx,%eax
f0103bfb:	73 2e                	jae    f0103c2b <memmove+0x47>
		s += n;
		d += n;
f0103bfd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0103c00:	89 d6                	mov    %edx,%esi
f0103c02:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c04:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103c0a:	75 13                	jne    f0103c1f <memmove+0x3b>
f0103c0c:	f6 c1 03             	test   $0x3,%cl
f0103c0f:	75 0e                	jne    f0103c1f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103c11:	83 ef 04             	sub    $0x4,%edi
f0103c14:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103c17:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103c1a:	fd                   	std    
f0103c1b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c1d:	eb 09                	jmp    f0103c28 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103c1f:	83 ef 01             	sub    $0x1,%edi
f0103c22:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103c25:	fd                   	std    
f0103c26:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103c28:	fc                   	cld    
f0103c29:	eb 1d                	jmp    f0103c48 <memmove+0x64>
f0103c2b:	89 f2                	mov    %esi,%edx
f0103c2d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c2f:	f6 c2 03             	test   $0x3,%dl
f0103c32:	75 0f                	jne    f0103c43 <memmove+0x5f>
f0103c34:	f6 c1 03             	test   $0x3,%cl
f0103c37:	75 0a                	jne    f0103c43 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103c39:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103c3c:	89 c7                	mov    %eax,%edi
f0103c3e:	fc                   	cld    
f0103c3f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c41:	eb 05                	jmp    f0103c48 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103c43:	89 c7                	mov    %eax,%edi
f0103c45:	fc                   	cld    
f0103c46:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103c48:	5e                   	pop    %esi
f0103c49:	5f                   	pop    %edi
f0103c4a:	5d                   	pop    %ebp
f0103c4b:	c3                   	ret    

f0103c4c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103c4c:	55                   	push   %ebp
f0103c4d:	89 e5                	mov    %esp,%ebp
f0103c4f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103c52:	8b 45 10             	mov    0x10(%ebp),%eax
f0103c55:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c59:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c5c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c60:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c63:	89 04 24             	mov    %eax,(%esp)
f0103c66:	e8 79 ff ff ff       	call   f0103be4 <memmove>
}
f0103c6b:	c9                   	leave  
f0103c6c:	c3                   	ret    

f0103c6d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103c6d:	55                   	push   %ebp
f0103c6e:	89 e5                	mov    %esp,%ebp
f0103c70:	56                   	push   %esi
f0103c71:	53                   	push   %ebx
f0103c72:	8b 55 08             	mov    0x8(%ebp),%edx
f0103c75:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103c78:	89 d6                	mov    %edx,%esi
f0103c7a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c7d:	eb 1a                	jmp    f0103c99 <memcmp+0x2c>
		if (*s1 != *s2)
f0103c7f:	0f b6 02             	movzbl (%edx),%eax
f0103c82:	0f b6 19             	movzbl (%ecx),%ebx
f0103c85:	38 d8                	cmp    %bl,%al
f0103c87:	74 0a                	je     f0103c93 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103c89:	0f b6 c0             	movzbl %al,%eax
f0103c8c:	0f b6 db             	movzbl %bl,%ebx
f0103c8f:	29 d8                	sub    %ebx,%eax
f0103c91:	eb 0f                	jmp    f0103ca2 <memcmp+0x35>
		s1++, s2++;
f0103c93:	83 c2 01             	add    $0x1,%edx
f0103c96:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c99:	39 f2                	cmp    %esi,%edx
f0103c9b:	75 e2                	jne    f0103c7f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103c9d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ca2:	5b                   	pop    %ebx
f0103ca3:	5e                   	pop    %esi
f0103ca4:	5d                   	pop    %ebp
f0103ca5:	c3                   	ret    

f0103ca6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103ca6:	55                   	push   %ebp
f0103ca7:	89 e5                	mov    %esp,%ebp
f0103ca9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cac:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103caf:	89 c2                	mov    %eax,%edx
f0103cb1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103cb4:	eb 07                	jmp    f0103cbd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103cb6:	38 08                	cmp    %cl,(%eax)
f0103cb8:	74 07                	je     f0103cc1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103cba:	83 c0 01             	add    $0x1,%eax
f0103cbd:	39 d0                	cmp    %edx,%eax
f0103cbf:	72 f5                	jb     f0103cb6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103cc1:	5d                   	pop    %ebp
f0103cc2:	c3                   	ret    

f0103cc3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103cc3:	55                   	push   %ebp
f0103cc4:	89 e5                	mov    %esp,%ebp
f0103cc6:	57                   	push   %edi
f0103cc7:	56                   	push   %esi
f0103cc8:	53                   	push   %ebx
f0103cc9:	8b 55 08             	mov    0x8(%ebp),%edx
f0103ccc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103ccf:	eb 03                	jmp    f0103cd4 <strtol+0x11>
		s++;
f0103cd1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103cd4:	0f b6 0a             	movzbl (%edx),%ecx
f0103cd7:	80 f9 09             	cmp    $0x9,%cl
f0103cda:	74 f5                	je     f0103cd1 <strtol+0xe>
f0103cdc:	80 f9 20             	cmp    $0x20,%cl
f0103cdf:	74 f0                	je     f0103cd1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103ce1:	80 f9 2b             	cmp    $0x2b,%cl
f0103ce4:	75 0a                	jne    f0103cf0 <strtol+0x2d>
		s++;
f0103ce6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103ce9:	bf 00 00 00 00       	mov    $0x0,%edi
f0103cee:	eb 11                	jmp    f0103d01 <strtol+0x3e>
f0103cf0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103cf5:	80 f9 2d             	cmp    $0x2d,%cl
f0103cf8:	75 07                	jne    f0103d01 <strtol+0x3e>
		s++, neg = 1;
f0103cfa:	8d 52 01             	lea    0x1(%edx),%edx
f0103cfd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d01:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103d06:	75 15                	jne    f0103d1d <strtol+0x5a>
f0103d08:	80 3a 30             	cmpb   $0x30,(%edx)
f0103d0b:	75 10                	jne    f0103d1d <strtol+0x5a>
f0103d0d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103d11:	75 0a                	jne    f0103d1d <strtol+0x5a>
		s += 2, base = 16;
f0103d13:	83 c2 02             	add    $0x2,%edx
f0103d16:	b8 10 00 00 00       	mov    $0x10,%eax
f0103d1b:	eb 10                	jmp    f0103d2d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0103d1d:	85 c0                	test   %eax,%eax
f0103d1f:	75 0c                	jne    f0103d2d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103d21:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103d23:	80 3a 30             	cmpb   $0x30,(%edx)
f0103d26:	75 05                	jne    f0103d2d <strtol+0x6a>
		s++, base = 8;
f0103d28:	83 c2 01             	add    $0x1,%edx
f0103d2b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0103d2d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103d32:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103d35:	0f b6 0a             	movzbl (%edx),%ecx
f0103d38:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103d3b:	89 f0                	mov    %esi,%eax
f0103d3d:	3c 09                	cmp    $0x9,%al
f0103d3f:	77 08                	ja     f0103d49 <strtol+0x86>
			dig = *s - '0';
f0103d41:	0f be c9             	movsbl %cl,%ecx
f0103d44:	83 e9 30             	sub    $0x30,%ecx
f0103d47:	eb 20                	jmp    f0103d69 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103d49:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103d4c:	89 f0                	mov    %esi,%eax
f0103d4e:	3c 19                	cmp    $0x19,%al
f0103d50:	77 08                	ja     f0103d5a <strtol+0x97>
			dig = *s - 'a' + 10;
f0103d52:	0f be c9             	movsbl %cl,%ecx
f0103d55:	83 e9 57             	sub    $0x57,%ecx
f0103d58:	eb 0f                	jmp    f0103d69 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103d5a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103d5d:	89 f0                	mov    %esi,%eax
f0103d5f:	3c 19                	cmp    $0x19,%al
f0103d61:	77 16                	ja     f0103d79 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0103d63:	0f be c9             	movsbl %cl,%ecx
f0103d66:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103d69:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103d6c:	7d 0f                	jge    f0103d7d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0103d6e:	83 c2 01             	add    $0x1,%edx
f0103d71:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103d75:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103d77:	eb bc                	jmp    f0103d35 <strtol+0x72>
f0103d79:	89 d8                	mov    %ebx,%eax
f0103d7b:	eb 02                	jmp    f0103d7f <strtol+0xbc>
f0103d7d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103d7f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103d83:	74 05                	je     f0103d8a <strtol+0xc7>
		*endptr = (char *) s;
f0103d85:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d88:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103d8a:	f7 d8                	neg    %eax
f0103d8c:	85 ff                	test   %edi,%edi
f0103d8e:	0f 44 c3             	cmove  %ebx,%eax
}
f0103d91:	5b                   	pop    %ebx
f0103d92:	5e                   	pop    %esi
f0103d93:	5f                   	pop    %edi
f0103d94:	5d                   	pop    %ebp
f0103d95:	c3                   	ret    
f0103d96:	66 90                	xchg   %ax,%ax
f0103d98:	66 90                	xchg   %ax,%ax
f0103d9a:	66 90                	xchg   %ax,%ax
f0103d9c:	66 90                	xchg   %ax,%ax
f0103d9e:	66 90                	xchg   %ax,%ax

f0103da0 <__udivdi3>:
f0103da0:	55                   	push   %ebp
f0103da1:	57                   	push   %edi
f0103da2:	56                   	push   %esi
f0103da3:	83 ec 0c             	sub    $0xc,%esp
f0103da6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103daa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103dae:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103db2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103db6:	85 c0                	test   %eax,%eax
f0103db8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103dbc:	89 ea                	mov    %ebp,%edx
f0103dbe:	89 0c 24             	mov    %ecx,(%esp)
f0103dc1:	75 2d                	jne    f0103df0 <__udivdi3+0x50>
f0103dc3:	39 e9                	cmp    %ebp,%ecx
f0103dc5:	77 61                	ja     f0103e28 <__udivdi3+0x88>
f0103dc7:	85 c9                	test   %ecx,%ecx
f0103dc9:	89 ce                	mov    %ecx,%esi
f0103dcb:	75 0b                	jne    f0103dd8 <__udivdi3+0x38>
f0103dcd:	b8 01 00 00 00       	mov    $0x1,%eax
f0103dd2:	31 d2                	xor    %edx,%edx
f0103dd4:	f7 f1                	div    %ecx
f0103dd6:	89 c6                	mov    %eax,%esi
f0103dd8:	31 d2                	xor    %edx,%edx
f0103dda:	89 e8                	mov    %ebp,%eax
f0103ddc:	f7 f6                	div    %esi
f0103dde:	89 c5                	mov    %eax,%ebp
f0103de0:	89 f8                	mov    %edi,%eax
f0103de2:	f7 f6                	div    %esi
f0103de4:	89 ea                	mov    %ebp,%edx
f0103de6:	83 c4 0c             	add    $0xc,%esp
f0103de9:	5e                   	pop    %esi
f0103dea:	5f                   	pop    %edi
f0103deb:	5d                   	pop    %ebp
f0103dec:	c3                   	ret    
f0103ded:	8d 76 00             	lea    0x0(%esi),%esi
f0103df0:	39 e8                	cmp    %ebp,%eax
f0103df2:	77 24                	ja     f0103e18 <__udivdi3+0x78>
f0103df4:	0f bd e8             	bsr    %eax,%ebp
f0103df7:	83 f5 1f             	xor    $0x1f,%ebp
f0103dfa:	75 3c                	jne    f0103e38 <__udivdi3+0x98>
f0103dfc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103e00:	39 34 24             	cmp    %esi,(%esp)
f0103e03:	0f 86 9f 00 00 00    	jbe    f0103ea8 <__udivdi3+0x108>
f0103e09:	39 d0                	cmp    %edx,%eax
f0103e0b:	0f 82 97 00 00 00    	jb     f0103ea8 <__udivdi3+0x108>
f0103e11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e18:	31 d2                	xor    %edx,%edx
f0103e1a:	31 c0                	xor    %eax,%eax
f0103e1c:	83 c4 0c             	add    $0xc,%esp
f0103e1f:	5e                   	pop    %esi
f0103e20:	5f                   	pop    %edi
f0103e21:	5d                   	pop    %ebp
f0103e22:	c3                   	ret    
f0103e23:	90                   	nop
f0103e24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e28:	89 f8                	mov    %edi,%eax
f0103e2a:	f7 f1                	div    %ecx
f0103e2c:	31 d2                	xor    %edx,%edx
f0103e2e:	83 c4 0c             	add    $0xc,%esp
f0103e31:	5e                   	pop    %esi
f0103e32:	5f                   	pop    %edi
f0103e33:	5d                   	pop    %ebp
f0103e34:	c3                   	ret    
f0103e35:	8d 76 00             	lea    0x0(%esi),%esi
f0103e38:	89 e9                	mov    %ebp,%ecx
f0103e3a:	8b 3c 24             	mov    (%esp),%edi
f0103e3d:	d3 e0                	shl    %cl,%eax
f0103e3f:	89 c6                	mov    %eax,%esi
f0103e41:	b8 20 00 00 00       	mov    $0x20,%eax
f0103e46:	29 e8                	sub    %ebp,%eax
f0103e48:	89 c1                	mov    %eax,%ecx
f0103e4a:	d3 ef                	shr    %cl,%edi
f0103e4c:	89 e9                	mov    %ebp,%ecx
f0103e4e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103e52:	8b 3c 24             	mov    (%esp),%edi
f0103e55:	09 74 24 08          	or     %esi,0x8(%esp)
f0103e59:	89 d6                	mov    %edx,%esi
f0103e5b:	d3 e7                	shl    %cl,%edi
f0103e5d:	89 c1                	mov    %eax,%ecx
f0103e5f:	89 3c 24             	mov    %edi,(%esp)
f0103e62:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103e66:	d3 ee                	shr    %cl,%esi
f0103e68:	89 e9                	mov    %ebp,%ecx
f0103e6a:	d3 e2                	shl    %cl,%edx
f0103e6c:	89 c1                	mov    %eax,%ecx
f0103e6e:	d3 ef                	shr    %cl,%edi
f0103e70:	09 d7                	or     %edx,%edi
f0103e72:	89 f2                	mov    %esi,%edx
f0103e74:	89 f8                	mov    %edi,%eax
f0103e76:	f7 74 24 08          	divl   0x8(%esp)
f0103e7a:	89 d6                	mov    %edx,%esi
f0103e7c:	89 c7                	mov    %eax,%edi
f0103e7e:	f7 24 24             	mull   (%esp)
f0103e81:	39 d6                	cmp    %edx,%esi
f0103e83:	89 14 24             	mov    %edx,(%esp)
f0103e86:	72 30                	jb     f0103eb8 <__udivdi3+0x118>
f0103e88:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103e8c:	89 e9                	mov    %ebp,%ecx
f0103e8e:	d3 e2                	shl    %cl,%edx
f0103e90:	39 c2                	cmp    %eax,%edx
f0103e92:	73 05                	jae    f0103e99 <__udivdi3+0xf9>
f0103e94:	3b 34 24             	cmp    (%esp),%esi
f0103e97:	74 1f                	je     f0103eb8 <__udivdi3+0x118>
f0103e99:	89 f8                	mov    %edi,%eax
f0103e9b:	31 d2                	xor    %edx,%edx
f0103e9d:	e9 7a ff ff ff       	jmp    f0103e1c <__udivdi3+0x7c>
f0103ea2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ea8:	31 d2                	xor    %edx,%edx
f0103eaa:	b8 01 00 00 00       	mov    $0x1,%eax
f0103eaf:	e9 68 ff ff ff       	jmp    f0103e1c <__udivdi3+0x7c>
f0103eb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103eb8:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103ebb:	31 d2                	xor    %edx,%edx
f0103ebd:	83 c4 0c             	add    $0xc,%esp
f0103ec0:	5e                   	pop    %esi
f0103ec1:	5f                   	pop    %edi
f0103ec2:	5d                   	pop    %ebp
f0103ec3:	c3                   	ret    
f0103ec4:	66 90                	xchg   %ax,%ax
f0103ec6:	66 90                	xchg   %ax,%ax
f0103ec8:	66 90                	xchg   %ax,%ax
f0103eca:	66 90                	xchg   %ax,%ax
f0103ecc:	66 90                	xchg   %ax,%ax
f0103ece:	66 90                	xchg   %ax,%ax

f0103ed0 <__umoddi3>:
f0103ed0:	55                   	push   %ebp
f0103ed1:	57                   	push   %edi
f0103ed2:	56                   	push   %esi
f0103ed3:	83 ec 14             	sub    $0x14,%esp
f0103ed6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103eda:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103ede:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103ee2:	89 c7                	mov    %eax,%edi
f0103ee4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ee8:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103eec:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103ef0:	89 34 24             	mov    %esi,(%esp)
f0103ef3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103ef7:	85 c0                	test   %eax,%eax
f0103ef9:	89 c2                	mov    %eax,%edx
f0103efb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103eff:	75 17                	jne    f0103f18 <__umoddi3+0x48>
f0103f01:	39 fe                	cmp    %edi,%esi
f0103f03:	76 4b                	jbe    f0103f50 <__umoddi3+0x80>
f0103f05:	89 c8                	mov    %ecx,%eax
f0103f07:	89 fa                	mov    %edi,%edx
f0103f09:	f7 f6                	div    %esi
f0103f0b:	89 d0                	mov    %edx,%eax
f0103f0d:	31 d2                	xor    %edx,%edx
f0103f0f:	83 c4 14             	add    $0x14,%esp
f0103f12:	5e                   	pop    %esi
f0103f13:	5f                   	pop    %edi
f0103f14:	5d                   	pop    %ebp
f0103f15:	c3                   	ret    
f0103f16:	66 90                	xchg   %ax,%ax
f0103f18:	39 f8                	cmp    %edi,%eax
f0103f1a:	77 54                	ja     f0103f70 <__umoddi3+0xa0>
f0103f1c:	0f bd e8             	bsr    %eax,%ebp
f0103f1f:	83 f5 1f             	xor    $0x1f,%ebp
f0103f22:	75 5c                	jne    f0103f80 <__umoddi3+0xb0>
f0103f24:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103f28:	39 3c 24             	cmp    %edi,(%esp)
f0103f2b:	0f 87 e7 00 00 00    	ja     f0104018 <__umoddi3+0x148>
f0103f31:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103f35:	29 f1                	sub    %esi,%ecx
f0103f37:	19 c7                	sbb    %eax,%edi
f0103f39:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103f3d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103f41:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103f45:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103f49:	83 c4 14             	add    $0x14,%esp
f0103f4c:	5e                   	pop    %esi
f0103f4d:	5f                   	pop    %edi
f0103f4e:	5d                   	pop    %ebp
f0103f4f:	c3                   	ret    
f0103f50:	85 f6                	test   %esi,%esi
f0103f52:	89 f5                	mov    %esi,%ebp
f0103f54:	75 0b                	jne    f0103f61 <__umoddi3+0x91>
f0103f56:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f5b:	31 d2                	xor    %edx,%edx
f0103f5d:	f7 f6                	div    %esi
f0103f5f:	89 c5                	mov    %eax,%ebp
f0103f61:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103f65:	31 d2                	xor    %edx,%edx
f0103f67:	f7 f5                	div    %ebp
f0103f69:	89 c8                	mov    %ecx,%eax
f0103f6b:	f7 f5                	div    %ebp
f0103f6d:	eb 9c                	jmp    f0103f0b <__umoddi3+0x3b>
f0103f6f:	90                   	nop
f0103f70:	89 c8                	mov    %ecx,%eax
f0103f72:	89 fa                	mov    %edi,%edx
f0103f74:	83 c4 14             	add    $0x14,%esp
f0103f77:	5e                   	pop    %esi
f0103f78:	5f                   	pop    %edi
f0103f79:	5d                   	pop    %ebp
f0103f7a:	c3                   	ret    
f0103f7b:	90                   	nop
f0103f7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f80:	8b 04 24             	mov    (%esp),%eax
f0103f83:	be 20 00 00 00       	mov    $0x20,%esi
f0103f88:	89 e9                	mov    %ebp,%ecx
f0103f8a:	29 ee                	sub    %ebp,%esi
f0103f8c:	d3 e2                	shl    %cl,%edx
f0103f8e:	89 f1                	mov    %esi,%ecx
f0103f90:	d3 e8                	shr    %cl,%eax
f0103f92:	89 e9                	mov    %ebp,%ecx
f0103f94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f98:	8b 04 24             	mov    (%esp),%eax
f0103f9b:	09 54 24 04          	or     %edx,0x4(%esp)
f0103f9f:	89 fa                	mov    %edi,%edx
f0103fa1:	d3 e0                	shl    %cl,%eax
f0103fa3:	89 f1                	mov    %esi,%ecx
f0103fa5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fa9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103fad:	d3 ea                	shr    %cl,%edx
f0103faf:	89 e9                	mov    %ebp,%ecx
f0103fb1:	d3 e7                	shl    %cl,%edi
f0103fb3:	89 f1                	mov    %esi,%ecx
f0103fb5:	d3 e8                	shr    %cl,%eax
f0103fb7:	89 e9                	mov    %ebp,%ecx
f0103fb9:	09 f8                	or     %edi,%eax
f0103fbb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103fbf:	f7 74 24 04          	divl   0x4(%esp)
f0103fc3:	d3 e7                	shl    %cl,%edi
f0103fc5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103fc9:	89 d7                	mov    %edx,%edi
f0103fcb:	f7 64 24 08          	mull   0x8(%esp)
f0103fcf:	39 d7                	cmp    %edx,%edi
f0103fd1:	89 c1                	mov    %eax,%ecx
f0103fd3:	89 14 24             	mov    %edx,(%esp)
f0103fd6:	72 2c                	jb     f0104004 <__umoddi3+0x134>
f0103fd8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103fdc:	72 22                	jb     f0104000 <__umoddi3+0x130>
f0103fde:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103fe2:	29 c8                	sub    %ecx,%eax
f0103fe4:	19 d7                	sbb    %edx,%edi
f0103fe6:	89 e9                	mov    %ebp,%ecx
f0103fe8:	89 fa                	mov    %edi,%edx
f0103fea:	d3 e8                	shr    %cl,%eax
f0103fec:	89 f1                	mov    %esi,%ecx
f0103fee:	d3 e2                	shl    %cl,%edx
f0103ff0:	89 e9                	mov    %ebp,%ecx
f0103ff2:	d3 ef                	shr    %cl,%edi
f0103ff4:	09 d0                	or     %edx,%eax
f0103ff6:	89 fa                	mov    %edi,%edx
f0103ff8:	83 c4 14             	add    $0x14,%esp
f0103ffb:	5e                   	pop    %esi
f0103ffc:	5f                   	pop    %edi
f0103ffd:	5d                   	pop    %ebp
f0103ffe:	c3                   	ret    
f0103fff:	90                   	nop
f0104000:	39 d7                	cmp    %edx,%edi
f0104002:	75 da                	jne    f0103fde <__umoddi3+0x10e>
f0104004:	8b 14 24             	mov    (%esp),%edx
f0104007:	89 c1                	mov    %eax,%ecx
f0104009:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010400d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0104011:	eb cb                	jmp    f0103fde <__umoddi3+0x10e>
f0104013:	90                   	nop
f0104014:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104018:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010401c:	0f 82 0f ff ff ff    	jb     f0103f31 <__umoddi3+0x61>
f0104022:	e9 1a ff ff ff       	jmp    f0103f41 <__umoddi3+0x71>
