# nimsimd

`nimble install nimsimd`

This repo provides pleasant Nim bindings for various SIMD instructions.

Each SIMD instruction set is in its own file for importing.

In addition to direct bindings to the SIMD instructions, there are also operator overloads to make for much more readable code (that is also easier to write!). See this basic example:

```nim
import nimsimd/sse2

# SIMD floating point multiplication
let
  a = m128(1.0) # Vector of 4 float32 each with value 1.0
  b = m128(2.0) # Vector of 4 float32 each with value 2.0
  c = a * b # SIMD vector multiplication operator

# Cast the vector to echo as separate float32 values
echo cast[array[4, float32]](c)
```

## Testing

`nimble test`
