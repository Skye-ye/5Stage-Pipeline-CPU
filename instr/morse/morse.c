// RISC-V RV32I Base ISA Morse code decoder

typedef struct {
  char letter;
  char morse[6];
} MorseCode;

// Static morse table in .rodata
static const MorseCode morseTable[] = {
    {'A', ".-"},    {'B', "-..."},  {'C', "-.-."},  {'D', "-.."},
    {'E', "."},     {'F', "..-."},  {'G', "--."},   {'H', "...."},
    {'I', ".."},    {'J', ".---"},  {'K', "-.-"},   {'L', ".-.."},
    {'M', "--"},    {'N', "-."},    {'O', "---"},   {'P', ".--."},
    {'Q', "--.-"},  {'R', ".-."},   {'S', "..."},   {'T', "-"},
    {'U', "..-"},   {'V', "...-"},  {'W', ".--"},   {'X', "-..-"},
    {'Y', "-.--"},  {'Z', "--.."},  {'0', "-----"}, {'1', ".----"},
    {'2', "..---"}, {'3', "...--"}, {'4', "....-"}, {'5', "....."},
    {'6', "-...."}, {'7', "--..."}, {'8', "---.."}, {'9', "----."}};

// Constants - avoid multiplication
#define MORSE_TABLE_SIZE 36

static inline int my_strlen(const char *str) {
  register int len = 0;
  register const char *ptr = str;

  while (*ptr != '\0') {
    ptr++;
    len++;
  }
  return len;
}

static inline int my_strcmp(const char *str1, const char *str2) {
  register const char *p1 = str1;
  register const char *p2 = str2;
  register char c1, c2;

  while (1) {
    c1 = *p1++;
    c2 = *p2++;

    if (c1 != c2) {
      return c1 - c2;
    }

    if (c1 == '\0') {
      return 0;
    }
  }
}

static inline char morseToChar(const char *morse) {
  register int i = 0;

  while (i < MORSE_TABLE_SIZE) {
    if (my_strcmp(morse, morseTable[i].morse) == 0) {
      return morseTable[i].letter;
    }
    i++;
  }
  return '?';
}

static inline void uart_putchar(char c) {
  volatile unsigned char *uart_tx = (volatile unsigned char *)0x00;
  // volatile unsigned int *uart_status = (volatile unsigned int *)0xF004;

  // Wait for TX ready bit
  // while ((*uart_status & 1) == 0) {
  //   // Busy wait
  // }

  // Send character
  *uart_tx = (unsigned char)c;
}

// String output function
static void uart_puts(const char *str) {
  register const char *ptr = str;
  while (*ptr) {
    uart_putchar(*ptr);
    ptr++;
  }
}

// Core decoding function - optimized for RV32I base ISA
void decode_morse_message(const char *input, char *output) {
  register const char *in_ptr = input;
  register char *out_ptr = output;
  char token[8];
  register int token_idx;
  register char current_char;

  while (*in_ptr != '\0') {
    // Skip leading spaces
    while (*in_ptr == ' ') {
      in_ptr++;
    }

    if (*in_ptr == '\0')
      break;

    // Extract token - avoid complex indexing
    token_idx = 0;
    while (token_idx < 7) {
      current_char = *in_ptr;

      if (current_char == ' ' || current_char == '\0') {
        break;
      }

      token[token_idx] = current_char;
      token_idx++;
      in_ptr++;
    }
    token[token_idx] = '\0';

    // Handle word separator
    if (token[0] == '/') {
      *out_ptr = ' ';
      out_ptr++;
      continue;
    }

    // Decode morse character
    char decoded = morseToChar(token);
    *out_ptr = decoded;
    out_ptr++;

    // Check for multiple spaces (word boundary)
    register int space_count = 0;
    register const char *temp_ptr = in_ptr;

    while (*temp_ptr == ' ') {
      space_count++;
      temp_ptr++;
    }

    // Add word separator if multiple spaces
    if (space_count > 1) {
      *out_ptr = ' ';
      out_ptr++;
    }
  }

  *out_ptr = '\0';
}

// Main function - entry point called from startup.s
int main(void) {
  // Use stack-based array instead of global data that needs copying
  char morse_input[] = ".... . .-.. .-.. ---";
  char decoded_output[128];

  // Decode the message
  decode_morse_message(morse_input, decoded_output);

  // Output result - use string literals (will be in .rodata)
  uart_puts("Decoded: ");
  uart_puts(decoded_output);
  uart_puts("\r\n");

  return 0;
}