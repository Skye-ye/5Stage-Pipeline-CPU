OUTPUT_FORMAT("elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    IMEM (rwx) : ORIGIN = 0x00000000, LENGTH = 4K
}

/* Stack configuration */
STACK_SIZE = 0x400;  /* 1KB stack */

SECTIONS {
    .text 0x00000000 : {
        KEEP(*(.text.init))
        *(.text)
        *(.text.startup)
        . = ALIGN(4);
    } > IMEM
    
    .rodata : {
        . = ALIGN(4);
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(4);
    } > IMEM
    
    .data : {
        . = ALIGN(4);
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
        . = ALIGN(4);
    } > IMEM
    
    .bss : {
        . = ALIGN(4);
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)
        _bss_end = .;
        . = ALIGN(4);
    } > IMEM
    
    /* Stack section */
    .stack : {
        . = ALIGN(16);
        _stack_start = .;
        . = . + STACK_SIZE;
        . = ALIGN(16);
        _stack_end = .;
        _stack_top = .;
    } > IMEM
    
    /* Provide stack pointer symbol */
    PROVIDE(__stack_top = _stack_top);
    
    /DISCARD/ : {
        *(.comment)
        *(.debug*)
        *(.eh_frame)
        *(.riscv.attributes)
    }
}