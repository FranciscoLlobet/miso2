/*
 * Picolibc runtime stubs for embedded/freestanding environment
 * These provide minimal implementations of required C library functions
 */

#include <stddef.h>
#include <stdio.h>

/* Dummy FILE structure for stderr stub */
static FILE __stdio_stderr = {0};

/* Provide stderr as required by picolibc's assert/abort */
FILE *const stderr = &__stdio_stderr;

/* Exit function - just loop forever in embedded systems */
void _exit(int status) {
    (void)status;
    while (1) {
        /* Infinite loop - system cannot exit */
        __asm__("wfi");  /* Wait for interrupt to save power */
    }
}
