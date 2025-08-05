{.experimental: "dotOperators".}
from std/strformat import fmt
from std/unicode   import reversed, toLower
from std/strutils  import join, split
from std/bitops    import testBit, BitsRange, bitSliced, setBit

#[
  Tested to work from 1.6.XX up to 2.3.1/devel 2025/8.
]#

when NimMajor >= 2 :
  proc unsafeAddr[T]( o :T ) :ptr T = o.addr

const 
  fp :bool = when defined(debug) :true else :false
  NL = '\n'

  CommonLabel = [               # pick one or all :))       
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

# (1) Leaf.<register-label> returns one i32 from slot 0..3.
#
template `.`*( leaf :Leaf, field :untyped ) :int32 = 
  let (label, idx) = getIdx astToStr field
  if idx == -1 : errorMsg( instantiationInfo( fullPaths=fp ), label )
  leaf[ idx mod 4 ]

# (1a) Leaf.<register-label> = Int -> puts a int32 into slot 0..3
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

when isMainModule :
  echo "nimsimd/src/nimsimd/leaf.nim :: main"

  var leaf = [ 0x800_0000, 11, 99999, 3453453 ].asLeaf
  assert leaf.ecx == 99999'i32 and leaf.R3 == 99999'i32
  echo leaf
  
  leaf.reset
  assert leaf.A==0 and leaf.B==0 and leaf.C==0 and leaf.D==0 #, "Smth went wrong ? "
  assert 0 == leaf.A 31..0
  assert ( leaf.Citron 0..31 ) == ( leaf.Citron 31..0 )
  assert 0 == leaf.D 0..31

  try :
    discard leaf.A 0..32  # throws, should not compile line-40 or line-96 ?
    assert false
  except RangeDefect : discard 

  leaf = [ 11,2,3,4 ].asLeaf
  echo "[ 11,2,3,4 ]", leaf
  assert leaf.r1==11 and leaf.r2==2 and leaf.r3==3 and leaf.r4==4 #, "Smth went wrong ? "

  leaf.Banana = 19
  echo "[ 11,19,3,4 ]", leaf
  assert leaf.a==11 and leaf.banana==19 and leaf.c==3 and leaf.d==4 #, "Smth. went wrong ?"

  let maskArr = [1,2,3]; let mask = [1,2,3].toMask
  echo leaf

  assert (leaf.Eax maskArr)  == leaf.Eax [1,2,3]
  assert (leaf.Eax and mask) == leaf.Eax [1,2,3]

  assert (leaf.A 1..3) == leaf[0].bitSliced 1..3
  assert  10 == leaf.eax [1,3]
  assert  on == leaf.eax 3
  assert  on == leaf.eax 0
  leaf.A = 0
  assert off == leaf.eax 0
  assert off == leaf.eax 3