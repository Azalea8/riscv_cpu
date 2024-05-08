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

图提供了RV32I单周期CPU的参考设计，下面我们就针对该CPU的控制通路和数据通路来分别进行说明。


![单周期设计图](/_images/rv32isingle.png)

### 控制通路

#### PC生成

程序计数器 *PC* 控制了整个 *CPU* 指令执行的顺序。在顺序执行的条件下，下一周期的 *PC* 为本周期 *PC+4* 。如果发生跳转，PC将会变成跳转目标地址。

本设计中每个时钟周期是以时钟信号 *CLK* 的上升沿为起点的。在上一周期结束前，利用组合逻辑电路生成本周期将要执行的指令的地址 *NextPC* 。

在时钟上升沿到达时，将 *NEXT PC* 同时加载到 *PC* 寄存器和指令存储器的地址缓冲中去，完成本周期指令执行的第一步。

*NextPC* 的计算涉及到指令译码和跳转分析，后续在 **跳转控制** 节中会详细描述。

在系统 *reset* 或刚刚上电时，可以将 *PC* 设置为固定的地址，如全零，让系统从特定的启动代码开始执行。

### 指令存储器

指令寄存器 *Instruction Memory* 专门用来存放指令。虽然在冯诺伊曼结构中指令和数据是存放在统一的存储器中，但大多数现代CPU是将指令缓存和数据缓存分开的。在本实验中我们也将指令和数据分开存储。

本实验中的指令存储器类似 *CPU* 中的指令缓存。本设计采用时钟上升沿来对指令存储器进行读取操作，指令存储器的读取地址是 *PC*。

指令存储器只需要支持读操作，在本实验中，可以要求所有代码都是 *4* 字节对齐，即 *PC* 低两位可以认为总是2’b00。由于指令存储器每次总是读取 *4* 个字节，所以可以将存储器的每个单元大小设置为 *32bit*。


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

*   **ExtOP** :宽度为3bit，选择立即数产生器的输出类型。

*   **RegWr** ：宽度为1bit，控制是否对寄存器rd进行写回，为1时写回寄存器。

*   **ALUAsrc** ：宽度为1bit，选择ALU输入端A的来源。为0时选择rs1，为1时选择PC。

*   **ALUBsrc** ：宽度为2bit，选择ALU输入端B的来源。为00时选择rs2，为01时选择imm(当是立即数移位指令时，只有低5位有效)，为10时选择常数4（用于跳转时计算返回地址PC+4）。

*   **ALUctr** ：宽度为4bit，选择ALU执行的操作，具体含义参见表 [<span class="std std-numref">Table 10</span>](10.html#tab-aluctr) 。

*   **Branch** ：宽度为3bit，说明分支和跳转的种类，用于生成最终的分支控制信号，含义参见表 [<span class="std std-numref">Table 18</span>](#tab-branch) 。

*   **MemtoReg** ：宽度为1bit，选择寄存器rd写回数据来源，为0时选择ALU输出，为1时选择数据存储器输出。

*   **MemWr** ：宽度为1bit，控制是否对数据存储器进行写入，为1时写回存储器。

*   **MemOP** ：宽度为3bit，控制数据存储器读写格式，为010时为4字节读写，为001时为2字节读写带符号扩展，为000时为1字节读写带符号扩展，为101时为2字节读写无符号扩展，为100时为1字节读写无符号扩展。

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

### 跳转控制[](#id14 "Permalink to this heading")

代码执行过程中，NextPC可能会有多种可能性：

> <div>
> 
> *   顺序执行：NextPC = PC + 4；
> 
> *   jal： NextPC = PC + imm;
> 
> *   jalr： NextPC = rs1 + imm;
> 
> *   条件跳转： 根据ALU的Zero和Less来判断，NextPC可能是PC + 4或者 PC + imm；
> </div>

在设计中使用一个单独的专用加法器来进行PC的计算。同时，利用了跳转控制模块来生成加法器输入选择。其中，PCAsrc控制PC加法器输入A的信号，为0时选择常数4，为1时选择imm。
PCBsrc控制PC加法器输入B的信号，为0时选择本周期PC，为1时选择寄存器rs1。

跳转控制模块根据控制信号Branch和ALU输出的Zero及Less信号来决定PCASrc和PCBsrc。其中控制信号Branch的定义如表 [<span class="std std-numref">Table 18</span>](#tab-branch) 所示。
跳转控制模块的输出见表 [<span class="std std-numref">Table 19</span>](#tab-branchrst) 。

<table class="docutils align-default" id="tab-branch">
<caption><span class="caption-number">Table 18 </span><span class="caption-text">控制信号Branch的含义</span>[](#tab-branch "Permalink to this table")</caption>
<thead>
<tr class="row-odd"><th class="head">

Branch
</th>
<th class="head">

跳转类型
</th>
</tr>
</thead>
<tbody>
<tr class="row-even"><td>

000
</td>
<td>

非跳转指令
</td>
</tr>
<tr class="row-odd"><td>

001
</td>
<td>

无条件跳转PC目标
</td>
</tr>
<tr class="row-even"><td>

010
</td>
<td>

无条件跳转寄存器目标
</td>
</tr>
<tr class="row-odd"><td>

100
</td>
<td>

条件分支，等于
</td>
</tr>
<tr class="row-even"><td>

101
</td>
<td>

条件分支，不等于
</td>
</tr>
<tr class="row-odd"><td>

110
</td>
<td>

条件分支，小于
</td>
</tr>
<tr class="row-even"><td>

111
</td>
<td>

条件分支，大于等于
</td>
</tr>
</tbody>
</table>
<table class="docutils align-default" id="tab-branchrst">
<caption><span class="caption-number">Table 19 </span><span class="caption-text">PC加法器输入选择逻辑</span>[](#tab-branchrst "Permalink to this table")</caption>
<thead>
<tr class="row-odd"><th class="head">

Branch
</th>
<th class="head">

Zero
</th>
<th class="head">

Less
</th>
<th class="head">

PCAsrc
</th>
<th class="head">

PCBsrc
</th>
<th class="head">

NextPC
</th>
</tr>
</thead>
<tbody>
<tr class="row-even"><td>

000
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

0
</td>
<td>

0
</td>
<td>

PC + 4
</td>
</tr>
<tr class="row-odd"><td>

001
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

1
</td>
<td>

0
</td>
<td>

PC + imm
</td>
</tr>
<tr class="row-even"><td>

010
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

1
</td>
<td>

1
</td>
<td>

rs1 + imm
</td>
</tr>
<tr class="row-odd"><td>

100
</td>
<td>

0
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

0
</td>
<td>

0
</td>
<td>

PC + 4
</td>
</tr>
<tr class="row-even"><td>

100
</td>
<td>

1
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

1
</td>
<td>

0
</td>
<td>

PC + imm
</td>
</tr>
<tr class="row-odd"><td>

101
</td>
<td>

0
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

1
</td>
<td>

0
</td>
<td>

PC + imm
</td>
</tr>
<tr class="row-even"><td>

101
</td>
<td>

1
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

0
</td>
<td>

0
</td>
<td>

PC + 4
</td>
</tr>
<tr class="row-odd"><td>

110
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

0
</td>
<td>

0
</td>
<td>

0
</td>
<td>

PC + 4
</td>
</tr>
<tr class="row-even"><td>

110
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

1
</td>
<td>

1
</td>
<td>

0
</td>
<td>

PC + imm
</td>
</tr>
<tr class="row-odd"><td>

111
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

0
</td>
<td>

1
</td>
<td>

0
</td>
<td>

PC + imm
</td>
</tr>
<tr class="row-even"><td>

111
</td>
<td>

<span class="math notranslate nohighlight">\(\times\)</span>
</td>
<td>

1
</td>
<td>

0
</td>
<td>

0
</td>
<td>

PC + 4
</td>
</tr>
</tbody>
</table>
</section>
<section id="id15">

### 数据通路[](#id15 "Permalink to this heading")

单周期数据通路可以复用上个实验中设计的寄存器堆、ALU和数据存储器，这里就不再详细描述。

</section>
<section id="cpu">

### 单周期CPU的时序设计[](#cpu "Permalink to this heading")

在单周期CPU中，所有操作均需要在一个周期内完成。其中单周期存储部件的读写是时序设计的关键。在CPU架构中PC、寄存器堆，指令存储器和数据存储器都是状态部件，需要用寄存器或存储器来实现。
在实验五中，我们也看到，如果要求上述存储部件以非同步方式进行读写会消耗大量资源，无法实现大容量的存储。因此，需要仔细地规划各个存储器的读写时序和实现方式。

图 [<span class="std std-numref">Fig. 80</span>](#fig-timesingle) 描述了本实验建议的时序设计方案。在该设计中，PC和寄存器堆由于容量不大，可以采用非同步方式读取，即地址改变后立即输出对应的数据。
对指令存储器和数据存储器来说，一般系统至少需要数百KB的容量。此时建议用时钟沿来控制读写。假定我们是以时钟下降延为每个时钟周期的开始。对于存储器和寄存器的写入统一安排在下降沿上进行。
对于数据存储器的读出，由于地址计算有一定延时，可以在时钟上升沿进行读取。

下面通过图 [<span class="std std-numref">Fig. 80</span>](#fig-timesingle) 来描述单个时钟周期内CPU的具体动作。其中绿色部分为本周期正确数据，黄色为上一周期的旧数据，蓝色为下一周期的未来数据。

> <div>
> 
> *   周期开始的下降沿将同时用于写入PC寄存器和读取指令存储器。由于指令存储器要在下降沿进行读取操作，而PC的输出要等到下降沿后才能更新，所以不能拿PC的输出做为指令存储器的地址。可以采用PC寄存器的输入，NextPC来做为指令存储器的地址。该信号是组合逻辑，一般在上个周期末就已经准备好。
> 
> *   指令读出后将出现在指令存储器的输出端，该信号可以通过组合逻辑来进行指令译码，产生控制信号，寄存器读写地址及立即数等。
> 
> *   寄存器读地址产生后，直接通过非同步读取方式，读取两个源寄存器的数据，与立即数操作数一起准备好，进入ALU的输入端。
> 
> *   ALU也是组合逻辑电路，在输入端数据准备好后就开始运算。由于数据存储器的读取地址也是ALU来计算的，所以要求ALU输出结果能在时钟半个周期的上升沿到来之前准备好。
> 
> *   时钟上升沿到来的时候，数据存储器的读地址如果准备好了，就可以在上升沿进行内存读取操作。
> 
> *   最后，在下一周期的时钟下降沿到来的时候，同时对目的寄存器和数据存储器进行写入操作。这样下一周期这些存储器中的数据就是最新的了。
> </div>

实验采用的DE10-Standard开发板上的M10K支持读写时钟分离的ram，且能够在主时钟50MHz下进行单周期读写操作。在此时序设计下，主要的关键路径在Load指令的读取地址生成，该路径需要在半个周期内完成，如果出现时序无法满足的情况，可以考虑降低时钟频率。

<figure class="align-default" id="fig-timesingle">
![../_images/timesingle.png](../_images/timesingle.png)
<figcaption>

<span class="caption-number">Fig. 80 </span><span class="caption-text">单周期CPU的时序设计</span>[](#fig-timesingle "Permalink to this image")

</figcaption>
</figure>
</section>
<section id="id16">

### 模块化设计[](#id16 "Permalink to this heading")

CPU设计过程中需要多个不同的模块分工协作，建议在开始编码前划分好具体模块的功能和接口。对于模块划分我们提供了以下的参考建议。顶层实体内包含的模块主要是：

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

</section>
</section>
<section id="id17">

## 软件及测试部分[](#id17 "Permalink to this heading")

RISC-V CPU是一个较为复杂的数字系统，在开发过程中需要对每一个环节进行详细的测试才能够保证系统整体的可靠性。

<section id="id18">

### 单元测试[](#id18 "Permalink to this heading")

在开发过程中，需要首先确保每一个子单元都正常工作，因此在完成各个单元的代码编写后需要进行对应的测试。具体可以包括：

*   **代码复查** ：检查代码编写过程中是否有问题，尤其是变量名称、数据线宽度等易出错的地方。检查编译中的警告，判断是否警告会带来错误。

*   **RTL复查** ：利用RTL Viewer检查系统编译输出的RTL是否符合设计构想，有没有悬空或未连接的引脚。

*   **TestBench功能仿真** ：通过针对独立单元的testbench进行功能仿真，尤其需要注意ALU、寄存器堆、及内容的功能正确性。对于存储元件需要分析时序正确性，即数据是否在正确的时间给出，写入时是否按预期写入等。
</section>
<section id="id19">

### 单步功能仿真[](#id19 "Permalink to this heading")

在完成基本单元测试后，可以进行CPU整体的联调。整体联调的主要目的是验证各个指令基本功能的正确性。
实验指导提供了testbench的示例帮助大家进行单步指令的执行和验证。

在这个Testbench中，首先定义了一部分测试中需要用到的变量：

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="no">`timescale</span><span class="w"> </span><span class="mh">1</span><span class="w"> </span><span class="n">ns</span><span class="w"> </span><span class="o">/</span><span class="w"> </span><span class="mh">10</span><span class="w"> </span><span class="n">ps</span>
<span class="k">module</span><span class="w"> </span><span class="n">testbench_cpu</span><span class="p">();</span>
<span class="k">integer</span><span class="w"> </span><span class="n">numcycles</span><span class="p">;</span><span class="w">  </span><span class="c1">//number of cycles in test</span>
<span class="kt">reg</span><span class="w"> </span><span class="n">clk</span><span class="p">,</span><span class="n">reset</span><span class="p">;</span><span class="w">  </span><span class="c1">//clk and reset signals</span>
<span class="kt">reg</span><span class="p">[</span><span class="mh">8</span><span class="o">*</span><span class="mh">30</span><span class="o">:</span><span class="mh">1</span><span class="p">]</span><span class="w"> </span><span class="n">testcase</span><span class="p">;</span><span class="w"> </span><span class="c1">//name of testcase</span>
</pre></div>
</div>

其中testcase是我们的测试用例名，为字符串格式，用来载入不同的测试用例。

随后，在testbench中实例化CPU中的部件，这里单独实例化了CPU主体、指令存储和数据存储：

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="c1">// CPU declaration</span>
<span class="c1">// signals</span>
<span class="kt">wire</span><span class="w"> </span><span class="p">[</span><span class="mh">31</span><span class="o">:</span><span class="mh">0</span><span class="p">]</span><span class="w"> </span><span class="n">iaddr</span><span class="p">,</span><span class="n">idataout</span><span class="p">;</span>
<span class="kt">wire</span><span class="w"> </span><span class="n">iclk</span><span class="p">;</span>
<span class="kt">wire</span><span class="w"> </span><span class="p">[</span><span class="mh">31</span><span class="o">:</span><span class="mh">0</span><span class="p">]</span><span class="w"> </span><span class="n">daddr</span><span class="p">,</span><span class="n">ddataout</span><span class="p">,</span><span class="n">ddatain</span><span class="p">;</span>
<span class="kt">wire</span><span class="w"> </span><span class="n">drdclk</span><span class="p">,</span><span class="w"> </span><span class="n">dwrclk</span><span class="p">,</span><span class="w"> </span><span class="n">dwe</span><span class="p">;</span>
<span class="kt">wire</span><span class="w"> </span><span class="p">[</span><span class="mh">2</span><span class="o">:</span><span class="mh">0</span><span class="p">]</span><span class="w">  </span><span class="n">dop</span><span class="p">;</span>
<span class="kt">wire</span><span class="w"> </span><span class="p">[</span><span class="mh">23</span><span class="o">:</span><span class="mh">0</span><span class="p">]</span><span class="w"> </span><span class="n">cpudbgdata</span><span class="p">;</span>

<span class="c1">//main CPU</span>
<span class="n">rv32is</span><span class="w"> </span><span class="n">mycpu</span><span class="p">(.</span><span class="n">clock</span><span class="p">(</span><span class="n">clk</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">reset</span><span class="p">(</span><span class="n">reset</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">imemaddr</span><span class="p">(</span><span class="n">iaddr</span><span class="p">),</span><span class="w"> </span><span class="p">.</span><span class="n">imemdataout</span><span class="p">(</span><span class="n">idataout</span><span class="p">),</span><span class="w"> </span><span class="p">.</span><span class="n">imemclk</span><span class="p">(</span><span class="n">iclk</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">dmemaddr</span><span class="p">(</span><span class="n">daddr</span><span class="p">),</span><span class="w"> </span><span class="p">.</span><span class="n">dmemdataout</span><span class="p">(</span><span class="n">ddataout</span><span class="p">),</span><span class="w"> </span><span class="p">.</span><span class="n">dmemdatain</span><span class="p">(</span><span class="n">ddatain</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">dmemrdclk</span><span class="p">(</span><span class="n">drdclk</span><span class="p">),</span><span class="w"> </span><span class="p">.</span><span class="n">dmemwrclk</span><span class="p">(</span><span class="n">dwrclk</span><span class="p">),</span><span class="w"> </span><span class="p">.</span><span class="n">dmemop</span><span class="p">(</span><span class="n">dop</span><span class="p">),</span><span class="w"> </span><span class="p">.</span><span class="n">dmemwe</span><span class="p">(</span><span class="n">dwe</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">dbgdata</span><span class="p">(</span><span class="n">cpudbgdata</span><span class="p">));</span>

<span class="c1">//instruction memory, no writing</span>
<span class="n">testmem</span><span class="w"> </span><span class="n">instructions</span><span class="p">(</span>
<span class="w">  </span><span class="p">.</span><span class="n">address</span><span class="p">(</span><span class="n">iaddr</span><span class="p">[</span><span class="mh">17</span><span class="o">:</span><span class="mh">2</span><span class="p">]),</span>
<span class="w">  </span><span class="p">.</span><span class="n">clock</span><span class="p">(</span><span class="n">iclk</span><span class="p">),</span>
<span class="w">  </span><span class="p">.</span><span class="n">data</span><span class="p">(</span><span class="mh">32</span><span class="mb">&#39;b0</span><span class="p">),</span>
<span class="w">  </span><span class="p">.</span><span class="n">wren</span><span class="p">(</span><span class="mh">1</span><span class="mb">&#39;b0</span><span class="p">),</span>
<span class="w">  </span><span class="p">.</span><span class="n">q</span><span class="p">(</span><span class="n">idataout</span><span class="p">));</span>

<span class="c1">//data memory</span>
<span class="n">dmem</span><span class="w"> </span><span class="n">datamem</span><span class="p">(.</span><span class="n">addr</span><span class="p">(</span><span class="n">daddr</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">dataout</span><span class="p">(</span><span class="n">ddataout</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">datain</span><span class="p">(</span><span class="n">ddatain</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">rdclk</span><span class="p">(</span><span class="n">drdclk</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">wrclk</span><span class="p">(</span><span class="n">dwrclk</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">memop</span><span class="p">(</span><span class="n">dop</span><span class="p">),</span>
<span class="w">            </span><span class="p">.</span><span class="n">we</span><span class="p">(</span><span class="n">dwe</span><span class="p">));</span>
</pre></div>
</div>

在实际实现中请同学们根据自己设计的CPU接口自行进行更改。在测试过程中，建议可以用自己写的memory模块替代IP核生成的memory模块，方便对内存进行各类操作。

随后，定义了一系列的辅助task，帮助我们完成各类测试操作：

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="c1">//useful tasks</span>
<span class="k">task</span><span class="w"> </span><span class="n">step</span><span class="p">;</span><span class="w">  </span><span class="c1">//step for one cycle ends 1ns AFTER the posedge of the next cycle</span>
<span class="w">  </span><span class="k">begin</span>
<span class="w">    </span><span class="p">#</span><span class="mh">9</span><span class="w">  </span><span class="n">clk</span><span class="o">=</span><span class="mh">1</span><span class="mb">&#39;b0</span><span class="p">;</span>
<span class="w">    </span><span class="p">#</span><span class="mh">10</span><span class="w"> </span><span class="n">clk</span><span class="o">=</span><span class="mh">1</span><span class="mb">&#39;b1</span><span class="p">;</span>
<span class="w">    </span><span class="n">numcycles</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="n">numcycles</span><span class="w"> </span><span class="o">+</span><span class="w"> </span><span class="mh">1</span><span class="p">;</span>
<span class="w">    </span><span class="p">#</span><span class="mh">1</span><span class="w"> </span><span class="p">;</span>
<span class="w">  </span><span class="k">end</span>
<span class="k">endtask</span>

<span class="k">task</span><span class="w"> </span><span class="n">stepn</span><span class="p">;</span><span class="w"> </span><span class="c1">//step n cycles</span>
<span class="w">  </span><span class="k">input</span><span class="w"> </span><span class="k">integer</span><span class="w"> </span><span class="n">n</span><span class="p">;</span>
<span class="w">  </span><span class="k">integer</span><span class="w"> </span><span class="n">i</span><span class="p">;</span>
<span class="w">  </span><span class="k">begin</span>
<span class="w">    </span><span class="k">for</span><span class="w"> </span><span class="p">(</span><span class="n">i</span><span class="w"> </span><span class="o">=</span><span class="mh">0</span><span class="p">;</span><span class="w"> </span><span class="n">i</span><span class="o">&lt;</span><span class="n">n</span><span class="w"> </span><span class="p">;</span><span class="w"> </span><span class="n">i</span><span class="o">=</span><span class="n">i</span><span class="o">+</span><span class="mh">1</span><span class="p">)</span>
<span class="w">      </span><span class="n">step</span><span class="p">();</span>
<span class="w">  </span><span class="k">end</span>
<span class="k">endtask</span>

<span class="k">task</span><span class="w"> </span><span class="n">resetcpu</span><span class="p">;</span><span class="w">  </span><span class="c1">//reset the CPU and the test</span>
<span class="w">  </span><span class="k">begin</span>
<span class="w">    </span><span class="n">reset</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="mh">1</span><span class="mb">&#39;b1</span><span class="p">;</span>
<span class="w">    </span><span class="n">step</span><span class="p">();</span>
<span class="w">    </span><span class="p">#</span><span class="mh">5</span><span class="w"> </span><span class="n">reset</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="mh">1</span><span class="mb">&#39;b0</span><span class="p">;</span>
<span class="w">    </span><span class="n">numcycles</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="mh">0</span><span class="p">;</span>
<span class="w">  </span><span class="k">end</span>
<span class="k">endtask</span>
</pre></div>
</div>

其中step任务是将CPU时钟前进一个周期，在单周期CPU中等价于单步执行一条指令。注意我们这里的周期是以上升沿开始的，在实际测试中可以将时间步进到下一个周期的上升沿后一个时间单位，这主要是由于我们单周期CPU是在下一上升沿进行写入，对数据的验证要在上升沿略后一些的时间进行。
stepn任务用于执行n条指令，resetcpu用于将cpu重置，从预定开始执行的地址重新执行。

Testbench中还定义了载入任务：

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="k">task</span><span class="w"> </span><span class="n">loadtestcase</span><span class="p">;</span><span class="w">  </span><span class="c1">//load intstructions to instruction mem</span>
<span class="w">  </span><span class="k">begin</span>
<span class="w">    </span><span class="nb">$readmemh</span><span class="p">({</span><span class="n">testcase</span><span class="p">,</span><span class="w"> </span><span class="s">&quot;.hex&quot;</span><span class="p">},</span><span class="n">instructions</span><span class="p">.</span><span class="n">ram</span><span class="p">);</span>
<span class="w">    </span><span class="nb">$display</span><span class="p">(</span><span class="s">&quot;---Begin test case %s-----&quot;</span><span class="p">,</span><span class="w"> </span><span class="n">testcase</span><span class="p">);</span>
<span class="w">  </span><span class="k">end</span>
<span class="k">endtask</span>
</pre></div>
</div>

该任务用于载入指令文件。指令文件为文本格式，建议放在simulate/modelsim子目录下，用相对目录名来定位文件。
这里采用$readmemh读入到指定的指令存储中去，由于指令存储空间的声明不在顶层实体instructions中，需要使用instructions.ram来访问实体内部声明的变量ram。
在编写testbench时请同学们自己按照自己的设计来定位实际应该访问的变量的位置。

同时还需要定义一系列的断言任务，辅助检查寄存器或者内存中的内容，并在出错时提供提示信息：

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="k">task</span><span class="w"> </span><span class="n">checkreg</span><span class="p">;</span><span class="c1">//check registers</span>
<span class="w">  </span><span class="k">input</span><span class="w"> </span><span class="p">[</span><span class="mh">4</span><span class="o">:</span><span class="mh">0</span><span class="p">]</span><span class="w"> </span><span class="n">regid</span><span class="p">;</span>
<span class="w">  </span><span class="k">input</span><span class="w"> </span><span class="p">[</span><span class="mh">31</span><span class="o">:</span><span class="mh">0</span><span class="p">]</span><span class="w"> </span><span class="n">results</span><span class="p">;</span>
<span class="w">  </span><span class="kt">reg</span><span class="w"> </span><span class="p">[</span><span class="mh">31</span><span class="o">:</span><span class="mh">0</span><span class="p">]</span><span class="w"> </span><span class="n">debugdata</span><span class="p">;</span>
<span class="w">  </span><span class="k">begin</span>
<span class="w">    </span><span class="n">debugdata</span><span class="o">=</span><span class="n">mycpu</span><span class="p">.</span><span class="n">myregfile</span><span class="p">.</span><span class="n">regs</span><span class="p">[</span><span class="n">regid</span><span class="p">];</span><span class="w"> </span><span class="c1">//get register content</span>
<span class="w">    </span><span class="k">if</span><span class="p">(</span><span class="n">debugdata</span><span class="o">==</span><span class="n">results</span><span class="p">)</span>
<span class="w">    </span><span class="k">begin</span>
<span class="w">        </span><span class="nb">$display</span><span class="p">(</span><span class="s">&quot;OK: end of cycle %d reg %h need to be %h, get %h&quot;</span><span class="p">,</span>
<span class="w">                  </span><span class="n">numcycles</span><span class="o">-</span><span class="mh">1</span><span class="p">,</span><span class="w"> </span><span class="n">regid</span><span class="p">,</span><span class="w"> </span><span class="n">results</span><span class="p">,</span><span class="w"> </span><span class="n">debugdata</span><span class="p">);</span>
<span class="w">    </span><span class="k">end</span>
<span class="w">  </span><span class="k">else</span>
<span class="w">  </span><span class="k">begin</span>
<span class="w">    </span><span class="nb">$display</span><span class="p">(</span><span class="s">&quot;!!!Error: end of cycle %d reg %h need to be %h, get %h&quot;</span><span class="p">,</span>
<span class="w">              </span><span class="n">numcycles</span><span class="o">-</span><span class="mh">1</span><span class="p">,</span><span class="w"> </span><span class="n">regid</span><span class="p">,</span><span class="w"> </span><span class="n">results</span><span class="p">,</span><span class="w"> </span><span class="n">debugdata</span><span class="p">);</span>
<span class="w">    </span><span class="k">end</span>
<span class="w">  </span><span class="k">end</span>
<span class="k">endtask</span>
</pre></div>
</div>

在这个任务中访问了CPU内部定义的寄存器堆myregfile中的regs变量，并根据所需要的访问regid来提取数据，并和预期数据进行比较。
如果不正确，任务会提示比较结果，方便进行debug。
同样的，也可以编写类似的内存内容比较模块，对内存中的内容进行检查。

假定需要测试CPU中加法语句的正确性，同学们可以编写一小段汇编

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="n">addi</span><span class="w"> </span><span class="n">t1</span><span class="p">,</span><span class="n">zero</span><span class="p">,</span><span class="mh">100</span>
<span class="n">addi</span><span class="w"> </span><span class="n">t2</span><span class="p">,</span><span class="n">zero</span><span class="p">,</span><span class="mh">20</span>
<span class="n">add</span><span class="w">  </span><span class="n">t3</span><span class="p">,</span><span class="n">t1</span><span class="p">,</span><span class="n">t2</span>
</pre></div>
</div>

在这段汇编执行过程中，我们可以检查各个寄存器结果，观察代码执行的正确性。
利用上学期用过的 [rars](https://github.com/TheThirdOne/rars) 仿真器来将这段汇编转换为二进制，并写入add.hex文件中，无需添加文件头v2.0 raw。示例文件的具体内容如下：

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="mh">06400313</span>
<span class="mh">01400393</span>
<span class="mf">00730E33</span>
</pre></div>
</div>

Testbench具体的执行部分如下：

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="k">initial</span><span class="w"> </span><span class="k">begin</span><span class="o">:</span><span class="n">TestBench</span>
<span class="w">      </span><span class="p">#</span><span class="mh">80</span>
<span class="w">      </span><span class="c1">// output the state of every instruction</span>
<span class="w">    </span><span class="nb">$monitor</span><span class="p">(</span><span class="s">&quot;cycle=%d, pc=%h, instruct= %h op=%h,</span>
<span class="w">              </span><span class="n">rs1</span><span class="o">=%</span><span class="n">h</span><span class="p">,</span><span class="n">rs2</span><span class="o">=%</span><span class="n">h</span><span class="p">,</span><span class="w"> </span><span class="n">rd</span><span class="o">=%</span><span class="n">h</span><span class="p">,</span><span class="w"> </span><span class="n">imm</span><span class="o">=%</span><span class="n">h</span><span class="s">&quot;,</span>
<span class="w">              </span><span class="n">numcycles</span><span class="p">,</span><span class="w">  </span><span class="n">mycpu</span><span class="p">.</span><span class="n">pc</span><span class="p">,</span><span class="w"> </span><span class="n">mycpu</span><span class="p">.</span><span class="n">instr</span><span class="p">,</span><span class="w"> </span><span class="n">mycpu</span><span class="p">.</span><span class="n">op</span><span class="p">,</span>
<span class="w">              </span><span class="n">mycpu</span><span class="p">.</span><span class="n">rs1</span><span class="p">,</span><span class="n">mycpu</span><span class="p">.</span><span class="n">rs2</span><span class="p">,</span><span class="n">mycpu</span><span class="p">.</span><span class="n">rd</span><span class="p">,</span><span class="n">mycpu</span><span class="p">.</span><span class="n">imm</span><span class="p">);</span>

<span class="w">    </span><span class="n">testcase</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="s">&quot;add&quot;</span><span class="p">;</span>
<span class="w">    </span><span class="n">loadtestcase</span><span class="p">();</span>
<span class="w">    </span><span class="n">resetcpu</span><span class="p">();</span>
<span class="w">    </span><span class="n">step</span><span class="p">();</span>
<span class="w">    </span><span class="n">checkreg</span><span class="p">(</span><span class="mh">6</span><span class="p">,</span><span class="mh">100</span><span class="p">);</span><span class="w"> </span><span class="c1">//t1==100</span>
<span class="w">    </span><span class="n">step</span><span class="p">();</span>
<span class="w">    </span><span class="n">checkreg</span><span class="p">(</span><span class="mh">7</span><span class="p">,</span><span class="mh">20</span><span class="p">);</span><span class="w">  </span><span class="c1">//t2=20</span>
<span class="w">    </span><span class="n">step</span><span class="p">();</span>
<span class="w">    </span><span class="n">checkreg</span><span class="p">(</span><span class="mh">28</span><span class="p">,</span><span class="mh">120</span><span class="p">);</span><span class="w"> </span><span class="c1">//t3=120</span>
<span class="w">    </span><span class="nb">$stop</span>
<span class="k">end</span>
</pre></div>
</div>

执行过程中，首先使用$monitor来定义我们需要观察的变量，只要这些变量发生变化modelsim会自动地打印出变量的内容。
这样，可以在每条指令执行时看到对应的PC及指令解码的关键信息。同学们也可以自定义需要观察的信号。
在载入add测试用例后，testbench单步执行了3次，每次执行完就按照我们预期的执行结果检查了t1, t2和t3寄存器。
modelsim的实际输出如图 [<span class="std std-numref">Fig. 81</span>](#fig-simoutput) ：

<figure class="align-default" id="fig-simoutput">
![../_images/simoutput.png](../_images/simoutput.png)
<figcaption>

<span class="caption-number">Fig. 81 </span><span class="caption-text">单周期CPU的仿真输出</span>[](#fig-simoutput "Permalink to this image")

</figcaption>
</figure>

从图中可以看到初始化结束后代码从全零地址开始执行，每个周期结束后会对寄存器进行检查。注意这里检查点在上升沿到来后，所以在第n周期结束时，PC和指令已经是下一条指令的内容了。

请自行按照自己的设计修改单步仿真testbench，并自行设计测试用例来对CPU进行初步联调。

</section>
<section id="id20">

### 系统功能仿真[](#id20 "Permalink to this heading")

单步功能仿真用于简单验证CPU中各条指令的基本情况，确保CPU可以完成基础功能。
但是，为了排除CPU中潜在的bug，我们需要对CPU的实现进行详细的测试，避免后面在搭建整个计算机系统时由于CPU的问题出现难以定位的bug。
在本实验中使用RISC-V的官方测试集来对CPU进行全面的系统仿真。

</section>
<section id="riscv-tests">

### riscv-tests测试集简介[](#riscv-tests "Permalink to this heading")

RISC-V社区开发了 [官方测试集](https://github.com/riscv/riscv-tests) ，针对不同的RISC-V指令变种都提供了测试。
测试集的编译需要安装risc-v gcc工具链，在Ubuntu下运行

<div class="highlight-Bash notranslate"><div class="highlight"><pre><span></span>apt-get<span class="w"> </span>install<span class="w"> </span>g++-riscv64-linux-gnu<span class="w"> </span>binutils-riscv64-linux-gnu
</pre></div>
</div>

如果在编译时遇到问题，可以参考PA2.2中的 [解决方法](https://nju-projectn.github.io/ics-pa-gitbook/ics2021/2.2.html#%E8%BF%90%E8%A1%8C%E7%AC%AC%E4%B8%80%E4%B8%AAc%E7%A8%8B%E5%BA%8F) 。
我们将测试移植到了AM中，地址为 [https://github.com/NJU-ProjectN/riscv-tests.git](https://github.com/NJU-ProjectN/riscv-tests.git) 。如果要使用该测试集，可以运行下列命令

<div class="highlight-Bash notranslate"><div class="highlight"><pre><span></span>$<span class="w"> </span>git<span class="w"> </span>clone<span class="w"> </span>-b<span class="w"> </span>digit<span class="w"> </span>https://github.com/NJU-ProjectN/riscv-tests.git
$<span class="w"> </span>git<span class="w"> </span>clone<span class="w"> </span>-b<span class="w"> </span>digit<span class="w"> </span>https://github.com/NJU-ProjectN/abstract-machine.git
$<span class="w"> </span><span class="nb">export</span><span class="w"> </span><span class="nv">AM_HOME</span><span class="o">=</span><span class="k">$(</span><span class="nb">pwd</span><span class="k">)</span>/abstract-machine
$<span class="w"> </span><span class="nb">cd</span><span class="w"> </span>riscv-tests
$<span class="w"> </span>make
</pre></div>
</div>

其中第1-2句从github上下载riscv-tests和am源代码，第3句设置环境变量，最后编译测试集。
编译后的文件在riscv-tests/build目录下，包括可执行文件(.elf)和反汇编文件(.txt)，以及我们需要的FPGA内存hex文件和mif文件。大家可以在反汇编文件中查看测试用例中包含的指令以及每条指令的地址。

RISC-V 官方测试集针对不同的 RISC-V 指令变种都提供了测试。在本实验中，我们主要使用 rv32ui 也就是 RV32 的基本指令集， u 表示是用户态， i 表示是整数基本指令集。实验中采用的环境是无虚拟地址的环境，即只使用物理地址访问内存。

</section>
<section id="id23">

### 测试程序移植[](#id23 "Permalink to this heading")

AM为应用程序提供了裸机运行时环境，最简单的运行时环境如abstract-machine/src/npc目录下的start.S和trm.c所示。
AM设置了栈指针、程序的入口(main)以及退出程序的方式(halt)，在完成初始化后就跳转到应用程序，也就是riscv-tests中的目标测试继续执行。

riscv-tests中提供了对每条指令的单元测试，以下为add测试用例中的部分反汇编片段：

<div class="highlight-default notranslate"><div class="highlight"><pre><span></span><span class="mi">00000580</span> <span class="o">&lt;</span><span class="n">test_38</span><span class="o">&gt;</span><span class="p">:</span>
<span class="mi">580</span><span class="p">:</span>  <span class="mi">01000093</span>                <span class="n">li</span>      <span class="n">ra</span><span class="p">,</span><span class="mi">16</span>
<span class="mi">584</span><span class="p">:</span>  <span class="mf">01e00113</span>                <span class="n">li</span>      <span class="n">sp</span><span class="p">,</span><span class="mi">30</span>
<span class="mi">588</span><span class="p">:</span>  <span class="mi">00208033</span>                <span class="n">add</span>     <span class="n">zero</span><span class="p">,</span><span class="n">ra</span><span class="p">,</span><span class="n">sp</span>
<span class="mi">58</span><span class="n">c</span><span class="p">:</span>  <span class="mi">00000393</span>                <span class="n">li</span>      <span class="n">t2</span><span class="p">,</span><span class="mi">0</span>
<span class="mi">590</span><span class="p">:</span>  <span class="mi">02600193</span>                <span class="n">li</span>      <span class="n">gp</span><span class="p">,</span><span class="mi">38</span>
<span class="mi">594</span><span class="p">:</span>  <span class="mi">00701463</span>                <span class="n">bne</span>     <span class="n">zero</span><span class="p">,</span><span class="n">t2</span><span class="p">,</span><span class="mi">59</span><span class="n">c</span> <span class="o">&lt;</span><span class="n">fail</span><span class="o">&gt;</span>
<span class="mi">598</span><span class="p">:</span>  <span class="mi">00301863</span>                <span class="n">bne</span>     <span class="n">zero</span><span class="p">,</span><span class="n">gp</span><span class="p">,</span><span class="mi">5</span><span class="n">a8</span> <span class="o">&lt;</span><span class="k">pass</span><span class="o">&gt;</span>

<span class="mi">0000059</span><span class="n">c</span> <span class="o">&lt;</span><span class="n">fail</span><span class="o">&gt;</span><span class="p">:</span>
<span class="mi">59</span><span class="n">c</span><span class="p">:</span>  <span class="n">deade537</span>                <span class="n">lui</span>     <span class="n">a0</span><span class="p">,</span><span class="mh">0xdeade</span>
<span class="mi">5</span><span class="n">a0</span><span class="p">:</span>  <span class="n">ead50513</span>                <span class="n">addi</span>    <span class="n">a0</span><span class="p">,</span><span class="n">a0</span><span class="p">,</span><span class="o">-</span><span class="mi">339</span> <span class="c1"># deaddead &lt;_pmem_start+0x5eaddead&gt;</span>
<span class="mi">5</span><span class="n">a4</span><span class="p">:</span>  <span class="mi">0200006</span><span class="n">f</span>                <span class="n">j</span>       <span class="mi">5</span><span class="n">c4</span> <span class="o">&lt;</span><span class="n">halt</span><span class="o">&gt;</span>

<span class="mi">000005</span><span class="n">a8</span> <span class="o">&lt;</span><span class="k">pass</span><span class="o">&gt;</span><span class="p">:</span>
<span class="mi">5</span><span class="n">a8</span><span class="p">:</span>  <span class="mi">00</span><span class="n">c10537</span>                <span class="n">lui</span>     <span class="n">a0</span><span class="p">,</span><span class="mh">0xc10</span>
<span class="mi">5</span><span class="n">ac</span><span class="p">:</span>  <span class="n">fee50513</span>                <span class="n">addi</span>    <span class="n">a0</span><span class="p">,</span><span class="n">a0</span><span class="p">,</span><span class="o">-</span><span class="mi">18</span> <span class="c1"># c0ffee &lt;_end+0xb0f7ee&gt;</span>
<span class="mi">5</span><span class="n">b0</span><span class="p">:</span>  <span class="mi">0140006</span><span class="n">f</span>                <span class="n">j</span>       <span class="mi">5</span><span class="n">c4</span> <span class="o">&lt;</span><span class="n">halt</span><span class="o">&gt;</span>
</pre></div>
</div>

在这里，程序会检查两个数的加法运算是否为预期结果，并相应地跳转到fail或者pass中。
在pass中会调用halt，将a0寄存器的值设置为32’h00c0ffee，并放入一条指令32’hdead10cc，表示测试完成，在仿真中获取这个数字之后就可以判断仿真完成了。
如果是fail的情况，则将a0置为32’hdeaddead，随后停止仿真。在仿真结束时通过a0寄存器的值就可以判断是否通过了全部测试。

<div class="admonition myquestion">

特殊指令32’hdead10cc

为什么正常的 rv32i 指令序列中肯定不会出现 32’hdead10cc ？在反汇编文件中，32’hdead10cc被反汇编成了什么？

</div>

在编译生成可执行文件后，得到的elf文件并不能直接用于FPGA内存初始化。所以，我们需要自动生成针对 verilog 的文本 .hex 文件和对 IP 核初始化的mif 文件。
在完成编译后会自动执行abstract-machine/scripts/riscv32-npc.mk中的以下命令，生成需要载入FPGA的hex文件：

<div class="highlight-Makefile notranslate"><div class="highlight"><pre><span></span><span class="nv">RISCV_OBJCOPY</span><span class="w"> </span><span class="o">?=</span><span class="w"> </span><span class="k">$(</span>RISCV_PREFIX<span class="k">)</span>objcopy<span class="w"> </span>-O<span class="w"> </span>verilog
<span class="nv">RISCV_HEXGEN</span><span class="w"> </span><span class="o">?=</span><span class="w"> </span><span class="s1">&#39;BEGIN{output=0;}{ gsub(&quot;\r&quot;,&quot;&quot;,$$(NF)); if ($$1~/@/) {if ($$1 ~/@80000000/) {output=code;} else {output=1-code;}; gsub(&quot;@&quot;,&quot;0x&quot;,$$1); addr=strtonum($$1); if (output==1){printf &quot;@%08x\n&quot;,(addr%262144)/4;}} else {if (output==1) {for(i=1;i&lt;NF;i+=4) print $$(i+3)$$(i+2)$$(i+1)$$i;}}}&#39;</span>
<span class="nv">RISCV_MIFGEN</span><span class="w"> </span><span class="o">?=</span><span class="w"> </span><span class="s1">&#39;BEGIN{printf &quot;WIDTH=32;\nDEPTH=%d;\n\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\nCONTENT BEGIN\n&quot;,depth; addr=0;} { gsub(&quot;\r&quot;,&quot;&quot;,$$(NF)); if ($$1 ~/@/) {gsub(&quot;@&quot;,&quot;0x&quot;,$$1);addr=strtonum($$1);} else {printf &quot;%04X : %s;\n&quot;,addr, $$1; addr=addr+1;}} END{print &quot;END\n&quot;;}&#39;</span>

<span class="nf">image</span><span class="o">:</span><span class="w"> </span><span class="k">$(</span><span class="nv">IMAGE</span><span class="k">)</span>.<span class="n">elf</span>
<span class="w">  </span>@<span class="k">$(</span>OBJDUMP<span class="k">)</span><span class="w"> </span>-d<span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>.elf<span class="w"> </span>&gt;<span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>.txt
<span class="w">  </span><span class="k">$(</span>RISCV_OBJCOPY<span class="k">)</span><span class="w"> </span>$&lt;<span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>.tmp
<span class="w">  </span>awk<span class="w"> </span>-v<span class="w"> </span><span class="nv">code</span><span class="o">=</span><span class="m">1</span><span class="w"> </span><span class="k">$(</span>RISCV_HEXGEN<span class="k">)</span><span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>.tmp<span class="w"> </span>&gt;<span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>.hex
<span class="w">  </span>awk<span class="w"> </span>-v<span class="w"> </span><span class="nv">code</span><span class="o">=</span><span class="m">0</span><span class="w"> </span><span class="k">$(</span>RISCV_HEXGEN<span class="k">)</span><span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>.tmp<span class="w"> </span>&gt;<span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>_d.hex
<span class="w">  </span>awk<span class="w"> </span>-v<span class="w"> </span><span class="nv">depth</span><span class="o">=</span><span class="m">65536</span><span class="w"> </span><span class="k">$(</span>RISCV_MIFGEN<span class="k">)</span><span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>.hex<span class="w"> </span>&gt;<span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>.mif
<span class="w">  </span>awk<span class="w"> </span>-v<span class="w"> </span><span class="nv">depth</span><span class="o">=</span><span class="m">32768</span><span class="w"> </span><span class="k">$(</span>RISCV_MIFGEN<span class="k">)</span><span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>_d.hex<span class="w"> </span>&gt;<span class="w"> </span><span class="k">$(</span>IMAGE<span class="k">)</span>_d.mif
</pre></div>
</div>

该过程分为以下几步：
首先用反汇编工具objdump生成包含所有指令的文本文件，方便进行测试。
第二步用 objcopy 工具来生成 .tmp 文件，这个文件符合 verilog 格式要求，但是其中的数据是按 8bit 字节存储的，无法直接用于初始化 32bit 宽度的内存。
第三步(line 8-9)是用 linux 的 awk 文本处理工具简单转换一下 verilog 的格式。 awk的指令请自行查找资料学习。本例中 awk 根据 output 变量判断是否需要打印输出。在读入一行后首先去除了最后一个 token 的换行符，然后判断是否是以 &#64;开头的地址。如果是，则判断地址是否是 0x80000000 代码段起始地址。根据变量 code 来判断是生成代码初始化文件还是数据初始化文件。随后，对地址取低18 位，并将地址除以四（从 byte 编址改成我们存储器中 4 字节编址），并打印修改后的地址。对于正常的数据行，awk会将token分成四个一组重新打印。

<div class="admonition myquestion">

思考

为什么我们将起始为 0x80000000 的代码段和数据段地址只取低 18位来生成代码和数据存储器的初始化文件，我们的 CPU 仍然正确地执行并找到对应的数据？

</div>

第四步(line 10-11)是用awk将文本hex格式改成mif格式，增加文件头尾和地址标识。

<div class="admonition myquestion">

思考

如果数据存储器是用 4 片 8bit 存储器来实现的，如何生成 4 片存储器对应的初始化文件？

</div>

采用上面介绍的框架和方法，我们能够很容易地移植其他测试程序，以一个简单的求和运算为例：

<div class="highlight-c notranslate"><div class="highlight"><pre><span></span><span class="c1">//sum.c</span>
<span class="cp">#define PASS_CODE 0xc0ffee</span>
<span class="cp">#define FAIL_CODE 0xdeaddead</span>
<span class="kt">void</span><span class="w"> </span><span class="nf">halt</span><span class="p">(</span><span class="kt">int</span><span class="w"> </span><span class="n">code</span><span class="p">);</span>

<span class="n">__attribute__</span><span class="p">((</span><span class="n">noinline</span><span class="p">))</span>
<span class="kt">void</span><span class="w"> </span><span class="n">check</span><span class="p">(</span><span class="kt">int</span><span class="w"> </span><span class="n">cond</span><span class="p">)</span><span class="w"> </span><span class="p">{</span>
<span class="w">  </span><span class="k">if</span><span class="w"> </span><span class="p">(</span><span class="o">!</span><span class="n">cond</span><span class="p">)</span><span class="w"> </span><span class="n">halt</span><span class="p">(</span><span class="n">FAIL_CODE</span><span class="p">);</span>
<span class="p">}</span>

<span class="kt">int</span><span class="w"> </span><span class="n">main</span><span class="p">()</span><span class="w"> </span><span class="p">{</span>
<span class="w">  </span><span class="kt">int</span><span class="w"> </span><span class="n">i</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="mi">1</span><span class="p">;</span>
<span class="w">  </span><span class="k">volatile</span><span class="w"> </span><span class="kt">int</span><span class="w"> </span><span class="n">sum</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="mi">0</span><span class="p">;</span>
<span class="w">  </span><span class="k">while</span><span class="p">(</span><span class="n">i</span><span class="w"> </span><span class="o">&lt;=</span><span class="w"> </span><span class="mi">100</span><span class="p">)</span><span class="w"> </span><span class="p">{</span>
<span class="w">    </span><span class="n">sum</span><span class="w"> </span><span class="o">+=</span><span class="w"> </span><span class="n">i</span><span class="p">;</span>
<span class="w">    </span><span class="n">i</span><span class="w"> </span><span class="o">++</span><span class="p">;</span>
<span class="w">  </span><span class="p">}</span>

<span class="w">  </span><span class="n">check</span><span class="p">(</span><span class="n">sum</span><span class="w"> </span><span class="o">==</span><span class="w"> </span><span class="mi">5050</span><span class="p">);</span>

<span class="w">  </span><span class="k">return</span><span class="w"> </span><span class="n">PASS_CODE</span><span class="p">;</span>
<span class="p">}</span>
</pre></div>
</div>

并编写相应Makefile文件，我们提供了一个简单的Makefile实例如下：

<div class="highlight-Makefile notranslate"><div class="highlight"><pre><span></span>// Makefile
.PHONY: all clean $(ALL)

ARCH ?= riscv32-npc
ALL ?= sum

all: $(addprefix Makefile-, $(ALL))
  @echo &quot;&quot; $(ALL)

$(ALL): %: Makefile-%

Makefile-%: %.c
  @/bin/echo -e &quot;NAME = $*\nSRCS = $&lt;\nLIBS += klib\nINC_PATH += $(shell pwd)/env/p $(shell pwd)/isa/macros/scalar\ninclude $${AM_HOME}/Makefile&quot; &gt; $@
  -@make -s -f $@ ARCH=$(ARCH) $(MAKECMDGOALS)
  -@rm -f Makefile-$*

clean:
  rm -rf Makefile-* build/
</pre></div>
</div>

通过变量ALL指定需要编译的程序源文件，并使用AM中的Makefile，将应用程序、运行时环境和AM中定义的库函数一起编译成可执行文件，同学们可以阅读AM中的Makefile了解编译具体过程，也可以自行编写Makefile进行编译。
在设置好环境变量AM_HOME后，在该目录下通过make命令编译后，就能够在build目录下找到相应的文件。这样就能够自己编写更多的测试用例来测试处理器的实现。

<div class="admonition myinfo">

注意，官方测试集基于跳转指令来判断运行是否正确。如果跳转指令实现有问题，有可能会在CPU有bug时也输出正确的结果。尤其是某些情况下，信号为不定值X的时候，branch指令可能会错误判断，请注意排除此类问题。

</div>
</section>
<section id="testbench">

### 测试集TestBench[](#testbench "Permalink to this heading")

我们需要修改Testbench支持对官方测试集的仿真。主要增加了以下辅助任务：

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="k">integer</span><span class="w"> </span><span class="n">maxcycles</span><span class="w"> </span><span class="o">=</span><span class="mh">10000</span><span class="p">;</span>

<span class="k">task</span><span class="w"> </span><span class="n">run</span><span class="p">;</span>
<span class="w">  </span><span class="k">integer</span><span class="w"> </span><span class="n">i</span><span class="p">;</span>
<span class="w">  </span><span class="k">begin</span>
<span class="w">    </span><span class="n">i</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="mh">0</span><span class="p">;</span>
<span class="w">    </span><span class="k">while</span><span class="p">(</span><span class="w"> </span><span class="p">(</span><span class="n">mycpu</span><span class="p">.</span><span class="n">instr</span><span class="o">!=</span><span class="mh">32&#39;hdead10cc</span><span class="p">)</span><span class="w"> </span><span class="o">&amp;&amp;</span><span class="w"> </span><span class="p">(</span><span class="n">i</span><span class="o">&lt;</span><span class="n">maxcycles</span><span class="p">))</span>
<span class="w">    </span><span class="k">begin</span>
<span class="w">      </span><span class="n">step</span><span class="p">();</span>
<span class="w">      </span><span class="n">i</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="n">i</span><span class="o">+</span><span class="mh">1</span><span class="p">;</span>
<span class="w">    </span><span class="k">end</span>
<span class="w">  </span><span class="k">end</span>
<span class="k">endtask</span>
</pre></div>
</div>

代码运行任务run会一直用单步运行代码，直到遇到我们定义的代码终止信号为止。如果代码一直不终止也会在给定最大运行周期后停止仿真。

对仿真结果测试是通过对仿真结束后a0寄存器中数据是否符合预期来进行判断的。当然如果程序不终止，或者a0数据不正常也会报错。

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="k">task</span><span class="w"> </span><span class="n">checkmagnum</span><span class="p">;</span>
<span class="w">    </span><span class="k">begin</span>
<span class="w">      </span><span class="k">if</span><span class="p">(</span><span class="n">numcycles</span><span class="o">&gt;</span><span class="n">maxcycles</span><span class="p">)</span>
<span class="w">    </span><span class="k">begin</span>
<span class="w">      </span><span class="nb">$display</span><span class="p">(</span><span class="s">&quot;!!!Error:test case %s does not terminate!&quot;</span><span class="p">,</span><span class="w"> </span><span class="n">testcase</span><span class="p">);</span>
<span class="w">    </span><span class="k">end</span>
<span class="w">    </span><span class="k">else</span><span class="w"> </span><span class="k">if</span><span class="p">(</span><span class="n">mycpu</span><span class="p">.</span><span class="n">myregfile</span><span class="p">.</span><span class="n">regs</span><span class="p">[</span><span class="mh">10</span><span class="p">]</span><span class="o">==</span><span class="mh">32&#39;hc0ffee</span><span class="p">)</span>
<span class="w">        </span><span class="k">begin</span>
<span class="w">          </span><span class="nb">$display</span><span class="p">(</span><span class="s">&quot;OK:test case %s finshed OK at cycle %d.&quot;</span><span class="p">,</span>
<span class="w">                    </span><span class="n">testcase</span><span class="p">,</span><span class="w"> </span><span class="n">numcycles</span><span class="o">-</span><span class="mh">1</span><span class="p">);</span>
<span class="w">        </span><span class="k">end</span>
<span class="w">    </span><span class="k">else</span><span class="w"> </span><span class="k">if</span><span class="p">(</span><span class="n">mycpu</span><span class="p">.</span><span class="n">myregfile</span><span class="p">.</span><span class="n">regs</span><span class="p">[</span><span class="mh">10</span><span class="p">]</span><span class="o">==</span><span class="mh">32&#39;hdeaddead</span><span class="p">)</span>
<span class="w">    </span><span class="k">begin</span>
<span class="w">      </span><span class="nb">$display</span><span class="p">(</span><span class="s">&quot;!!!ERROR:test case %s finshed with error in cycle %d.&quot;</span><span class="p">,</span>
<span class="w">                </span><span class="n">testcase</span><span class="p">,</span><span class="w"> </span><span class="n">numcycles</span><span class="o">-</span><span class="mh">1</span><span class="p">);</span>
<span class="w">    </span><span class="k">end</span>
<span class="w">    </span><span class="k">else</span>
<span class="w">    </span><span class="k">begin</span>
<span class="w">        </span><span class="nb">$display</span><span class="p">(</span><span class="s">&quot;!!!ERROR:test case %s unknown error in cycle %d.&quot;</span><span class="p">,</span>
<span class="w">                </span><span class="n">testcase</span><span class="p">,</span><span class="w"> </span><span class="n">numcycles</span><span class="o">-</span><span class="mh">1</span><span class="p">);</span>
<span class="w">    </span><span class="k">end</span>
<span class="w">  </span><span class="k">end</span>
<span class="k">endtask</span>
</pre></div>
</div>

数据存储可以用我们生成的hex文件进行初始化，仿真时可以用我们提供的ram模块替代IP核生成的模块。一般只有在访存指令的测试时才需要初始化数据存储

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="k">task</span><span class="w"> </span><span class="n">loaddatamem</span><span class="p">;</span>
<span class="w">    </span><span class="k">begin</span>
<span class="w">      </span><span class="nb">$readmemh</span><span class="p">({</span><span class="n">testcase</span><span class="p">,</span><span class="w"> </span><span class="s">&quot;_d.hex&quot;</span><span class="p">},</span><span class="n">datamem</span><span class="p">.</span><span class="n">mymem</span><span class="p">.</span><span class="n">ram</span><span class="p">);</span>
<span class="w">  </span><span class="k">end</span>
<span class="k">endtask</span>
</pre></div>
</div>

我们也提供了一个简单的可以执行单个测试用例的任务

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="k">task</span><span class="w"> </span><span class="n">run_riscv_test</span><span class="p">;</span>
<span class="w">    </span><span class="k">begin</span>
<span class="w">    </span><span class="n">loadtestcase</span><span class="p">();</span>
<span class="w">    </span><span class="n">loaddatamem</span><span class="p">();</span>
<span class="w">    </span><span class="n">resetcpu</span><span class="p">();</span>
<span class="w">    </span><span class="n">run</span><span class="p">();</span>
<span class="w">    </span><span class="n">checkmagnum</span><span class="p">();</span>
<span class="w">  </span><span class="k">end</span>
<span class="k">endtask</span>
</pre></div>
</div>

所以在仿真过程中我们只需要按顺序执行所有需要的仿真即可：

<div class="highlight-Verilog notranslate"><div class="highlight"><pre><span></span><span class="n">testcase</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="s">&quot;rv32ui-p-simple&quot;</span><span class="p">;</span>
<span class="n">run_riscv_test</span><span class="p">();</span>
<span class="n">testcase</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="s">&quot;rv32ui-p-add&quot;</span><span class="p">;</span>
<span class="n">run_riscv_test</span><span class="p">();</span>
<span class="n">testcase</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="s">&quot;rv32ui-p-addi&quot;</span><span class="p">;</span>
<span class="n">run_riscv_test</span><span class="p">();</span>
<span class="n">testcase</span><span class="w"> </span><span class="o">=</span><span class="w"> </span><span class="s">&quot;rv32ui-p-and&quot;</span><span class="p">;</span>
<span class="n">run_riscv_test</span><span class="p">();</span>
</pre></div>
</div>
<figure class="align-default" id="fig-simout2">
![../_images/simuout2.png](../_images/simuout2.png)
<figcaption>

<span class="caption-number">Fig. 82 </span><span class="caption-text">使用官方测试集的CPU的仿真输出</span>[](#fig-simout2 "Permalink to this image")

</figcaption>
</figure>

在仿真过程中可以暂时注释$monitor任务，只有在出错时再检查具体测试用例为何出错。图 [<span class="std std-numref">Fig. 82</span>](#fig-simout2) 显示了利用官方测试集进行仿真的输出结果示例。

</section>
<section id="id24">

### 上板测试[](#id24 "Permalink to this heading")

在设计过程中建议CPU预留测试数据接口，上板测试前可以将对应接口接至板上的LED或七段数码管，显示CPU的内部状态。具体选择测试接口输出哪些内容可以自行决定，可以考虑PC、寄存器结果，控制信号等等。
在初次上板测试时，可以将CPU时钟连接到板载的KEY按钮上，每按一下单步执行一个周期，方便进行调试。

对于单周期CPU，由于需要在一个周期内完成指令执行的所有步骤，很可能不能以50MHz运行。请观察你的CPU综合后Timing Analysis结果是否存在时序不满足，即某些model下Setup Slack为负数。此时，可以考虑调整设计减少关键路径时延，或者降低主频。

</section>
</section>
<section id="id25">

## 实验验收要求[](#id25 "Permalink to this heading")

<section id="id26">

### 在线测试[](#id26 "Permalink to this heading")

请自行完成单周期CPU的实现，并通过在线测试中单周期CPU的功能测试及官方测试部分。

*   **必做** 单周期功能测试

*   **必做** 单周期CPU官方测试
<div class="admonition myinfo">

注意

由于我们在线测试仅针对单周期CPU，如果同学实现了多周期或流水线CPU可能会在时序上与在线测试结果不一致。可以自行参考课程网站上提供的test bench自行编写测试代码，需要完成RISC-V官方测试集中rv32ui-p开头的所有指令的测试，由助教现场验收后可以通过。

</div>
<div class="admonition myinfo">

致谢

感谢2019级李晗及高灏同学在RISC-V工具链方面的探索。

</div>
</section>
</section>
</section>

           </div>
          </div>
          <footer><div class="rst-footer-buttons" role="navigation" aria-label="Footer">
        [<span class="fa fa-arrow-circle-left" aria-hidden="true"></span> Previous](10.html "实验十 CPU数据通路")
        [Next <span class="fa fa-arrow-circle-right" aria-hidden="true"></span>](12.html "实验十二 计算机系统")
    </div>

* * *

  <div role="contentinfo">

&#169; Copyright 2022, 王炜 吴海军 陈璐.

  </div>

  Built with [Sphinx](https://www.sphinx-doc.org/) using a
    [theme](https://github.com/readthedocs/sphinx_rtd_theme)
    provided by [Read the Docs](https://readthedocs.org).

</footer>
        </div>
      </div>
    </section>
  </div>
  <script>
      jQuery(function () {
          SphinxRtdTheme.Navigation.enable(true);
      });
  </script> 

</body>
</html>