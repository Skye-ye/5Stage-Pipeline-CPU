OUTPUT_FORMAT("elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    IMEM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS {
    .text 0x00000000 : {
        KEEP(*(.text.init))
        *(.text)
        *(.text.startup)
        . = ALIGN(4);
    } > IMEM
    
    .rodata : {
        *(.rodata)
        . = ALIGN(4);
    } > IMEM
    
    .data : {
        *(.data)
        . = ALIGN(4);
    } > IMEM
    
    .bss : {
        _bss_start = .;
        *(.bss)
        *(COMMON)
        _bss_end = .;
        . = ALIGN(4);
    } > IMEM
    
    /DISCARD/ : {
        *(.comment)
        *(.debug*)
        *(.eh_frame)
        *(.riscv.attributes)
    }
}