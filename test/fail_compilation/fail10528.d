/*
TEST_OUTPUT:
---
fail_compilation/fail10528.d(19): Error: module fail10528 variable a10528.a is private
fail_compilation/fail10528.d(20): Error: variable a10528.a is not accessible from module fail10528
fail_compilation/fail10528.d(22): Error: variable a10528.b is not accessible from module fail10528
fail_compilation/fail10528.d(23): Error: variable a10528.b is not accessible from module fail10528
fail_compilation/fail10528.d(25): Error: struct a10528.S member c is not accessible from module fail10528
fail_compilation/fail10528.d(26): Error: struct a10528.S member c is not accessible from module fail10528
fail_compilation/fail10528.d(28): Error: class a10528.C member d is not accessible from module fail10528
fail_compilation/fail10528.d(29): Error: class a10528.C member d is not accessible from module fail10528
---
*/

import imports.a10528;

void main()
{
    auto a1 = a;
    auto a2 = imports.a10528.a;

    auto b1 = b;
    auto b2 = imports.a10528.b;

    auto c1 = S.c;
    with (S) auto c2 = c;

    auto d1 = C.d;
    with (C) auto d2 = d;
}
