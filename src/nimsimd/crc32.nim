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
  {.passc: "-msse4.2".}
]#

import sse42
export sse42

# {.push header: "nmintrin.h".}

# func mm_crc32_u8*(  crc :uint32, v :uint8 ) :uint32 {.importc: "_mm_crc32_u8" .}
# func mm_crc32_u16*( crc :uint32, v :uint16) :uint32 {.importc: "_mm_crc32_u16".}

# func mm_crc32_u32*( crc, v :uint32 ) :uint32 {.importc: "_mm_crc32_u32".}
# func mm_crc32_u64*( crc, v :uint64 ) :uint64 {.importc: "_mm_crc32_u64".}

# {.pop.}