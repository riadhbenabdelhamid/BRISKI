/* Define memory regions */
MEMORY
{
    /* Define RAM and ROM memory regions with specific addresses and sizes */
    RAM (rwx) : ORIGIN = 0x00000200, LENGTH = 3072
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 1024
}

/* Define the sections and their placement */
SECTIONS
{
    /* Place the .text section in ROM */
    .text : {
        *(.text) /* All .text sections from input files */
    } >ROM

    /* Place the .data section in RAM */
    .data : {
        *(.data) /* All .data sections from input files */
    } >RAM


    /* Additional sections can be added here */
}
