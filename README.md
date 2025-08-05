# nimsimd

![Github Actions](https://github.com/guzba/nimsimd/workflows/Github%20Actions/badge.svg)

`nimble install nimsimd`

This repo provides pleasant Nim bindings for various SIMD instructions.

Each SIMD instruction set is in its own file for importing.

## x86

Instruction Set | Bindings | Wiki
--------- | :---|---------------
SSE       | ✅ | [Streaming SIMD Extensions](https://en.wikipedia.org/wiki/Streaming_SIMD_Extensions)
SSE2      | ✅ |
SSE3      | ✅ |
SSSE3     | ✅ |
SSE4.1    | ✅ |
SSE4.2    | ✅ |
AVX       | ✅ | [Advanced Vector Extensions](https://en.wikipedia.org/wiki/Advanced_Vector_Extensions) a.k.a _AVX1_
AVX2      | ✅ | 
PCLMULQDQ | ✅ | [Carryless Multiplication](https://en.wikipedia.org/wiki/CLMUL_instruction_set) 
BMI1      | ✅ | [Bit Manipulation Instruction Set(s)](https://en.wikipedia.org/wiki/X86_Bit_manipulation_instruction_set)
BMI2      | ✅ |
F16C      | ✅ | _Half-precision_ [Floating Point 16 Conversion](https://en.wikipedia.org/wiki/F16C)
MOVBE     | ✅ |
POPCNT    | ✅ | Pop-Count a.k.a. [Hamming Weight](https://en.wikipedia.org/wiki/Hamming_weight)
FMA       | ✅ | [Fused-Multiply-Add](https://en.wikipedia.org/wiki/FMA_instruction_set) a.k.a _FMA3_
FMA4      | | 
TSC       | ✅ | [Time Stamp Counter](https://en.wikipedia.org/wiki/Time_Stamp_Counter)
RDTSC     | ✅ | Read Time Stamp Counter
AES       | ✅ | [AES Instruction set](https://en.wikipedia.org/wiki/AES_instruction_set)
RDRAND    | ✅ | [Read Random](https://en.wikipedia.org/wiki/RDRAND)
CRC32     | ✅ | [Cyclic Redundancy Checks](https://en.wikipedia.org/wiki/Computation_of_cyclic_redundancy_checks#CRC-32_example)
LZCNT     | ✅ | [Leading Zeros Count](https://en.wikipedia.org/wiki/Find_first_set) a.k.a _Find first set bit_

### Compiler flags

Some instruction sets require additional compiler flags to compile. I suggest
putting any code that uses these instructions into its own .nim file and adding a `localPassc` pragma to the top of that file as needed, such as:

```nim
import nimsimd/sse42

when defined(gcc) or defined(clang):
  {.localPassc: "-msse4.2".}

...
```

### Runtime check

You can also check if instruction sets are available at runtime:

```nim
import nimsimd/runtimecheck

echo checkInstructionSets({SSE41, PCLMULQDQ})
```

## ARM

NEON bindings are started but experimental. Much to learn here about versioning and compilers.

## Uses of nimsimd

* [Pixie](https://github.com/treeform/pixie) uses SIMD for faster 2D drawing.
* [Crunchy](https://github.com/guzba/crunchy) uses SIMD for faster hashing and checksums.
* [Noisy](https://github.com/guzba/noisy) uses SIMD to accelerate generating coherent noise.

## Testing

`nimble test`
