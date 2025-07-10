#include <stdint.h>

// Enum for system states remains the same
typedef enum { STATE_RUNNING, STATE_PAUSED, STATE_SHUTDOWN } system_state_t;

// Global state variables remain the same
volatile system_state_t current_state = STATE_RUNNING;
volatile uint32_t work_timer = 0;

// CSR and cause definitions remain the same
#define CSR_MSTATUS 0x300
#define CSR_MIE 0x304
#define CSR_MTVEC 0x305
#define CSR_MEPC 0x341
#define CSR_MCAUSE 0x342

#define CAUSE_TIMER_INTERRUPT 0x80000007
#define CAUSE_EXTERNAL_INTERRUPT 0x8000000B
#define CAUSE_ECALL 11

#define SYS_EXIT 93

// CSR access macros remain the same
#define str(s) #s
#define xstr(s) str(s)

#define read_csr(reg)                                                          \
  ({                                                                           \
    unsigned long __tmp;                                                       \
    asm volatile("csrr %0, " xstr(reg) : "=r"(__tmp));                         \
    __tmp;                                                                     \
  })

#define write_csr(reg, val)                                                    \
  ({ asm volatile("csrw " xstr(reg) ", %0" ::"r"(val)); })

#define set_csr(reg, bit)                                                      \
  ({ asm volatile("csrrs zero, " xstr(reg) ", %0" ::"r"(bit)); })

#define clear_csr(reg, bit)                                                    \
  ({ asm volatile("csrrc zero, " xstr(reg) ", %0" ::"r"(bit)); })

// UART functions remain the same
static inline void uart_putchar(char c) {
  volatile unsigned char *uart_tx = (volatile unsigned char *)0xF004;
  *uart_tx = (unsigned char)c;
}

static void uart_puts(const char *str) {
  volatile unsigned char *uart_clear = (volatile unsigned char *)0xF00C;
  *uart_clear = 1;

  register const char *ptr = str;
  while (*ptr) {
    uart_putchar(*ptr);
    ptr++;
  }
}

// FIX: Combined into a single, clean syscall handler.
void handle_syscall() {
  uint32_t syscall_num;
  uint32_t arg0;

  // Read syscall number from a7 and argument from a0
  asm volatile("mv %0, a7" : "=r"(syscall_num));
  asm volatile("mv %0, a0" : "=r"(arg0));

  switch (syscall_num) {
  case SYS_EXIT:
    uart_puts("OFF ");
    uart_putchar(arg0 + '0');
    current_state = STATE_SHUTDOWN;
    break;
  default:
    uart_puts("UNKWN SYS");
    break;
  }
}

// FIX: The interrupt handler now calls the single `handle_syscall` function.
void __attribute__((interrupt)) interrupt_handler() {
  uint32_t cause = read_csr(CSR_MCAUSE);

  if (cause == CAUSE_TIMER_INTERRUPT) {
    work_timer++;
  } else if (cause == CAUSE_EXTERNAL_INTERRUPT) {
    if (current_state == STATE_RUNNING) {
      current_state = STATE_PAUSED;
      uart_puts("PAUSE");
      clear_csr(CSR_MIE, (1 << 7)); // Disable timer interrupt
    } else if (current_state == STATE_PAUSED) {
      current_state = STATE_RUNNING;
      uart_puts("JOB ");
      uart_putchar(work_timer + '0');
      set_csr(CSR_MIE, (1 << 7)); // Enable timer interrupt
    }
  } else if (cause == CAUSE_ECALL) {
    handle_syscall(); // Call the one, correct handler
    uint32_t mepc = read_csr(CSR_MEPC);
    write_csr(CSR_MEPC, mepc + 4); // Advance past the ecall instruction
  }
}

// The exit function remains the same
void exit(int status) {
  asm volatile("mv a7, %0" : : "r"(SYS_EXIT));
  asm volatile("mv a0, %0" : : "r"(status));
  asm volatile("ecall");
}

// The init function remains the same
void init_interrupts() {
  write_csr(CSR_MTVEC, (uint32_t)interrupt_handler);
  // Enable Timer (Bit 7) and External (Bit 11) interrupts
  write_csr(CSR_MIE, (1 << 7) | (1 << 11));
  // Enable Global Interrupts (MIE Bit 3)
  write_csr(CSR_MSTATUS, (1 << 3));
}

int main() {
  init_interrupts();
  uint32_t last_work_time = 0;
  uart_puts("HELLO");

  while (1) {
    if (current_state == STATE_RUNNING) {
      if (work_timer != last_work_time) {
        uart_puts("JOB ");
        uart_putchar(work_timer + '0');
        last_work_time = work_timer;
      }
      if (work_timer >= 6) {
        exit(0);
      }
      volatile int i = 0;
      while (i < 100000) {
        i++;
      }
    } else if (current_state == STATE_PAUSED) {
      volatile int i = 0;
      while (i < 100000) {
        i++;
      }
    } else if (current_state == STATE_SHUTDOWN) {
      break; // Exit the main loop
    }
  }

  return 0;
}