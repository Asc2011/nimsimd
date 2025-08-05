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
  {.passc: "-maes".}
]#

import sse2
export sse2

{.push header: "wmmintrin.h".}

func mm_aesdec_si128*(          a, roundKey :M128i )         :M128i {.importc: "_mm_aesdec_si128".}
func mm_aesdeclast_si128*(      a, roundKey :M128i )         :M128i {.importc: "_mm_aesdeclast_si128".}
func mm_aesenc_si128*(          a, roundKey :M128i )         :M128i {.importc: "_mm_aesenc_si128".}
func mm_aesenclast_si128*(      a, roundKey :M128i )         :M128i {.importc: "_mm_aesenclast_si128".}
func mm_aesimc_si128*(          a :M128i )                   :M128i {.importc: "_mm_aesimc_si128".}
func mm_aeskeygenassist_si128*( a :M128i, imm8 :static int ) :M128i {.importc: "_mm_aeskeygenassist_si128".}

{.pop.}
