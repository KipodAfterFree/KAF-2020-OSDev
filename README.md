# KAF-2020-OSDev
OSDev was a reversing challenge in KAFCTF 2020.

This is a real-mode x86 assembly implementation of the AES encryption algorithm, in an MBR boot sector. It computes all constants (e.g. the S-box) at runtime,
which makes it a. vulnerable to side-channel attacks, and b. difficult to reverse engineer.
