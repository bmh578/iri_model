#include <stdio.h>
#include "example.h"

int main() {
    int a = 5;
    int b = 3;
    int result = add_numbers(a, b);
    printf("Result of %d + %d = %d\n", a, b, result);
    return 0;
} 