
main.elf:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <fun>:
   0:	fe010113          	addi	sp,sp,-32
   4:	00812e23          	sw	s0,28(sp)
   8:	02010413          	addi	s0,sp,32
   c:	fea42623          	sw	a0,-20(s0)
  10:	fec42783          	lw	a5,-20(s0)
  14:	0007a783          	lw	a5,0(a5)
  18:	00a78713          	addi	a4,a5,10
  1c:	fec42783          	lw	a5,-20(s0)
  20:	00e7a023          	sw	a4,0(a5)
  24:	00000013          	nop
  28:	01c12403          	lw	s0,28(sp)
  2c:	02010113          	addi	sp,sp,32
  30:	00008067          	ret

00000034 <main>:
  34:	fe010113          	addi	sp,sp,-32
  38:	00112e23          	sw	ra,28(sp)
  3c:	00812c23          	sw	s0,24(sp)
  40:	02010413          	addi	s0,sp,32
  44:	00100793          	li	a5,1
  48:	fef42623          	sw	a5,-20(s0)
  4c:	fec40793          	addi	a5,s0,-20
  50:	00078513          	mv	a0,a5
  54:	fadff0ef          	jal	ra,0 <fun>
  58:	00000793          	li	a5,0
  5c:	00078513          	mv	a0,a5
  60:	01c12083          	lw	ra,28(sp)
  64:	01812403          	lw	s0,24(sp)
  68:	02010113          	addi	sp,sp,32
  6c:	00008067          	ret
