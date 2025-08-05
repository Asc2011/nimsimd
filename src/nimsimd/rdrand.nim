#[
from std/strutils import toUpperAscii

when NimVersion == "1.6.10" :
  from std/os import fileExists, splitPath, joinPath
else :
  from std/files import fileExists
  import std/paths

when defined( debug ):
  static:
    let cwd = currentSourcePath()
    include ./testFeature.inc

when defined( gcc ) or defined( clang ):
  {.passc: "-mrdrnd".}
]#

{.push header: "immintrin.h".}

func rdrand16_step*( val :ptr uint16 ) :int32 {.importc: "_rdrand16_step".}
func rdrand32_step*( val :ptr uint32 ) :int32 {.importc: "_rdrand32_step".}
func rdrand64_step*( val :ptr uint64 ) :int32 {.importc: "_rdrand64_step".}

{.pop.}