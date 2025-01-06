
main.elf:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <fun>:
   0:   fe010113                addi    sp,sp,-32
   4:   00812e23                sw      s0,28(sp)
   8:   02010413                addi    s0,sp,32
   c:   fea42623                sw      a0,-20(s0)
  10:   fec42783                lw      a5,-20(s0)
  14:   0007a703                lw      a4,0(a5)
  18:   00200793                li      a5,2
  1c:   00f71e63                bne     a4,a5,38 <fun+0x38>
  20:   fec42783                lw      a5,-20(s0)
  24:   0007a783                lw      a5,0(a5)
  28:   00178713                addi    a4,a5,1
  2c:   fec42783                lw      a5,-20(s0)
  30:   00e7a023                sw      a4,0(a5)
  34:   01c0006f                j       50 <fun+0x50>
  38:   fec42783                lw      a5,-20(s0)
  3c:   0007a783                lw      a5,0(a5)
  40:   00a78713                addi    a4,a5,10
  44:   fec42783                lw      a5,-20(s0)
  48:   00e7a023                sw      a4,0(a5)
  4c:   00000013                nop
  50:   01c12403                lw      s0,28(sp)
  54:   02010113                addi    sp,sp,32
  58:   00008067                ret

0000005c <main>:
  5c:   fe010113                addi    sp,sp,-32
  60:   00112e23                sw      ra,28(sp)
  64:   00812c23                sw      s0,24(sp)
  68:   02010413                addi    s0,sp,32
  6c:   00100793                li      a5,1
  70:   fef42623                sw      a5,-20(s0)
  74:   fec40793                addi    a5,s0,-20
  78:   00078513                mv      a0,a5
  7c:   f85ff0ef                jal     ra,0 <fun>
  80:   00000793                li      a5,0
  84:   00078513                mv      a0,a5
  88:   01c12083                lw      ra,28(sp)
  8c:   01812403                lw      s0,24(sp)
  90:   02010113                addi    sp,sp,32
  94:   00008067                ret