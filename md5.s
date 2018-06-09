.section .rodata
    f_hexa: .asciz "%02x"
    rb: .asciz "rb"
    MD5_out: .asciz "  %s"
    err_msg: .asciz "%s: no existe tal archivo o no pudo ser abierto"
    barra: .asciz "\n"
    S11: .long 7
    S12: .long 12
    S13: .long 17
    S14: .long 22
    S21: .long 5
    S22: .long 9
    S23: .long 14
    S24: .long 20
    S31: .long 4
    S32: .long 11
    S33: .long 16
    S34: .long 23
    S41: .long 6
    S42: .long 10
    S43: .long 15
    S44: .long 21
    padding: .byte 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.section .bss
    .comm context, 88, 1
    .comm file, 4
    .comm buffer, 1024, 1
    .comm digest, 64, 4
    .comm bits_arr, 8, 1
    .comm x, 64, 4
    .comm a, 4
    .comm b, 4
    .comm c, 4
    .comm d, 4
.section .text
.globl _start
_start:

    movl (%esp), %ecx # argc
    movl 8(%esp), %edx # argv[1]

    movl $1, %edi

    main_loop:

        cmpl %ecx, %edi
        jge exit

        pushl %ecx # resguardando
        pushl %edx
        pushl %edi

        pushl %edx
        call MD5File
        addl $4, %esp

        popl %edi
        popl %edx # retrieving
        popl %ecx

        pushl %ecx # resguardando (again)
        pushl %edx

        pushl %edx
        call strlen
        addl $4, %esp

        popl %edx # retrieving (again)
        popl %ecx

        addl $1, %eax
        addl %eax, %edx

        incl %edi
        jmp main_loop

exit:
    movl $1, %eax
    movl $0, %ebx
    int $0x80


MD5Print:
    pushl %ebp
    movl %esp, %ebp
    movl $0, %edi
    movl 8(%ebp), %edx # recibe apuntador al array digest[]
    for:
        pushl %edx
        movb (%edi,%edx,), %dl

        xor %eax, %eax
        movb %dl, %al

        pushl %eax
        pushl $f_hexa
        call printf
        addl $8, %esp
        popl %edx
        incl %edi
        cmpl $16, %edi
        jl for
    leave
    ret

MD5File:
    pushl %ebp
    movl %esp, %ebp
    movl 8(%ebp), %edx # recibe apuntador al nombre del archivo

    pushl $rb # intenta abrir. Si no puede, aborta
    pushl %edx
    call fopen
    addl $8, %esp
    movl %eax, file

    pushl $context # incializando el contexto
    call MD5Init
    addl $4, %esp

    while:
        pushl file
        pushl $1024
        pushl $1
        pushl $buffer # leyendo en 1024 bloques de tamaño 1
        call fread
        addl $16, %esp
        cmpl $0, %eax
        je end

        pushl %eax # <--- len esta en %eax
        pushl $buffer
        pushl $context
        call MD5Update
        addl $12, %esp
        jmp while
    end:
        pushl $context
        pushl $digest # fin del while, llamando a MD5Final
        call MD5Final # para el append, etc
        addl $8, %esp

    pushl file
    call fclose # cerrando el archivo
    addl $4, %esp

    pushl $digest
    call MD5Print
    addl $4, %esp

    pushl 8(%ebp) # nombre del archivo again
    pushl $MD5_out
    call printf
    addl $8, %esp

    pushl $barra
    call printf
    addl $4, %esp

    pushl $0
    call fflush
    addl $4, %esp

    leave
    ret

MD5Init:
    pushl %ebp
    movl %esp, %ebp
    movl 8(%ebp), %edx # recibe apuntador a context

    movl $0, 16(%edx) # context->count[0]
    movl $0, 20(%edx) # context->count[1]

    movl $0x67452301, (%edx) # context->state[0]
    movl $0xefcdab89, 4(%edx) # context->state[1]
    movl $0x98badcfe, 8(%edx) # context->state[2]
    movl $0x10325476, 12(%edx) # context->state[3]

    leave
    ret

MD5Update:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %edx # apuntador a context
    movl 16(%edx), %ecx # context->count[0], index en %ecx
    shrl $3, %ecx # sacando mod
    andl $0x3F, %ecx
    movl 16(%ebp), %ebx # inputLen en %ebx
    shll $3, %ebx
    addl %ebx, 16(%edx)
    cmpl 16(%edx), %ebx
    jbe continue_update
    incl 20(%edx)
continue_update:
    movl 16(%ebp), %ebx # inputLen en %ebx
    shrl $29, %ebx
    addl %ebx, 20(%edx)

    leal -64(%ecx), %eax # partLen en %eax
    pushl %eax
    call abs
    addl $4, %esp
    movl 16(%ebp), %ebx # inputLen->ebx

    cmpl %eax, %ebx
    jb else_update

    pushl %eax # resguardando
    pushl %ecx

    pushl %eax
    pushl 12(%ebp) # *input
    leal 24(%ecx, %edx,), %eax
    pushl %eax # &context->buffer[index]
    call memcpy
    addl $12, %esp

    popl %ecx
    popl %eax

    pushl %eax # resguardando
    pushl %ecx

    movl 8(%ebp), %edx
    leal 24(%edx), %eax
    pushl %eax
    pushl %edx
    call MD5Transform
    addl $8, %esp

    popl %ecx
    popl %eax

    movl %eax, %esi
    for_update:
        movl 16(%ebp), %ebx
        leal 63(%esi), %edi
        cmpl %ebx, %edi
        jae endfor_update

        movl 12(%ebp), %edx # &input[i] en %edx
        addl %esi, %edx

        pushl %ecx # resguardando
        pushl %esi

        pushl %edx # &input[i]
        pushl 8(%ebp) # context->state
        call MD5Transform
        addl $8, %esp

        popl %esi
        popl %ecx

        addl $64, %esi
        jmp for_update

    endfor_update:
        movl $0, %ecx # index
        jmp end_if_update
 else_update:
        movl $0, %esi
end_if_update:

    movl 16(%ebp), %eax # inputLen
    movl %esi, %ebx
    subl %eax, %ebx
    pushl %eax
    pushl %ebx
    call abs
    add $4, %esp
    movl %eax, %ebx
    popl %eax

    pushl %ebx # inputLen-i
    movl 12(%ebp), %eax # &input[i]
    addl %esi, %eax
    pushl %eax
    movl 8(%ebp), %edx
    leal 24(%ecx,%edx,), %edx # &context->buffer[index]
    pushl %edx
    call memcpy
    addl $12, %esp

    leave
    ret

MD5Final:
    pushl %ebp
    movl %esp, %ebp

    pushl $8
    movl 12(%ebp), %eax
    addl $16, %eax
    pushl %eax
    pushl $bits_arr
    call memcpy
    addl $12, %esp

    movl 12(%ebp), %edx # apuntador a context
    movl 16(%edx), %ecx # context->count[0], index en %ecx
    shrl $3, %ecx # sacando mod
    andl $0x3F, %ecx # index->%ecx

    quick_if:
        cmpl $56, %ecx
        jae else_quick_if
        subl $56, %ecx
        jmp end_quick_if
    else_quick_if:
        subl $120, %ecx
    end_quick_if: # ahora %ecx es padLen

    pushl %eax
    pushl %ecx
    call abs
    addl $4, %esp
    movl %eax, %ecx
    popl %eax

    pushl %ecx
    pushl $padding
    pushl 12(%ebp)
    call MD5Update
    addl $12, %esp

    pushl $8
    pushl $bits_arr
    pushl 12(%ebp)
    call MD5Update
    addl $12, %esp

    pushl $16
    pushl 12(%ebp)
    pushl $digest
    call memcpy
    addl $12, %esp

    pushl $88
    pushl $0
    pushl 12(%ebp)
    call memset
    addl $12, %esp

    leave
    ret

F:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %ebx # x
    movl 12(%ebp), %ecx # y
    movl 16(%ebp), %edx # z

    andl %ebx, %ecx # y & x -> ecx
    notl %ebx # ~x -> ebx
    andl %ebx, %edx # z & ~x -> edx
    orl %ecx, %edx

    movl %edx, %eax
    leave
    ret


G:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %ebx # x
    movl 12(%ebp), %ecx # y
    movl 16(%ebp), %edx # z

    andl %edx, %ebx # x = x & z
    notl %edx # z = ~z
    andl %edx, %ecx # z = y & ~z
    orl %ebx, %ecx

    movl %ecx, %eax
    leave
    ret


H:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax
    movl 12(%ebp), %ebx
    movl 16(%ebp), %ecx

    xorl %eax, %ebx
    xorl %ebx, %ecx
    movl %ecx, %eax

    leave
    ret

I:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax
    movl 12(%ebp), %ebx
    movl 16(%ebp), %ecx

    notl %ecx
    orl %ecx, %eax
    xorl %eax, %ebx
    movl %ebx, %eax
    leave
    ret

FF:

    pushl %ebp
    movl %esp, %ebp

    pushl 20(%ebp) # F(b, c, d) -> eax
    pushl 16(%ebp)
    pushl 12(%ebp)
    call F
    addl $12, %esp

    movl 8(%ebp), %ebx # copiando &a
    movl (%ebx), %ebx # "deferencing" a

    addl 24(%ebp), %eax # F(b, c, d) + x -> eax
    addl 32(%ebp), %eax # eax + ac -> eax

    addl %ebx, %eax # eax + a -> eax

    movl 28(%ebp), %ecx
    roll %cl, %eax

    addl 12(%ebp), %eax # b + eax -> eax

    movl 8(%ebp), %ebx  # making sure eax esta en &a
    movl %eax, (%ebx)

    leave
    ret

GG:

    pushl %ebp
    movl %esp, %ebp

    pushl 20(%ebp) # F(b, c, d) -> eax
    pushl 16(%ebp)
    pushl 12(%ebp)
    call G
    addl $12, %esp

    movl 8(%ebp), %ebx # copiando &a
    movl (%ebx), %ebx # "deferencing" a

    addl 24(%ebp), %eax # F(b, c, d) + x -> eax
    addl 32(%ebp), %eax # eax + ac -> eax

    addl %ebx, %eax # eax + a -> eax

    movl 28(%ebp), %ecx
    roll %cl, %eax

    addl 12(%ebp), %eax # b + eax -> eax

    movl 8(%ebp), %ebx  # making sure eax esta en &a
    movl %eax, (%ebx)

    leave
    ret
HH:

    pushl %ebp
    movl %esp, %ebp

    pushl 20(%ebp) # F(b, c, d) -> eax
    pushl 16(%ebp)
    pushl 12(%ebp)
    call H
    addl $12, %esp

    movl 8(%ebp), %ebx # copiando &a
    movl (%ebx), %ebx # "deferencing" a

    addl 24(%ebp), %eax # F(b, c, d) + x -> eax
    addl 32(%ebp), %eax # eax + ac -> eax

    addl %ebx, %eax # eax + a -> eax

    movl 28(%ebp), %ecx
    roll %cl, %eax

    addl 12(%ebp), %eax # b + eax -> eax

    movl 8(%ebp), %ebx  # making sure eax esta en &a
    movl %eax, (%ebx)

    leave
    ret
II:

    pushl %ebp
    movl %esp, %ebp

    pushl 20(%ebp) # F(b, c, d) -> eax
    pushl 16(%ebp)
    pushl 12(%ebp)
    call I
    addl $12, %esp

    movl 8(%ebp), %ebx # copiando &a
    movl (%ebx), %ebx # "deferencing" a

    addl 24(%ebp), %eax # F(b, c, d) + x -> eax
    addl 32(%ebp), %eax # eax + ac -> eax

    addl %ebx, %eax # eax + a -> eax

    movl 28(%ebp), %ecx
    roll %cl, %eax

    addl 12(%ebp), %eax # b + eax -> eax

    movl 8(%ebp), %ebx  # making sure eax esta en &a
    movl %eax, (%ebx)

    leave
    ret

MD5Transform:

    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax # cargando parametros
    movl (%eax), %ebx
    movl %ebx, a
    movl 4(%eax), %ebx
    movl %ebx, b
    movl 8(%eax), %ebx
    movl %ebx, c
    movl 12(%eax), %ebx
    movl %ebx, d

    pushl $64 # llamando a Decode
    pushl 12(%ebp)
    pushl $x
    call memcpy
    addl $12, %esp

    # hell
    pushl $0xd76aa478; pushl S11; movl $0, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call FF; addl $28, %esp
    pushl $0xe8c7b756; pushl S12; movl $1, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call FF; addl $28, %esp
    pushl $0x242070db; pushl S13; movl $2, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call FF; addl $28, %esp
    pushl $0xc1bdceee; pushl S14; movl $3, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call FF; addl $28, %esp
    pushl $0xf57c0faf; pushl S11; movl $4, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call FF; addl $28, %esp
    pushl $0x4787c62a; pushl S12; movl $5, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call FF; addl $28, %esp
    pushl $0xa8304613; pushl S13; movl $6, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call FF; addl $28, %esp
    pushl $0xfd469501; pushl S14; movl $7, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call FF; addl $28, %esp
    pushl $0x698098d8; pushl S11; movl $8, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call FF; addl $28, %esp
    pushl $0x8b44f7af; pushl S12; movl $9, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call FF; addl $28, %esp
    pushl $0xffff5bb1; pushl S13; movl $10, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call FF; addl $28, %esp
    pushl $0x895cd7be; pushl S14; movl $11, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call FF; addl $28, %esp
    pushl $0x6b901122; pushl S11; movl $12, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call FF; addl $28, %esp
    pushl $0xfd987193; pushl S12; movl $13, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call FF; addl $28, %esp
    pushl $0xa679438e; pushl S13; movl $14, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call FF; addl $28, %esp
    pushl $0x49b40821; pushl S14; movl $15, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call FF; addl $28, %esp

    pushl $0xf61e2562; pushl S21; movl $1, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call GG; addl $28, %esp
    pushl $0xc040b340; pushl S22; movl $6, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call GG; addl $28, %esp
    pushl $0x265e5a51; pushl S23; movl $11, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call GG; addl $28, %esp
    pushl $0xe9b6c7aa; pushl S24; movl $0, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call GG; addl $28, %esp
    pushl $0xd62f105d; pushl S21; movl $5, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call GG; addl $28, %esp
    pushl $0x02441453; pushl S22; movl $10, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call GG; addl $28, %esp
    pushl $0xd8a1e681; pushl S23; movl $15, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call GG; addl $28, %esp
    pushl $0xe7d3fbc8; pushl S24; movl $4, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call GG; addl $28, %esp
    pushl $0x21e1cde6; pushl S21; movl $9, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call GG; addl $28, %esp
    pushl $0xc33707d6; pushl S22; movl $14, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call GG; addl $28, %esp
    pushl $0xf4d50d87; pushl S23; movl $3, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call GG; addl $28, %esp
    pushl $0x455a14ed; pushl S24; movl $8, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call GG; addl $28, %esp
    pushl $0xa9e3e905; pushl S21; movl $13, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call GG; addl $28, %esp
    pushl $0xfcefa3f8; pushl S22; movl $2, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call GG; addl $28, %esp
    pushl $0x676f02d9; pushl S23; movl $7, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call GG; addl $28, %esp
    pushl $0x8d2a4c8a; pushl S24; movl $12, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call GG; addl $28, %esp

    pushl $0xfffa3942; pushl S31; movl $5, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call HH; addl $28, %esp
    pushl $0x8771f681; pushl S32; movl $8, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call HH; addl $28, %esp
    pushl $0x6d9d6122; pushl S33; movl $11, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call HH; addl $28, %esp
    pushl $0xfde5380c; pushl S34; movl $14, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call HH; addl $28, %esp
    pushl $0xa4beea44; pushl S31; movl $1, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call HH; addl $28, %esp
    pushl $0x4bdecfa9; pushl S32; movl $4, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call HH; addl $28, %esp
    pushl $0xf6bb4b60; pushl S33; movl $7, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call HH; addl $28, %esp
    pushl $0xbebfbc70; pushl S34; movl $10, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call HH; addl $28, %esp
    pushl $0x289b7ec6; pushl S31; movl $13, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call HH; addl $28, %esp
    pushl $0xeaa127fa; pushl S32; movl $0, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call HH; addl $28, %esp
    pushl $0xd4ef3085; pushl S33; movl $3, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call HH; addl $28, %esp
    pushl $0x04881d05; pushl S34; movl $6, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call HH; addl $28, %esp
    pushl $0xd9d4d039; pushl S31; movl $9, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call HH; addl $28, %esp
    pushl $0xe6db99e5; pushl S32; movl $12, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call HH; addl $28, %esp
    pushl $0x1fa27cf8; pushl S33; movl $15, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call HH; addl $28, %esp
    pushl $0xc4ac5665; pushl S34; movl $2, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call HH; addl $28, %esp

    pushl $0xf4292244; pushl S41; movl $0, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call II; addl $28, %esp
    pushl $0x432aff97; pushl S42; movl $7, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call II; addl $28, %esp
    pushl $0xab9423a7; pushl S43; movl $14, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call II; addl $28, %esp
    pushl $0xfc93a039; pushl S44; movl $5, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call II; addl $28, %esp
    pushl $0x655b59c3; pushl S41; movl $12, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call II; addl $28, %esp
    pushl $0x8f0ccc92; pushl S42; movl $3, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call II; addl $28, %esp
    pushl $0xffeff47d; pushl S43; movl $10, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call II; addl $28, %esp
    pushl $0x85845dd1; pushl S44; movl $1, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call II; addl $28, %esp
    pushl $0x6fa87e4f; pushl S41; movl $8, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call II; addl $28, %esp
    pushl $0xfe2ce6e0; pushl S42; movl $15, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call II; addl $28, %esp
    pushl $0xa3014314; pushl S43; movl $6, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call II; addl $28, %esp
    pushl $0x4e0811a1; pushl S44; movl $13, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call II; addl $28, %esp
    pushl $0xf7537e82; pushl S41; movl $4, %esi; pushl x(, %esi, 4); pushl d; pushl c; pushl b; pushl $a; call II; addl $28, %esp
    pushl $0xbd3af235; pushl S42; movl $11, %esi; pushl x(, %esi, 4); pushl c; pushl b; pushl a; pushl $d; call II; addl $28, %esp
    pushl $0x2ad7d2bb; pushl S43; movl $2, %esi; pushl x(, %esi, 4); pushl b; pushl a; pushl d; pushl $c; call II; addl $28, %esp
    pushl $0xeb86d391; pushl S44; movl $9, %esi; pushl x(, %esi, 4); pushl a; pushl d; pushl c; pushl $b; call II; addl $28, %esp

    movl 8(%ebp), %ebx

    leal (%ebx), %eax
    movl a, %ecx
    addl %ecx, (%eax)

    leal 4(%ebx), %eax
    movl b, %ecx
    addl %ecx, (%eax)

    leal 8(%ebx), %eax
    movl c, %ecx
    addl %ecx, (%eax)

    leal 12(%ebx), %eax
    movl d, %ecx
    addl %ecx, (%eax)

    pushl $64 # sizeof(x)
    pushl $0
    pushl $x
    call memset
    addl $12, %esp

    leave
    ret

abs:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax
    testl %eax, %eax
    js signed
    jmp not_signed
    signed:
        notl %eax
	incl %eax
    not_signed:

    leave
    ret
