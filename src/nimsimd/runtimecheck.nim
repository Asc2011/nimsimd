{.experimental: "dotOperators".}
{.experimental : "codeReordering".}

from std/strformat import fmt
from std/unicode   import reversed, toLower
from std/strutils  import join, split
from std/bitops    import testBit, BitsRange, bitSliced, setBit

when NimMajor >= 2 :
  proc unsafeAddr[T]( o :T ) :ptr T = o.addr

const 
  fp :bool = when defined(debug) :true else :false
  NL = '\n'

  CommonLabel = [                      
    "a",   "b",   "c",   "d",   # for the purists
    "r1",  "r2",  "r3",  "r4",  # for the CS loosers
    "aaa", "bbb", "ccc", "ddd", # for cognitive-scientists/UI-pros
    "eax", "ebx", "ecx", "edx"  # when u love standards
  ]
var
  RegisterLabel* :seq[string] = CommonLabel[0..15] & @[
    "tick", "trick", "track",    "donald",   # Donaldists
    "joe",  "jack",  "william",  "averett",  # Cowboys
    "first", "second", "third",  "fourth",   # quick-on-the-keys
    "apple", "banana", "citron", "date",     # Frutarians
    "atilla", "babe",  "candy",  "dolly",    # pr0n-fans
    "abram",  "bar",   "chai",   "dana",     # Jews
    "leftmost", "left", "right", "rightmost" # 2d-thinkers
    # ... this is public & writable ...
  ]
type 
  II = tuple[ filename :string; line, column :int ]
  UArr[T] = UncheckedArray[T] 
  Leaf* {.borrow.} = distinct array[4, int32] 

proc errorMsg( ii :II, ident :string ) {.noReturn.} = 
  let msg = fmt"Unknown register-label '{ident}' ? "
  quit msg & fmt"{ii.fileName} [{ii.line}, {ii.column}]"

func `[]`*(  l :Leaf, i :int )  :int32   = 
  cast[ ptr UArr[int32] ]( l.unsafeAddr )[i]
func `[]=`*(l :Leaf, i :int, v :int32 ) = 
  cast[ ptr UArr[int32] ]( l.unsafeAddr )[i] = v

func `[]`*[ T :SomeInteger ](i :T, ft :HSlice[int,int]) :int = 
  var start :BitsRange[T] = ft.a; var fin :BitsRange[T] = ft.b
  if fin < start : start.swap fin
  i.bitSliced start.int .. fin.int

proc toMask( arr :varargs[int] ) :int32 = 
  for pos in arr : result.setBit pos

proc asLeaf*( arr :array[4, int32] ) :Leaf = 
  cast[ptr Leaf]( arr.unsafeAddr )[]
proc asLeaf*[T :SomeInteger]( arr :openArray[T] ) :Leaf = 
  for i in 0..(if arr.high > 2: 3 else: arr.high) : 
    result[i] = arr[i].int32

when defined( debug ): 
  proc `$`*( l :Leaf ) :string = 
    let pt = cast[ptr UArr[uint8]]( l.unsafeAddr )
    var bits :array[ 4, seq[string] ]
    for i in 0..3 :
      for j in 0..3 : 
        let b = pt[ i*4 + j ]
        bits[i].add ( fmt"{b:.>8b}".reversed & fmt"│{b:<3} " )
    result = NL & fmt"Leaf[                                          msb─┐" & NL &
      fmt" A │{bits[0].join}{l[0]:.<X}h" & NL &
      fmt" B │{bits[1].join}{l[1]:.<X}h" & NL &
      fmt" C │{bits[2].join}{l[2]:.<X}h" & NL &
      fmt" D │{bits[3].join}{l[3]:.<X}h" & NL &
      fmt"]  └─lsb" & NL
else:
  proc `$`*( l :Leaf ) :string = "\n" & 
    fmt"Leaf [ {l[0]:>8x}H {l[1]:>8x}H {l[2]:>8x}H {l[3]:>8x}H ]"

proc getIdx( label :string ) :(string, int) = 
  {.gcsafe.} : (label, RegisterLabel.find label.toLower)

# (1) Leaf.<register-label> returns one i32 from slot.
#
template `.`*( leaf :Leaf, field :untyped ) :int32 = 
  let (label, idx) = getIdx astToStr field
  if idx == -1 : errorMsg( instantiationInfo( fullPaths=fp ), label )
  leaf[ idx mod 4 ]

# (1a) Leaf.<register-label> = Int -> dunk int into slot.
#
template `.=`*( leaf :Leaf, field :untyped, v :SomeInteger ) = #:untyped = 
  let (label, idx) = getIdx astToStr field
  if idx == -1 : errorMsg( instantiationInfo( fullPaths=fp ), label )
  leaf[ idx mod 4 ] = v.int32

# (2) Leaf.<label> bitPosition:int -> true if bit-position is set.
#
template `.`*( leaf :Leaf, field :untyped, pos :BitsRange[int32] ) :bool = 
  let (label, idx) = getIdx astToStr field
  if idx == -1 : errorMsg( instantiationInfo( fullPaths=fp ), label )
  leaf[ idx mod 4 ].testBit pos

# (3) Leaf.<label> HSlice[a,b] -> int of sliced bit-range.
#
template `.`*( l :Leaf, field :untyped, fromTo :HSlice[int, int] ) :int = 
  let (label, idx) = getIdx astToStr field
  if idx == -1 : errorMsg( instantiationInfo( fullPaths=fp ), label )
  leaf[ idx mod 4 ][ fromTo ]

# (4) Leaf.label> seq[int] -> int32 AND-masked with indices from array.
#
template `.`*( l :Leaf, field :untyped, maskBits :openArray[int] ) :int32 = 
  let (label, idx) = getIdx astToStr field
  if idx == -1 : errorMsg( instantiationInfo( fullPaths=fp ), label )
  leaf[ idx mod 4 ] and toMask( maskBits )



when defined(amd64):
  ## https://www.felixcloutier.com/x86/cpuid
  ## (cross-checking) https://docs.rs/iced-x86/latest/iced_x86/enum.CpuidFeature.html
  ## finally, the source-of-truth https://gitlab.com/x86-cpuid.org/x86-cpuid-db/-/tree/tip/db?ref_type=heads
  
  # when defined(isAMD):
  #   type
  #     InstructionSet* = enum
  #       LWP
  #       XOP
  #       FMA4
  #       D3NOW
  #       D3NOWEXT
  #       RDPRU
  # else :
  type
    InstructionSet* = enum
      SSE3
      PCLMULQDQ           # Carry-less Multiplication (CLMUL).
      MONITOR       
      SMX                 # Secure Matrix Extension a.k.a. TSX -> Transactional Synchronization Ext.
      SSSE3       
      VMX                 # Virtual Machine Extensions
      FMA                 # Fused-Multiply-Add
      CMPXCHG16B
      SSE41
      SSE42
      CRC32
      MOVBE
      POPCNT
      TSC_DEADLINE_TIMER  # TSC is programmable.
      AES                 # Advanced Encryption Standard
      XSAVE
      OSXSAVE
      AVX                 # Advanced Vector Extensions
      F16C                # a.k.a CVT16 convert float16 (half-precision)
      RDRAND              # RD random
      TSC                 # Time-stamp-counter
      MSR                 # Model-specific Register
      NONSTOP_TSC         # nonstop TSP implies constant-tsp
      SEP                 # System Event Pointer
      CMOV                # Conditional Move
      PSN                 # Processor-Serial-Number
      CLFSH               # Flush Cache Line
      MMX                 # Multimedia Extensions
      FXSR
      SSE           
      SSE2
      SHA512              # SHA512
      SM3                 #
      SM4                 # 
      RAO_INT             # New atomic operations by Intel (not released 2025)
      AVX_VNNI            #
      AVX512_BF16
      CMPCCXADD           #
      WRMSRNS             # Non-Serializing Write to Model Specific Register instruction
      AMX_FP16            #
      HRESET              # History Reset
      AVX_IFMA            #
      LAM                 # Linear Address Masking
      MSRLIST             # MSR 
      FSGSBASE            # Write to FS- & GS-Segment Base-registers
      TSC_ADJUST          # 
      BMI1                # Bit Manipulation Instruction Set 1
      HLE                 # Hardware Lock Elision 
      AVX2                # Advanced Vector Extensions 2
      BMI2                # Bit Manipulation Instruction Set 2
      INVPCID             # Invalidate Process-Context Identifier
      RTM                 # Restricted Transactional Memory
      MPX                 # Memory Protection Extensions
      AVX512F             # AVX512 Foundations
      AVX512DQ
      RDSEED              # RD seed
      ADX                 # Multi-Precision Add-Carry Instruction Extensions
      AVX512_IFMA
      CLFLUSHOPT          # Flush Cache Line Optimized
      CLWB                # CacheLine Writeback
      AVX512PF
      AVX512ER
      AVX512CD
      SHA                 # Secure-Hash Algorithm Extensions
      AVX512BW
      AVX512VL
      TSE                 # Time Stamp Counter Extension TSC
      PREFETCHWT1
      AVX512_VBMI
      UMIP
      PKU                 # Memory Protection Keys (PKEYs)
      WAITPKG
      AVX512_VBMI2
      CET_SS
      GFNI                # Galois Field New Instructions
      VAES                # Vector AES Instructions
      VPCLMULQDQ          # Carry-less Vector Multiplication (CLMUL). AVX-solo | AVX512F
      AVX512_VNNI
      AVX512_BITALG
      AVX512_VPOPCNTDQ
      SMAP                # Supervisor Mode Access Prevention
      RDPID               # Read Processor-ID
      KL                  # KEY-LOCKER
      CLDEMOTE            # Cacheline Demote
      MOVDIRI
      MOVDIR64B
      ENQCMD
      SGX_LC
      PKS
      AVX512_4VNNIW
      AVX512_4FMAPS
      UINTR               # User-Interrupt Return
      AVX512_VP2INTERSECT
      SERIALIZE
      TSXLDTRK            # Transactional Synchronization Extensions (TSX)
      PCONFIG
      CET_IBT
      AMX_BF16
      AVX512_FP16
      AMX_TILE
      AMX_INT8
      AVX_VNNI_INT8       #
      AVX_NE_CONVERT
      AMX_COMPLEX         # 
      AVX_VNNI_INT16      #
      PREFETCHITI         #
      AVX10
      APX_F 
      XSAVEOPT
      XSAVEC              # XSAVE-Compaction
      XGETBV
      XSAVES
      SGX1                # Software Guard Extension
      PTWRITE             # Processor-Trace Write >Gemini-Lake
      AESKLE              # AES Key-Locker Extension
      LZCNT               # leading-zeroes-count
      PREFETCHW
      XOP                 # eXtended Operations by AMD, see SSE & SSE5
      TBM                 # Trailing Bit Manipulation by AMD, see BMI1 & BMI2
      MONITORX
      SYSCALL
      RDTSCP              # read Time-Stamp-Counter
      X64                 # arch X64
      WBNOINVD            # Write Back and Do Not Invalidate Cache

  
  proc cpuid[T :SomeInteger](eaxIn :T, subLeaf :T = 0, initCall :bool = false ) :Leaf

  proc cpuBrandString*()  :string
  proc cpuVendorString*() :string

  var Leaf0*, Leaf8000* :Leaf

  type
    InstructionSetCheckInfo* = object
      leaf*, register*, bit*: int
      ecxInit* :int32 #= 0 # TODO breaks 1.6.10


  const checkInfos* = [
    InstructionSetCheckInfo( leaf: 1, register: 2, bit:  0 ), # SSE3
    InstructionSetCheckInfo( leaf: 1, register: 2, bit:  1 ), # PCLMULQDQ
    InstructionSetCheckInfo( leaf: 1, register: 2, bit:  3 ), # MONITOR
    InstructionSetCheckInfo( leaf: 1, register: 2, bit:  6 ), # SMX
    InstructionSetCheckInfo( leaf: 1, register: 2, bit:  9 ), # SSSE3
    InstructionSetCheckInfo( leaf: 1, register: 2, bit:  5 ), # VMX
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 12 ), # FMA
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 13 ), # CMPXCHG16B
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 19 ), # SSE4.1
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 20 ), # SSE4.2
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 20 ), # CRC32 -> avail. since SSE4.2, no seperate cpuId-check known.
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 22 ), # MOVBE
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 23 ), # POPCNT
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 24 ), # TSC_DEADLINE_TIMER
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 25 ), # AES a.k.a. AESNI, AES-NI
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 26 ), # XSAVE
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 27 ), # OSXSAVE
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 28 ), # AVX
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 29 ), # F16C
    InstructionSetCheckInfo( leaf: 1, register: 2, bit: 30 ), # RDRAND
    InstructionSetCheckInfo( leaf: 1, register: 3, bit:  4 ), # TSC
    InstructionSetCheckInfo( leaf: 1, register: 3, bit:  5 ), # MSR
    InstructionSetCheckInfo( leaf: 1, register: 3, bit:  7 ), # NONSTOP_TSC
    InstructionSetCheckInfo( leaf: 1, register: 3, bit: 11 ), # SEP
    InstructionSetCheckInfo( leaf: 1, register: 3, bit: 15 ), # CMOV
    InstructionSetCheckInfo( leaf: 1, register: 3, bit: 18 ), # PSN
    InstructionSetCheckInfo( leaf: 1, register: 3, bit: 19 ), # CLFSH CLFLUSH-instruction
    InstructionSetCheckInfo( leaf: 1, register: 3, bit: 23 ), # MMX
    InstructionSetCheckInfo( leaf: 1, register: 3, bit: 24 ), # FXSR
    InstructionSetCheckInfo( leaf: 1, register: 3, bit: 25 ), # SSE
    InstructionSetCheckInfo( leaf: 1, register: 3, bit: 26 ), # SSE2
    InstructionSetCheckInfo( leaf: 7, register: 0, bit:  0, ecxInit: 1'i32 ), # SHA512
    InstructionSetCheckInfo( leaf: 7, register: 0, bit:  1, ecxInit: 1'i32 ), # SM3
    InstructionSetCheckInfo( leaf: 7, register: 0, bit:  2, ecxInit: 1'i32 ), # SM4
    InstructionSetCheckInfo( leaf: 7, register: 0, bit:  3, ecxInit: 1'i32 ), # RAO_INT
    InstructionSetCheckInfo( leaf: 7, register: 0, bit:  4, ecxInit: 1'i32 ), # AVX_VNNI
    InstructionSetCheckInfo( leaf: 7, register: 0, bit:  5, ecxInit: 1'i32 ), # AVX512_BF16
    InstructionSetCheckInfo( leaf: 7, register: 0, bit:  7, ecxInit: 1'i32 ), # CMPCCXADD
    InstructionSetCheckInfo( leaf: 7, register: 0, bit: 19, ecxInit: 1'i32 ), # WRMSRNS
    InstructionSetCheckInfo( leaf: 7, register: 0, bit: 21, ecxInit: 1'i32 ), # AMX_FP16
    InstructionSetCheckInfo( leaf: 7, register: 0, bit: 22, ecxInit: 1'i32 ), # HRESET
    InstructionSetCheckInfo( leaf: 7, register: 0, bit: 23, ecxInit: 1'i32 ), # AVX_IFMA
    InstructionSetCheckInfo( leaf: 7, register: 0, bit: 26, ecxInit: 1'i32 ), # LAM
    InstructionSetCheckInfo( leaf: 7, register: 0, bit: 27, ecxInit: 1'i32 ), # MSRLIST
    InstructionSetCheckInfo( leaf: 7, register: 1, bit:  0 ), # FSGSBASE
    InstructionSetCheckInfo( leaf: 7, register: 1, bit:  1 ), # TSC_ADJUST
    InstructionSetCheckInfo( leaf: 7, register: 1, bit:  3 ), # BMI1
    InstructionSetCheckInfo( leaf: 7, register: 1, bit:  4 ), # HLE
    InstructionSetCheckInfo( leaf: 7, register: 1, bit:  5 ), # AVX2
    InstructionSetCheckInfo( leaf: 7, register: 1, bit:  8 ), # BMI2
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 10 ), # INVPCID
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 11 ), # RTM
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 14 ), # MPX
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 16 ), # AVX512F
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 17 ), # AVX512DQ
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 18 ), # RDSEED
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 19 ), # ADX
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 21 ), # AVX512_IFMA
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 23 ), # CLFLUSHOPT
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 24 ), # CLWB
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 26 ), # AVX512PF
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 27 ), # AVX512ER
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 28 ), # AVX512CD
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 29 ), # SHA
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 30 ), # AVX512BW
    InstructionSetCheckInfo( leaf: 7, register: 1, bit: 31 ), # AVX512VL

    InstructionSetCheckInfo( leaf: 7, register: 1, bit:  1, ecxInit: 1'i32 ), # TSE

    InstructionSetCheckInfo( leaf: 7, register: 2, bit:  0 ), # PREFETCHWT1
    InstructionSetCheckInfo( leaf: 7, register: 2, bit:  1 ), # AVX512_VBMI
    InstructionSetCheckInfo( leaf: 7, register: 2, bit:  2 ), # UMIP
    InstructionSetCheckInfo( leaf: 7, register: 2, bit:  3 ), # PKU
    InstructionSetCheckInfo( leaf: 7, register: 2, bit:  5 ), # WAITPKG
    InstructionSetCheckInfo( leaf: 7, register: 2, bit:  6 ), # AVX512_VBMI2
    InstructionSetCheckInfo( leaf: 7, register: 2, bit:  7 ), # CET_SS
    InstructionSetCheckInfo( leaf: 7, register: 2, bit:  8 ), # GFNI
    InstructionSetCheckInfo( leaf: 7, register: 2, bit:  9 ), # VAES
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 10 ), # VPCLMULQDQ
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 11 ), # AVX512_VNNI
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 12 ), # AVX512_BITALG
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 14 ), # AVX512_VPOPCNTDQ
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 20 ), # SMAP
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 22 ), # RDPID
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 23 ), # KL
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 25 ), # CLDEMOTE
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 27 ), # MOVDIRI
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 28 ), # MOVDIR64B
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 29 ), # ENQCMD
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 30 ), # SGX_LC
    InstructionSetCheckInfo( leaf: 7, register: 2, bit: 31 ), # PKS
    InstructionSetCheckInfo( leaf: 7, register: 3, bit:  2 ), # AVX512_4VNNIW
    InstructionSetCheckInfo( leaf: 7, register: 3, bit:  3 ), # AVX512_4FMAPS
    InstructionSetCheckInfo( leaf: 7, register: 3, bit:  5 ), # UINTR
    InstructionSetCheckInfo( leaf: 7, register: 3, bit:  8 ), # AVX512_VP2INTERSECT
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 14 ), # SERIALIZE
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 16 ), # TSXLDTRK
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 18 ), # PCONFIG
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 20 ), # CET_IBT
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 22 ), # AMX_BF16
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 23 ), # AVX512_FP16
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 24 ), # AMX_TILE
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 25 ), # AMX_INT8
    InstructionSetCheckInfo( leaf: 7, register: 3, bit:  4, ecxInit: 1'i32 ), # AVX_VNNI_INT8
    InstructionSetCheckInfo( leaf: 7, register: 3, bit:  5, ecxInit: 1'i32 ), # AVX_NE_CONVERT 
    InstructionSetCheckInfo( leaf: 7, register: 3, bit:  8, ecxInit: 1'i32 ), # AMX_COMPLEX
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 10, ecxInit: 1'i32 ), # AVX_VNNI_INT16
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 14, ecxInit: 1'i32 ), # PREFETCHITI
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 19, ecxInit: 1'i32 ), # AVX10
    InstructionSetCheckInfo( leaf: 7, register: 3, bit: 21, ecxInit: 1'i32 ), # APX_F

    InstructionSetCheckInfo( leaf: 13, register: 0, bit: 0, ecxInit: 1'i32 ), # XSAVEOPT
    InstructionSetCheckInfo( leaf: 13, register: 0, bit: 1, ecxInit: 1'i32 ), # XSAVEC
    InstructionSetCheckInfo( leaf: 13, register: 0, bit: 2, ecxInit: 1'i32 ), # XGETBV
    InstructionSetCheckInfo( leaf: 13, register: 0, bit: 3, ecxInit: 1'i32 ), # XSAVES

    InstructionSetCheckInfo( leaf: 12, register: 0, bit: 0 ), # SGX1 ?hex?
    InstructionSetCheckInfo( leaf: 14, register: 1, bit: 4 ), # PTWRITE ?hex?
    InstructionSetCheckInfo( leaf: 25, register: 1, bit: 0 ), # AESKLE ?hex?

    InstructionSetCheckInfo( leaf: (0x80000001'i32).int, register: 2, bit:  5 ), # LZCNT
    InstructionSetCheckInfo( leaf: (0x80000001'i32).int, register: 2, bit:  8 ), # PREFETCHW
    InstructionSetCheckInfo( leaf: (0x80000001'i32).int, register: 2, bit: 11 ), # XOP
    InstructionSetCheckInfo( leaf: (0x80000001'i32).int, register: 2, bit: 21 ), # TBM
    InstructionSetCheckInfo( leaf: (0x80000001'i32).int, register: 2, bit: 29 ), # MONITORX
    InstructionSetCheckInfo( leaf: (0x80000001'i32).int, register: 3, bit: 11 ), # SYSCALL
    InstructionSetCheckInfo( leaf: (0x80000001'i32).int, register: 3, bit: 27 ), # RDTSCP
    InstructionSetCheckInfo( leaf: (0x80000001'i32).int, register: 3, bit: 29 ), # X64 arch
    InstructionSetCheckInfo( leaf: (0x80000008'i32).int, register: 1, bit:  9 ), # WBNOINVD
  ]

  proc cpuid[T :SomeInteger](eaxIn :T, subLeaf :T = 0, initCall :bool = false ) :Leaf =
    let (a, c) = (eaxIn.int32, subLeaf.int32)

    when defined(vcc):

      proc cpuid(cpuInfo: ptr int32, functionId, subFunctionId: int32)
        {.cdecl, importc: "__cpuidex", header: "intrin.h".}
      cpuid(cast[ptr int32](result.addr), eaxi, ecxi)

    else :

      func asmCall( a,c :int32 ) : Leaf =
        var eax, ebx, ecx, edx :int32
        asm """
          cpuid
          :"=a"(`eax`), "=b"(`ebx`), "=c"(`ecx`), "=d"(`edx`)
          :"a"(`a`), "c"(`c`)"""
        [ eax,ebx,ecx,edx ].asLeaf

      if initCall :
        # assert (subLeaf == 0) and (eaxIn in [0, 0x8000_0000'i32 ]), "initCall ?"
        ( Leaf0, Leaf8000 ) = ( asmCall( 0,0 ), asmCall( 0x8000_0000'i32, 0 ) )
        # TODO : clear dynamic ApicID, always 0
        echo fmt"init max-{Leaf0.A} min-{Leaf8000.A}"
        return Leaf0

      if  ( eaxIn == 0 ) and (subLeaf == 0) : return Leaf0
      elif( eaxIn  > Leaf0.D ) : return
      elif( eaxIn == 0x8000_0000'i32 ) and ( subLeaf == 0 ) : return Leaf8000
      elif( eaxIn  < 0 ) and (eaxIn > Leaf8000.A ) : return
 
      debugEcho fmt"calling cpuid({eaxIn=} {subLeaf=}) is {initCall=}"
      return asmCall( a,c )


  proc checkInstructionSets*(instructionSets: set[InstructionSet]) :bool =
    result = true

    let (leaf1, leaf7) = (cpuid(1, 0), cpuid(7, 0))

    for instructionSet in instructionSets :
      let checkInfo = checkInfos[ instructionSet.ord ]
      if checkInfo.leaf == 1:
        if (leaf1[checkInfo.register.int32] and (1 shl checkInfo.bit)) == 0 :
          return false
      else:
        if (leaf7[checkInfo.register.int32] and (1 shl checkInfo.bit)) == 0 :
          return false


  proc checkInstructionSet*(iSet :InstructionSet) :bool =
    let
      rec  = checkInfos[ iSet.ord ] 
      # leaf = cpuid( rec.leaf.int32, 0 )
      leaf = cpuid( rec.leaf, subLeaf=rec.ecxInit )

    #echo "leaf-infos :: ", leaf, fmt" | b-bits {leaf[2]:.b}"
    # echo "leaf-infos :: ", leaf, fmt" | b-bits {leaf[ rec.register ]:.b}"
    result = ( leaf[ rec.register ] and ( 1 shl rec.bit ).int32 ) > 0


  proc cacheInfo*() :seq[ tuple[ 
      ct, mapping, inclusive :string, level, CL, cacheSizeKB :int, invalidates :bool 
      ] ] =
    # L2-CacheInfo in ECX
    # let 
    #   regsL2 = cpuid( 0x8000_0006'i32, subLeaf=0 )
    #   cl = ( regsL2[2].uint32 and 255'u32 ).int
    #   assoc = (( regsL2[2].uint32 shr 12 ) and 0x07'u32 ).int
    #   kbyte = ( regsL2[2].uint32 shr 16 ).int
    # return ( bytes, kbyte, assoc )
  
    let hasLeaf11 = cpuid(11).B != 0
    echo "maxLeaf is ", Leaf0.D, ". Is leaf-11 supported ? ", hasLeaf11
    echo "test 0_0 <- eBx != 0 ? ", cpuid(0).B != 0

    # unique ID for each logical-processor via leaf-11
    let resp0 = cpuid(11)
    # echo " eBx != 0 ? ", resp0.B != 0
    #echo 1.cpuid 0
    # CPUID.(EAX=11, ECX=n):EAX[4:0] 
    #echo "a,b,c,d ", resp0
    # echo " id ? ", resp0.A 4..0

    var logicalID = resp0.D # id from edx
    echo "got id : ", logicalID
     
    # ref https://software.intel.com/en-us/articles/intel-64-architecture-processor-topology-enumeration/
    # src SO https://stackoverflow.com/questions/14283171/how-to-receive-l1-l2-l3-cache-size-using-cpuid-instruction-in-x86
    # 
    var 
      leaf :Leaf
      turn :int32

    while( leaf = 4.cpuid( subLeaf=turn ); leaf.A != 0 ) :
      turn.inc
      let 
        cType      = ["none", "Data", "Instruction", "Unified"][ leaf.A 4..0 ]
        cNWay      = succ leaf.B 31..22
        cPart      = succ leaf.B 21..12
        cLine      = succ leaf.B 11..0 
        cLevel     =      leaf.A  7..5 

        cMapping   = [ "Direct", "Complex" ][ ord leaf.D.testBit 1 ] 
        cInclusive = [ "notInclusive", "isInclusive" ][ ord leaf.D.testBit 2 ] 

        cSize = cNWay * cPart * cLine * succ(leaf.C)

      #echo "   assoc L", cLevel, "  N-", cNWay, fmt"  {cLine=} {cSize=}"
      result.add ( cType, cMapping, cInclusive, cLevel, cLine, cSize, (not leaf.D.testBit 2) )


  proc cpuSignature*() : ( tuple[
      maxApicId, CLSize, cpuType,
      familyId, extFamilyId, brandIndex,
      model, extModelId, steppingId :int
    ], int ) = 
      let leaf = 1.cpuid subLeaf=0
      var info = result[ 0 ]
      info.extFamilyId = leaf.A 27..20
      info.extModelId  = leaf.A 19..16
      info.cpuType     = leaf.A 13..12
      info.familyId    = leaf.A 11..8 
      info.model       = leaf.A  7..4
      info.steppingId  = leaf.A  3..0

      info.brandIndex  = leaf.B  7..0

      if info.familyId in [ 6,15 ] :
        info.model += info.extModelId shl 4
        if info.familyId == 15 :
          info.familyId += info.extModelId

      if leaf.D.testBit 28 : # supports HyperThreading ?
        info.maxApicId = leaf.B 23..16

      if leaf.D.testBit 19 : # CLFlush ?
        info.CLSize = 8 * leaf.B 15..8

      ## dynamic ApicId (= responding thread/core)
      result[1] = leaf.B 31..24  # dynamic ! might change with every call !
      result[0] = info


  proc cpuBrandString*() :string =

    result.setLen 48
    let
      leaf2 = 0x8000_0002'i32.cpuid subLeaf=0
      leaf3 = 0x8000_0003'i32.cpuid subLeaf=0
      leaf4 = 0x8000_0004'i32.cpuid subLeaf=0

    copyMem( result[  0 ].unsafeAddr, leaf2.unsafeAddr, 16 )
    copyMem( result[ 16 ].unsafeAddr, leaf3.unsafeAddr, 16 )
    copyMem( result[ 32 ].unsafeAddr, leaf4.unsafeAddr, 16 )


  proc cpuVendorString*() :string =
    #
    # courtesy of https://stackoverflow.com/questions/21642347/cpu-id-using-c-windows
    #
    result.setLen 12

    let leaf0 = 0.cpuid subLeaf=0
    let ( subB, subD, subC ) = ( leaf0.B, leaf0.D, leaf0.C )
    copyMem( result[ 0 ].unsafeAddr, subB.unsafeAddr, 4 )
    copyMem( result[ 4 ].unsafeAddr, subD.unsafeAddr, 4 )
    copyMem( result[ 8 ].unsafeAddr, subC.unsafeAddr, 4 )

#[ 
  This inital request reads leaf-0/subLeaf-0 and leaf-0x8000_0000/subLeaf-0.
  Leaf-0 returns the number of the highest-leaf that carries information about this cpu.
  Leaf-0x8000_0000 provides the number of the lowest leaf.
  In addition to the limits, they contain the `cpuVendorString()`.
  As a 'hello-msg', the infos are loaded at module-import-time.
  Both results are kept in global vars `Leaf0` and `Leaf8000`.
]#
once : discard 0.cpuid( 0, initCall=true )
