{.passC: "-I ./../whichCompiler.h".}

type 
  CompilerVI* {.header: "../whichCompiler.h".} = object
    versionI*   :int32     ## bits 31..24 major, 23..16 minor, 15..0 patch-level
    isLLVM*     :int32     ## int32/cBool => 1 or 0
    ident*      :cstring   ## char[8]

static:
  echo "Major-", NimMajor, " Minor-", NimMinor

var vi {.importc: "vi", nodecl.} :CompilerVI 

when (NimMajor, NimMinor) < (1,3) :
  template typeMasked[ T :SomeInteger](x :T) :T = x
  func bitsliced*[T :SomeInteger](v :T; slice :Slice[int]) :T =
    let
      upmost = sizeof(T) * 8 - 1
      uv     = v.uint32
    ((uv shl (upmost - slice.b)).typeMasked shr (upmost - slice.b + slice.a)).T
else :
  from std/bitops import bitSliced

#from std/bitops import testBit, BitsRange, setBit

proc version*() :tuple[ name, os :string; major, minor, patch :int; isLLVM :bool ] = 
  (
    name   : $vi.ident,
    os     : hostOS,
    major  : int( vi.versionI.bitSliced 24..31 ),
    minor  : int( vi.versionI.bitSliced 16..23 ),
    patch  : int( vi.versionI.bitSliced  0..15 ),
    isLLVM : vi.isLLVM != 0
  )


when isMainModule:
  echo "ct.nim:main ", version()
