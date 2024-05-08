# RV32I CPU

“陛下，我们把这台计算机命名为‘秦一号’。请看，那里，中心部分，是CPU，是计算机的核心计算元件。由您最精锐的五个军团构成，对照这张图您可以看到里面的加法器、寄存器、堆栈存贮器；外围整齐的部分是内存，构建这部分时我们发现人手不够，好在这部分每个单元的动作最简单，就训练每个士兵拿多种颜色的旗帜，组合起来后，一个人就能同时完成最初二十个人的操作，这就使内存容量达到了运行‘秦1.0’操作系统的最低要求；”

> <div>
> 
>  《三体》, 刘慈欣
> 
> </div>

## RISC-V指令集简介

[RISC-V](https://riscv.org/) 是由UC Berkeley推出的一套开源指令集。
该指令集包含一系列的基础指令集和可选扩展指令集。在本实验中我们主要关注其中的32位基础指令集RV32I。
RV32I指令集中包含了40条基础指令，涵盖了整数运算、存储器访问、控制转移和系统控制几个大类。本实验中无需实现系统控制的ECALL/EBREAK、内存同步FENCE指令及CSR访问指令，所以共需实现37条指令。
RV32I中的程序计数器PC及32个通用寄存器均是32位长度，访存地址线宽度也是32位。RV32I的指令长度也统一为32位，在实现过程中无需支持16位的压缩指令格式。

### RV32I指令编码

RV32I的指令编码非常规整，分为六种类型，其中四种类型为基础编码类型，其余两种是变种：

> <div>
> 
> *   **R-Type** ：为寄存器操作数指令，含2个源寄存器rs1 ,rs2和一个目的寄存器 rd。
> 
> *   **I-Type** ：为立即数操作指令，含1个源寄存器和1个目的寄存器和1个12bit立即数操作数
> 
> *   **S-Type** ：为存储器写指令，含2个源寄存器和一个12bit立即数。
> 
> *   **B-Type** ：为跳转指令，实际是 *S-Type* 的变种。与 *S-Type* 主要的区别是立即数编码。
> 
> *   **U-Type** ：为长立即数指令，含一个目的寄存器和20bit立即数操作数。
> 
> *   **J-Type** ：为长跳转指令，实际是 *U-Type* 的变种。与 *U-Type* 主要的区别是立即数编码。
> </div>

其中四种基本格式如图

![指令格式](_images/riscvisa.png)

在指令编码中，opcode必定为指令低7bit，源寄存器rs1，rs2和目的寄存器rd也都在特定位置出现，所以指令解码非常方便。

### RV32I中的通用寄存器

RV32I共32个32bit的通用寄存器x0~x31(寄存器地址为5bit编码），其中寄存器x0中的内容总是0，无法改变。
其他寄存器的别名和寄存器使用约定参见表。

需要注意的是，部分寄存器在函数调用时是由调用方（Caller）来负责保存的，部分寄存器是由被调用方（Callee）来保存的。在进行C语言和汇编混合编程时需要注意。

<table class="docutils align-default" id="tab-regname">
<caption><span class="caption-number">Table 12 </span><span class="caption-text">RV32I中通用寄存器的定义与用法</span></caption>
<thead>
<tr class="row-odd"><th class="head">

Register
</th>
<th class="head">

Name
</th>
<th class="head">

Use
</th>
<th class="head">

Saver
</th>
</tr>
</thead>
<tbody>
<tr class="row-even"><td>

x0
</td>
<td>

zero
</td>
<td>

Constant 0
</td>
<td>

–
</td>
</tr>
<tr class="row-odd"><td>

x1
</td>
<td>

ra
</td>
<td>

Return Address
</td>
<td>

Caller
</td>
</tr>
<tr class="row-even"><td>

x2
</td>
<td>

sp
</td>
<td>

Stack Pointer
</td>
<td>

Callee
</td>
</tr>
<tr class="row-odd"><td>

x3
</td>
<td>

gp
</td>
<td>

Global Pointer
</td>
<td>

–
</td>
</tr>
<tr class="row-even"><td>

x4
</td>
<td>

tp
</td>
<td>

Thread Pointer
</td>
<td>

–
</td>
</tr>
<tr class="row-odd"><td>

x5~x7
</td>
<td>

t0~t2
</td>
<td>

Temp
</td>
<td>

Caller
</td>
</tr>
<tr class="row-even"><td>

x8
</td>
<td>

s0/fp
</td>
<td>

Saved/Frame pointer
</td>
<td>

Callee
</td>
</tr>
<tr class="row-odd"><td>

x9
</td>
<td>

s1
</td>
<td>

Saved
</td>
<td>

Callee
</td>
</tr>
<tr class="row-even"><td>

x10~x11
</td>
<td>

a0~a1
</td>
<td>

Arguments/Return Value
</td>
<td>

Caller
</td>
</tr>
<tr class="row-odd"><td>

x12~x17
</td>
<td>

a2~a7
</td>
<td>

Arguments
</td>
<td>

Caller
</td>
</tr>
<tr class="row-even"><td>

x18~x27
</td>
<td>

s2~s11
</td>
<td>

Saved
</td>
<td>

Callee
</td>
</tr>
<tr class="row-odd"><td>

x28~x31
</td>
<td>

t3~t6
</td>
<td>

Temp
</td>
<td>

Caller
</td>
</tr>
</tbody>
</table>

### RV32I中的指令类型

本实验中需要实现的RV32I指令含包含以下三类：

*   **整数运算指令** ：可以是对两个源寄存器操作数，或一个寄存器一个立即数操作数进行计算后，结果送入目的寄存器。运算操作包括带符号数和无符号数的算术运算、移位、逻辑操作和比较后置位等。

*   **控制转移指令** ：条件分支包括 *beq* ，*bne* 等等，根据寄存器内容选择是否跳转。无条件跳转指令会将本指令下一条指令地址 *PC+4* 存入 *rd* 中供函数返回时使用。

*   **存储器访问指令** ：对内存操作是首先寄存器加立即数偏移量，以计算结果为地址读取/写入内存。读写时可以是按32位字，16位半字或8位字节来进行读写。读写时区分无符号数和带符号数。注意：RV32I为 [Load/Store](https://en.wikipedia.org/wiki/Load%E2%80%93store_architecture) 型架构，内存中所有数据都需要先 *load* 进入寄存器才能进行操作，不能像 *x86* 一样直接对内存数据进行算术处理。

### 整数运算指令

RV32I的整数运算指令包括21条不同的指令，其指令编码方式参见表

![整数运算编码方式](_images/riscv-encoding.png)

这些整数运算指令所需要完成的操作参见表。

<table class="docutils align-default" id="tab-integerop">
<caption><span class="caption-number"></span><span class="caption-text">整数运算指令操作说明</span></caption>
<thead>
<tr class="row-odd"><th class="head">

指令
</th>
<th class="head">

行为
</th>
</tr>
</thead>
<tbody>
<tr class="row-even"><td>

lui rd,imm20
</td>
<td>

<span class="math notranslate nohighlight">将 20 位的立即数左移12位，低 12 位补零，并写回寄存器 rd 中</span>
</td>
</tr>
<tr class="row-odd"><td>

auipc rd,imm20
</td>
<td>

<span class="math notranslate nohighlight">将 20 位的立即数左移12位，低 12 位补零，将得到的 32 位数与 pc 的值相加，最后写回寄存器 rd 中</span>
</td>
</tr>
<tr class="row-even"><td>

addi rd,rs1,imm12
</td>
<td>

<span class="math notranslate nohighlight">立即数加法</span>
</td>
</tr>
<tr class="row-odd"><td>

slti rd,rs1,imm12
</td>
<td>

<span class="math notranslate nohighlight">立即数有符号小于比较</span>
</td>
</tr>
<tr class="row-even"><td>

sltiu rd,rs1,imm12
</td>
<td>

<span class="math notranslate nohighlight">立即数无符号小于比较</span>
</td>
</tr>
<tr class="row-odd"><td>

xori rd,rs1,imm12
</td>
<td>

<span class="math notranslate nohighlight">立即数逻辑异或</span>
</td>
</tr>
<tr class="row-even"><td>

ori rd,rs1,imm12
</td>
<td>

<span class="math notranslate nohighlight">立即数逻辑或</span>
</td>
</tr>
<tr class="row-odd"><td>

andi rd,rs1,imm12
</td>
<td>

<span class="math notranslate nohighlight">立即数逻辑与</span>
</td>
</tr>
<tr class="row-even"><td>

slli rd,rs1,shamt
</td>
<td>

<span class="math notranslate nohighlight">立即数逻辑左移</span>
</td>
</tr>
<tr class="row-odd"><td>

srli rd,rs1,shamt
</td>
<td>

<span class="math notranslate nohighlight">立即数逻辑右移</span>
</td>
</tr>
<tr class="row-even"><td>

srai rd,rs1,shamt
</td>
<td>

<span class="math notranslate nohighlight">立即数算数右移</span>
</td>
</tr>
<tr class="row-odd"><td>

add rd,rs1,rs2
</td>
<td>

<span class="math notranslate nohighlight">加法</span>
</td>
</tr>
<tr class="row-even"><td>

sub rd,rs1,rs2
</td>
<td>

<span class="math notranslate nohighlight">减法</span>
</td>
</tr>
<tr class="row-odd"><td>

sll rd,rs1,rs2
</td>
<td>

<span class="math notranslate nohighlight">逻辑左移</span>
</td>
</tr>
<tr class="row-even"><td>

slt rd,rs1,rs2
</td>
<td>

<span class="math notranslate nohighlight">有符号小于比较</span>
</td>
</tr>
<tr class="row-odd"><td>

sltu rd,rs1,rs2
</td>
<td>

<span class="math notranslate nohighlight">无符号小于比较</span>
</td>
</tr>
<tr class="row-even"><td>

xor rd,rs1,rs2
</td>
<td>

<span class="math notranslate nohighlight">逻辑异或</span>
</td>
</tr>
<tr class="row-odd"><td>

srl rd,rs1,rs2
</td>
<td>

<span class="math notranslate nohighlight">逻辑右移</span>
</td>
</tr>
<tr class="row-even"><td>

sra rd,rs1,rs2
</td>
<td>

<span class="math notranslate nohighlight">算数右移</span>
</td>
</tr>
<tr class="row-odd"><td>

or rd,rs1,rs2
</td>
<td>

<span class="math notranslate nohighlight">逻辑或</span>
</td>
</tr>
<tr class="row-even"><td>

and rd,rs1,rs2
</td>
<td>

<span class="math notranslate nohighlight">逻辑与</span>
</td>
</tr>
</tbody>
</table>

基本的整数运算指令并没有完全覆盖到所有的运算操作。RV32I中基本指令集可以通过伪指令或组合指令的方式来实现基本指令中未覆盖到的功能，具体可以参考 常见伪指令 节。


### 控制转移指令

RV32I中包含了6条分支指令和2条无条件转移指令。图列出了这些控制转移指令的编码方式。

![控制转移指令编码方式](/_images/branchcode.png)

<table class="docutils align-default" id="tab-branchop">
<caption><span class="caption-number"></span><span class="caption-text">控制转移指令操作说明</span></caption>
<thead>
<tr class="row-odd"><th class="head">

指令
</th>
<th class="head">

行为
</th>
</tr>
</thead>
<tbody>
<tr class="row-even"><td>

jal rd,imm20
</td>
<td>

<span class="math notranslate nohighlight">将 PC+4 的值保存到 rd 寄存器中，然后设置 PC = PC + offset</span>
</td>
</tr>
<tr class="row-odd"><td>

jalr rd,rs1,imm12
</td>
<td>

<span class="math notranslate nohighlight">将 PC+4 保存到 rd 寄存器中，然后设置 PC = rs1  + imm</span>
</td>
</tr>
<tr class="row-even"><td>

beq rs1,rs2,imm12
</td>
<td>

<span class="math notranslate nohighlight">相等跳转</span>
</td>
</tr>
<tr class="row-odd"><td>

bne rs1,rs2,imm12
</td>
<td>

<span class="math notranslate nohighlight">不等跳转</span>
</td>
</tr>
<tr class="row-even"><td>

blt rs1,rs2,imm12
</td>
<td>

<span class="math notranslate nohighlight">小于跳转</span>
</td>
</tr>
<tr class="row-odd"><td>

bge rs1,rs2,imm12
</td>
<td>

<span class="math notranslate nohighlight">大于等于跳转</span>
</td>
</tr>
<tr class="row-even"><td>

bltu rs1,rs2,imm12
</td>
<td>

<span class="math notranslate nohighlight">无符号小于跳转</span>
</td>
</tr>
<tr class="row-odd"><td>

bgeu rs1,rs2,imm12
</td>
<td>

<span class="math notranslate nohighlight">无符号大于等于跳转</span>
</td>
</tr>
</tbody>
</table>

### 存储器访问指令

RV32I提供了按字节、半字和字访问存储器的8条指令。所有访存指令的寻址方式都是寄存器间接寻址方式，访存地址可以不对齐4字节边界，但是在实现中可以要求访存过程中对齐4字节边界。在读取单个字节或半字时，可以按要求对内存数据进行符号扩展或无符号扩展后再存入寄存器。

![编码方式](_images/memcode.png)

<table class="docutils align-default" id="tab-memop">
<caption><span class="caption-number"></span><span class="caption-text">存储访问指令操作说明</span></caption>
<thead>
<tr class="row-odd"><th class="head">

指令
</th>
<th class="head">

行为
</th>
</tr>
</thead>
<tbody>
<tr class="row-even"><td>

lb rd,imm12(rs1)
</td>
<td>
<span class="math notranslate nohighlight">字节加载</span>
</td>
</tr>
<tr class="row-odd"><td>

lh rd,imm12(rs1)
</td>
<td>
<span class="math notranslate nohighlight">半字加载</span>
</td>
</tr>
<tr class="row-even"><td>

lw rd,imm12(rs1)
</td>
<td>
<span class="math notranslate nohighlight">字加载</span>
</td>
</tr>
<tr class="row-odd"><td>

lbu rd,imm12(rs1)
</td>
<td>
<span class="math notranslate nohighlight">无符号字节加载</span>
</td>
</tr>
<tr class="row-even"><td>

lhu rd,imm12(rs1)
</td>
<td>
<span class="math notranslate nohighlight">无符号半字加载</span>
</td>
</tr>
<tr class="row-odd"><td>

sb rs2,imm12(rs1)
</td>
<td>
<span class="math notranslate nohighlight">字节储存</span>
</td>
</tr>
<tr class="row-even"><td>

sh rs2,imm12(rs1)
</td>
<td>
<span class="math notranslate nohighlight">半字储存</span>
</td>
</tr>
<tr class="row-odd"><td>

sw rs2,imm12(rs1)
</td>
<td>
<span class="math notranslate nohighlight">字储存</span>
</td>
</tr>
</tbody>
</table>
</section>
<section id="id7">

### 常见伪指令

RISC-V中规定了一些常用的伪指令。这些伪指令一般可以在汇编程序中使用，汇编器会将其转换成对应的指令序列。表介绍了RISC-V的常见伪指令列表。

<table class="docutils align-default" id="tab-pseudocode">
<caption><span class="caption-number"></span><span class="caption-text">常见伪指令说明</span></caption>
<thead>
<tr class="row-odd"><th class="head">

伪指令
</th>
<th class="head">

实际指令序列
</th>
<th class="head">

操作
</th>
</tr>
</thead>
<tbody>
<tr class="row-even"><td>

nop
</td>
<td>

addi x0, x0, 0
</td>
<td>

空操作
</td>
</tr>
<tr class="row-odd"><td>

li rd,imm
</td>
<td><div class="line-block">
<div class="line">lui rd, imm[32:12]+imm[11]</div>
<div class="line">addi rd, rd, imm[11:0]</div>
</div>
</td>
<td><div class="line-block">
<div class="line">加载32位立即数，先加载高位，</div>
<div class="line">再加上低位，注意低位是符号扩展</div>
</div>
</td>
</tr>
<tr class="row-even"><td>

mv rd, rs
</td>
<td>

addi rd, rs
</td>
<td>

寄存器拷贝
</td>
</tr>
<tr class="row-odd"><td>

not rd, rs
</td>
<td>

xori rd, rs, -1
</td>
<td>

取反操作
</td>
</tr>
<tr class="row-even"><td>

neg rd, rs
</td>
<td>

sub  rd, x0, rs
</td>
<td>

取负操作
</td>
</tr>
<tr class="row-odd"><td>

seqz rd, rs
</td>
<td>

sltiu rd, rs, 1
</td>
<td>

等于0时置位
</td>
</tr>
<tr class="row-even"><td>

snez rd, rs
</td>
<td>

sltu rd, x0, rs
</td>
<td>

不等于0时置位
</td>
</tr>
<tr class="row-odd"><td>

sltz rd, rs
</td>
<td>

slt rd, rs, x0
</td>
<td>

小于0时置位
</td>
</tr>
<tr class="row-even"><td>

sgtz rd, rs
</td>
<td>

slt rd, x0, rs
</td>
<td>

大于0时置位
</td>
</tr>
<tr class="row-odd"><td>

beqz rs, offset
</td>
<td>

beq rs, x0, offset
</td>
<td>

等于0时跳转
</td>
</tr>
<tr class="row-even"><td>

bnez rs, offset
</td>
<td>

bne rs, x0, offset
</td>
<td>

不等于0时跳转
</td>
</tr>
<tr class="row-odd"><td>

blez rs, offset
</td>
<td>

bge x0, rs, offset
</td>
<td>

小于等于0时跳转
</td>
</tr>
<tr class="row-even"><td>

bgez rs, offset
</td>
<td>

bge rs, x0, offset
</td>
<td>

大于等于0时跳转
</td>
</tr>
<tr class="row-odd"><td>

bltz rs, offset
</td>
<td>

blt rs, x0, offset
</td>
<td>

小于0时跳转
</td>
</tr>
<tr class="row-even"><td>

bgtz rs, offset
</td>
<td>

blt x0, rs, offset
</td>
<td>

大于0时跳转
</td>
</tr>
<tr class="row-odd"><td>

bgt rs, rt, offset
</td>
<td>

blt rt, rs, offset
</td>
<td>

rs大于rt时跳转
</td>
</tr>
<tr class="row-even"><td>

ble rs, rt, offset
</td>
<td>

bge rt, rs, offset
</td>
<td>

rs小于等于rt时跳转
</td>
</tr>
<tr class="row-odd"><td>

bgtu rs, rt, offset
</td>
<td>

bltu rt, rs, offset
</td>
<td>

无符号rs大于rt时跳转
</td>
</tr>
<tr class="row-even"><td>

bleu rs, rt, offset
</td>
<td>

bgeu rt, rs, offset
</td>
<td>

无符号rs小于等于rt时跳转
</td>
</tr>
<tr class="row-odd"><td>

j offset
</td>
<td>

jal x0, offset
</td>
<td>

无条件跳转，不保存地址
</td>
</tr>
<tr class="row-even"><td>

jal offset
</td>
<td>

jal x1, offset
</td>
<td>

无条件跳转，地址缺省保存在x1
</td>
</tr>
<tr class="row-odd"><td>

jr rs
</td>
<td>

jalr x0, 0 (rs)
</td>
<td>

无条件跳转到rs寄存器，不保存地址
</td>
</tr>
<tr class="row-even"><td>

jalr rs
</td>
<td>

jalr x1, 0 (rs)
</td>
<td>

无条件跳转到rs寄存器，地址缺省保存在x1
</td>
</tr>
<tr class="row-odd"><td>

ret
</td>
<td>

jalr x0, 0 (x1)
</td>
<td>

函数调用返回
</td>
</tr>
<tr class="row-even"><td>

call offset
</td>
<td><div class="line-block">
<div class="line">aupic x1, offset[32:12]+offset[11]</div>
<div class="line">jalr x1, offset[11:0] (x1)</div>
</div>
</td>
<td>

调用远程子函数
</td>
</tr>
<tr class="row-odd"><td>

la rd, symbol
</td>
<td><div class="line-block">
<div class="line">aupic rd, delta[32:12]+delta[11]</div>
<div class="line">addi rd, rd, delta[11:0]</div>
</div>
</td>
<td>

载入全局地址，其中detla是PC和全局符号地址的差
</td>
</tr>
<tr class="row-even"><td>

lla rd, symbol
</td>
<td><div class="line-block">
<div class="line">aupic rd, delta[32:12]+delta[11]</div>
<div class="line">addi rd, rd, delta[11:0]</div>
</div>
</td>
<td>

载入局部地址，其中detla是PC和局部符号地址的差
</td>
</tr>
<tr class="row-odd"><td>

l{b|h|w} rd, symbol
</td>
<td><div class="line-block">
<div class="line">aupic rd, delta[32:12]+delta[11]</div>
<div class="line">l{b|h|w} rd, delta[11:0] (rd)</div>
</div>
</td>
<td>

载入全局变量
</td>
</tr>
<tr class="row-even"><td>

s{b|h|w} rd, symbol, rt
</td>
<td><div class="line-block">
<div class="line">aupic rd, delta[32:12]+delta[11]</div>
<div class="line">s{b|h|w} rd, delta[11:0] (rt)</div>
</div>
</td>
<td>

载入局部变量
</td>
</tr>
</tbody>
</table>
</section>
</section>
<section id="id8">

# RV32I 电路实现

## 单周期电路设计

在了解了RV32I指令集的指令体系结构（Instruction Set Architecture，ISA)之后，我们将着手设计CPU的微架构（micro architecture）。

同样的一套指令体系结构可以用完全不同的微架构来实现。不同的微架构在实现的时候只要保证程序员可见的状态，即PC、通用寄存器和内存等，在指令执行过程中遵守ISA中的规定即可。具体微架构的实现可以自由发挥。

在本实验中，我们首先来实现单周期CPU的微架构。所谓单周期CPU是指CPU在每一个时钟周期中需要完成一条指令的所有操作，即每个时钟周期完成一条指令。

每条指令的执行过程一般需要以下几个步骤：

> <div>
> 
> 1.  **取指** ：使用本周期新的PC从指令存储器中取出指令，并将其放入指令寄存器（IR）中
> 
> 2.  **译码** ：对取出的指令进行分析，生成本周期执行指令所需的控制信号，并计算下一条指令的地址，从寄存器堆中读取寄存器操作数，并完成立即数的生成
> 
> 
> 3.  **运算** ：利用ALU对操作数进行必要的运算
> 
> 4.  **访存** ：包括读取或写入内存对应地址的内容
> 
> 5.  **写回** ：将最终结果写回到目的寄存器中
> </div>

每条指令执行过程中的以上几个步骤需要CPU的控制通路和数据通路配合来完成。

其中控制通路主要负责控制信号的生成，通过控制信号来指示数据通路完成具体的数据操作。
数据通路是具体完成数据存取、运算的部件。

控制通路和数据通路分离的开发模式在数字系统中经常可以碰到。其设计的基本指导原则是：控制通路要足够灵活，并能够方便地修改和添加功能，控制通路的性能和时延往往不是优化重点。

反过来，数据通路需要简单且性能强大。数据通路需要以可靠的方案，快速地移动和操作大量数据。
在一个简单且性能强大的数据通路支持下，控制通路可以灵活地通过控制信号的组合来实现各种不同的应用。

图提供了RV32I单周期CPU的参考设计。下面我们就针对该CPU的控制通路和数据通路来分别进行说明 

**有改动的地方，仅作大致参考**


![单周期设计图](/_images/rv32isingle.png)

### 控制通路

#### PC生成

程序计数器 *PC* 控制了整个 *CPU* 指令执行的顺序。在顺序执行的条件下，下一周期的 *PC* 为本周期 *PC+4* 。如果发生跳转，PC将会变成跳转目标地址。

本设计中每个时钟周期是以时钟信号 *CLK* 的上升沿为起点的。在上一周期结束前，利用组合逻辑电路生成本周期将要执行的指令的地址 *NextPC* 。

在时钟上升沿到达时，将 *NEXT PC* 同时加载到 *PC* 寄存器和指令存储器的地址缓冲中去，完成本周期指令执行的第一步。

*NextPC* 的计算涉及到指令译码和跳转分析，后续在 **跳转控制** 节中会详细描述。

在系统 *reset* 或刚刚上电时，可以将 *PC* 设置为固定的地址，如全零，让系统从特定的启动代码开始执行。

### 指令存储器

指令寄存器 *Instruction Memory* 专门用来存放指令。虽然在冯诺伊曼结构中指令和数据是存放在统一的存储器中，但大多数现代 *CPU* 是将指令缓存和数据缓存分开的。在本实验中我们也将指令和数据分开存储。

本实验中的指令存储器类似 *CPU* 中的指令缓存。本设计采用时钟上升沿来对指令存储器进行读取操作，指令存储器的读取地址是 *PC*。

指令存储器只需要支持读操作，由于指令存储器每次总是读取 *4* 个字节，所以可以将存储器的每个单元大小设置为 *32bit*。


#### 指令译码及立即数生成

在读取出本周期的指令 *instr[31:0]* 之后，*CPU* 将对 *32bit* 的指令进行译码，并产生各个指令对应的立即数。

RV32I的指令比较规整，所以可以直接取指令对应的bit做为译码结果：

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="k">assign</span><span class="w">  </span><span class="n">op</span><span class="w">  </span><span class="o">=</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">6</span><span class="o">:</span><span class="mh">0</span><span class="p">];</span>
<span class="k">assign</span><span class="w">  </span><span class="n">rs1</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">19</span><span class="o">:</span><span class="mh">15</span><span class="p">];</span>
<span class="k">assign</span><span class="w">  </span><span class="n">rs2</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">24</span><span class="o">:</span><span class="mh">20</span><span class="p">];</span>
<span class="k">assign</span><span class="w">  </span><span class="n">rd</span><span class="w">  </span><span class="o">=</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">11</span><span class="o">:</span><span class="mh">7</span><span class="p">];</span>
<span class="k">assign</span><span class="w">  </span><span class="n">func3</span><span class="w">  </span><span class="o">=</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">14</span><span class="o">:</span><span class="mh">12</span><span class="p">];</span>
<span class="k">assign</span><span class="w">  </span><span class="n">func7</span><span class="w">  </span><span class="o">=</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">31</span><span class="o">:</span><span class="mh">25</span><span class="p">];</span>
</pre></div>
</div>

同样的，也可以利用立即数生成器 *imm Generator* 生成所有的立即数。注意，所有立即数均是符号扩展，且符号位总是 *instr[31]* :

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="k">assign</span><span class="w"> </span><span class="n">immI</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="p">{{</span><span class="mh">20</span><span class="p">{</span><span class="n">instr</span><span class="p">[</span><span class="mh">31</span><span class="p">]}},</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">31</span><span class="o">:</span><span class="mh">20</span><span class="p">]};</span>
<span class="k">assign</span><span class="w"> </span><span class="n">immU</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="p">{</span><span class="n">instr</span><span class="p">[</span><span class="mh">31</span><span class="o">:</span><span class="mh">12</span><span class="p">],</span><span class="w"> </span><span class="mh">12</span><span class="mb">&#39;b0</span><span class="p">};</span>
<span class="k">assign</span><span class="w"> </span><span class="n">immS</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="p">{{</span><span class="mh">20</span><span class="p">{</span><span class="n">instr</span><span class="p">[</span><span class="mh">31</span><span class="p">]}},</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">31</span><span class="o">:</span><span class="mh">25</span><span class="p">],</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">11</span><span class="o">:</span><span class="mh">7</span><span class="p">]};</span>
<span class="k">assign</span><span class="w"> </span><span class="n">immB</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="p">{{</span><span class="mh">20</span><span class="p">{</span><span class="n">instr</span><span class="p">[</span><span class="mh">31</span><span class="p">]}},</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">7</span><span class="p">],</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">30</span><span class="o">:</span><span class="mh">25</span><span class="p">],</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">11</span><span class="o">:</span><span class="mh">8</span><span class="p">],</span><span class="w"> </span><span class="mh">1</span><span class="mb">&#39;b0</span><span class="p">};</span>
<span class="k">assign</span><span class="w"> </span><span class="n">immJ</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="p">{{</span><span class="mh">12</span><span class="p">{</span><span class="n">instr</span><span class="p">[</span><span class="mh">31</span><span class="p">]}},</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">19</span><span class="o">:</span><span class="mh">12</span><span class="p">],</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">20</span><span class="p">],</span><span class="w"> </span><span class="n">instr</span><span class="p">[</span><span class="mh">30</span><span class="o">:</span><span class="mh">21</span><span class="p">],</span><span class="w"> </span><span class="mh">1</span><span class="mb">&#39;b0</span><span class="p">};</span>
</pre></div>
</div>

在生成各类指令的立即数之后，根据控制信号 *ExtOP* ，通过多路选择器来选择立即数生成器最终输出的 *imm* 是以上五种类型中的哪一个。

<table class="docutils align-default" id="tab-extop">
<caption><span class="caption-number"></span><span class="caption-text">控制信号ExtOP的含义</span></caption>
<thead>
<tr class="row-odd"><th class="head">

ExtOP
</th>
<th class="head">

立即数类型
</th>
</tr>
</thead>
<tbody>
<tr class="row-even"><td>

000
</td>
<td>

immI
</td>
</tr>
<tr class="row-odd"><td>

001
</td>
<td>

immU
</td>
</tr>
<tr class="row-even"><td>

010
</td>
<td>

immS
</td>
</tr>
<tr class="row-odd"><td>

011
</td>
<td>

immB
</td>
</tr>
<tr class="row-even"><td>

100
</td>
<td>

immJ
</td>
</tr>
</tbody>
</table>

![../_images/controlpart1.png](../_images/controlpart1.png)


<span class="caption-number">Fig. 78 </span><span class="caption-text">RV32I指令控制信号列表第一部分</span>

![../_images/controlpart2.png](../_images/controlpart2.png)

<span class="caption-number">Fig. 79 </span><span class="caption-text">RV32I指令控制信号列表第二部分</span>



#### 控制信号生成

在确定指令类型后，需要生成每个指令对应的控制信号，来控制数据通路部件进行对应的动作。控制信号生产部件 *Control Signal Generator* 是根据 *instr* 中的操作码 *opcode* ，及 *func3* 和 *func7* 来生成对应的控制信号的。

生成的控制信号具体包括：

*   **extOP** :宽度为3bit，选择立即数产生器的输出类型。

*   **write_reg** ：宽度为1bit，控制是否对寄存器rd进行写回，为1时写回寄存器。

*   **rs1Data_EX_PC** ：宽度为1bit，选择ALU输入端A的来源。为0时选择rs1，为1时选择PC。

*   **rs2Data_EX_imm32_4** ：宽度为2bit，选择ALU输入端B的来源。为00时选择rs2，为01时选择imm(当是立即数移位指令时，只有低5位有效)，为10时选择常数4（用于跳转时计算返回地址PC+4）。

*   **aluc** ：宽度为5bit，选择ALU执行的操作。

*   **pcImm_NEXTPC_rs1Imm** ：宽度为2bit，无条件跳转信号，01时选择pc + imm，10时选择rs1Data + imm。

*   **aluOut_WB_memOut** ：宽度为1bit，选择寄存器rd写回数据来源，为0时选择ALU输出，为1时选择数据存储器输出。

*   **write_mem** ：宽度为2bit，控制是否对数据存储器进行写入，为01时按字写回存储器，10时按半字写回存储器，11时按字节写回存储器。

*   **read_mem** ：宽度为3bit，控制数据存储器读格式。最高位为1时带符号读，为0时无符号读。低二位为00时直接返回32'b0，为01时为4字节读（无需判断符号），为10时为2字节读，为11时为1字节读。

这些控制信号控制各个数据通路部件按指令的要求进行对应的操作。所有指令对应的控制信号列表如表 [<span class="std std-numref">Fig. 78</span>](#fig-controlpart1) 和表 [<span class="std std-numref">Fig. 79</span>](#fig-controlpart2) 所示。
根据这些控制信号可以得出系统在给定指令下的一个周期内所需要做的具体操作。
注意：这里的控制信号在定义上可能和教科书上的9条指令CPU控制信号有一些区别。
如果没有学习过组成原理的同学请参考相关教科书，分析各类指令在给定控制信号下的数据通路的具体操作。这里只进行一个简略的说明：

*   **lui** : ALU A输入端不用，B输入端为立即数，按U-Type扩展，ALU执行的操作是拷贝B输入，ALU结果写回到rd。

*   **auipc** ：ALU A输入端为PC，B输入端为立即数，按U-Type扩展，ALU执行的操作是加法，ALU结果写回到rd。

*   **立即数运算类指令** ：ALU A输入端为rs1，B输入端为立即数，按I-Type扩展。ALU按ALUctr进行操作，ALU结果写回rd。

*   **寄存器运算类指令** ：ALU A输入端为rs1，B输入端为rs2。ALU按ALUctr进行操作，ALU结果写回rd。

*   **jal** : ALU A输入端PC，B输入端为常数4，ALU执行的操作是计算PC+4，ALU结果写回到rd。PC计算通过专用加法器，计算PC+imm，imm为J-Type扩展。

*   **jalr** : ALU A输入端PC，B输入端为常数4，ALU执行的操作是计算PC+4，ALU结果写回到rd。PC计算通过专用加法器，计算rs1+imm，imm为I-Type扩展。

*   **Branch类指令** : ALU A输入端为rs1，B输入端为rs2，ALU执行的操作是比较大小或判零，根据ALU标志位选择NextPC，可能是PC+4或PC+imm，imm为B-Type扩展，PC计算由专用加法器完成。不写回寄存器。

*   **Load类指令** :ALU A输入端为rs1，B输入端为立即数，按I-Type扩展。ALU做加法计算地址，读取内存，读取内存方式由存储器具体执行，内存输出写回rd。

*   **Store类指令** :ALU A输入端为rs1，B输入端为立即数，按S-Type扩展。ALU做加法计算地址，将rs2内容写入内存，不写回寄存器。
</section>
<section id="id14">

### 跳转控制

代码执行过程中，NextPC可能会有多种可能性：

> <div>
> 
> *   顺序执行：NextPC = PC + 4；
> 
> *   jal： NextPC = PC + imm;
> 
> *   jalr： NextPC = rs1Data + imm;
> 
> *   条件跳转： 根据ALU的condition_branch来判断，NextPC可能是PC + 4或者 PC + imm；
> </div>


    module next_pc(
    input [1: 0] pcImm_NEXTPC_rs1Imm,
    input condition_branch,
    input [31: 0] pc, offset, rs1Data,

    output reg [31: 0] next_pc
    );

    always @(*) begin
        if(pcImm_NEXTPC_rs1Imm == 2'b01) next_pc = pc + offset;
        else if(pcImm_NEXTPC_rs1Imm == 2'b10) next_pc = rs1Data + offset;
        else if(condition_branch) next_pc = pc + offset;
        else if(pc == 32'h6c) next_pc = 32'h6c; // CPU空转
        else next_pc = pc + 4;
    end

    endmodule

#### 数据通路

单周期数据通路可以复用上个实验中设计的寄存器堆、ALU和数据存储器，这里就不再详细描述。


#### 单周期CPU的时序设计

在单周期 *CPU* 中，所有操作均需要在一个周期内完成。其中单周期存储部件的读写是时序设计的关键。在 *CPU* 架构中 *PC* 、寄存器堆，指令存储器和数据存储器都是状态部件，需要用寄存器或存储器来实现。

对指令存储器和数据存储器来说，一般系统至少需要数百KB的容量。此时建议用时钟沿来控制读写。假定我们是以时钟上升延为每个时钟周期的开始。对于存储器和寄存器的写入统一安排在上升沿上进行。

> <div>
> 
> *   周期开始的上升沿将 *next_pc* 写入 *PC* 寄存器，*pc* 读取指令存储器。
> 
> *   指令读出后将出现在指令存储器的输出端，该信号可以通过组合逻辑来进行指令译码，产生控制信号，寄存器读写地址及立即数等。
> 
> *   寄存器读地址产生后，直接通过非同步读取方式，读取两个源寄存器的数据，与立即数操作数一起准备好，进入ALU的输入端。
> 
> *   ALU也是组合逻辑电路，在输入端数据准备好后就开始运算。
> 
> *   数据存储器的读地址如果准备好了，就可以在上升沿进行内存读取操作。
> 
> *   最后，同时对目的寄存器和数据存储器进行写入操作。这样下一周期这些存储器中的数据就是最新的了。
> </div>

#### 模块化设计

CPU设计过程中需要多个不同的模块分工协作，建议在开始编码前划分好具体模块的功能和接口。对于模块划分提供了以下的参考建议。顶层实体内包含的模块主要是：

*   **CPU模块** ：主要对外接口包括时钟、Reset、指令存储器的地址/数据线、数据存储器的地址及数据线和自行设计的调试信号。

        *   ALU模块:主要对外接口是ALU的输入操作数、ALU控制字、ALU结果输出和标志位输出等。

            *   加法器模块

                *   桶型移位器模块

        *   寄存器堆模块：主要对外接口是读写寄存器号输入、写入数据输入、寄存器控制信号、写入时钟、输出数据。

        *   控制信号生成模块：主要对外接口是指令输入及各种控制信号输出。

        *   立即数生成器模块：主要对外接口是指令输入，立即数类型及立即数输出。

        *   跳转控制模块：主要对外接口是ALU标志位输入、跳转控制信号输入及PC选择信号输出。

        *   PC生成模块：主要对外接口是PC输入、立即数输入，rs1输入，PC选择信号及NEXTPC输出。

*   **指令存储器模块** ：主要对外接口包括时钟、地址线和输出数据线。

*   **数据存储器模块** ：主要对外接口包括时钟、输入输出地址线、输入输出数据、内存访问控制信号和写使能信号。

*   **外围设备** ：用于Reset或显示调试结果等等。

以上模块划分不是唯一的，同学们可以按照自己的理解进行划分。
设计中将存储器部分与CPU分开放在顶层的主要目的是在后续的计算机系统实验中简化外设对存储器的访问。
设计时请先划分模块，确认模块的连接，再单独开发各个模块，建议对模块进行单元测试后再整合系统。

### 单周期测试部分

RISC-V CPU是一个较为复杂的数字系统，在开发过程中需要对每一个环节进行详细的测试才能够保证系统整体的可靠性。

测试部分需要查看波形图，我所用的软件是 **Vivado 2023.1**，不过这玩意简直是纯粹的电子垃圾，压缩包大小有 **100G**，由于我们只需查看波形，用不到太多功能，所以你也可以选择其他软件查看波形。

下载地址：[Vivado 2023.1](https://soc.ustc.edu.cn/Digital/lab0/vivado/)

如果你需要编写 *C* 语言尝试运行，需要 *Linux* 操作系统并安装 *riscv* 指令集所对应的 *gcc* 。因为我们的电脑是 *x86* 指令集，需要交叉编译。

    $ sudo apt update
    $ sudo apt install build-essential gcc make perl dkms git gcc-riscv64-unknown-elf gdb-multiarch qemu-system-misc

注意请在 *Linux* 上运行，这是我在学习 *riscv* 操作系统时偷来的

传送门：[循序渐进，学习开发一个RISC-V上的操作系统 - 汪辰 - 2021春](https://www.bilibili.com/video/BV1Q5411w7z5)

#### 指令测试

在开发过程中，需要首先确保每一个指令都正常工作，因此在完成各个指令控制器代码编写后需要进行对应的测试，是否可以正常工作

#### 行为仿真

在完成基本指令测试后，可以进行 *CPU* 整体的联调。整体联调的主要目的是验证各个指令基本功能的正确性，可以自己编写简单的 *C* 语言代码编译链接后生成机器代码单步测试。

生成可执行文件，我们还需要一个链接脚本，本来这是可有可无的，但我们需要指令所在的地址从 *0* 开始，方便我们对照。

**script.ld**

    ENTRY(_start)

    SECTIONS
    {
        . = 0;

        .text :
        {
            *(.text)
        }

        .data :
        {
            *(.data)
        }

        .bss :
        {
            *(.bss)
        }
    }

**main.c**

    void fun(int *x) {
        *x += 10;
        return;
    }

    int main() {
        int x = 1;
        fun(&x);
        return 0;
    }

**生成可执行文件**

    riscv64-unknown-elf-gcc -nostdlib -fno-builtin -march=rv32g -mabi=ilp32 -g -Wall main.c -o main.elf -T script.ld

**反汇编生成机器代码**

    riscv64-unknown-elf-objdump -d main.elf > main.s

**main.s**

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

**未完待续**