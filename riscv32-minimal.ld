/* RISC-V 32-bit Minimal Linker Script
 * Keeps only necessary sections to minimize output size
 */
OUTPUT_FORMAT("elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
    . = 0x00000000;
    
    /* Code section */
    .text : {
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
    }
    
    /* Data section - immediately after text */
    .data : {
        . = ALIGN(4);
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
    }
    
    /* BSS is typically zeroed, so we can exclude it from binary */
    .bss (NOLOAD) : {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)
        __bss_end = .;
    }
    
    /* Store end of used memory */
    _end = .;
    
    /* Discard everything else */
    /DISCARD/ : {
        *(.comment)
        *(.debug*)
        *(.eh_frame)
        *(.riscv.attributes)
    }
}