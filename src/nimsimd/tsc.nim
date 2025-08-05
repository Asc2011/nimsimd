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
]#


when hostOS == "macosx" and hostCPU == "amd64" :
  {.push header: "x86intrin.h".}
else :
  {.push header: "immintrin.h".} 


func rdtsc*() :int64 {.importc: "_rdtsc".}

{.pop.}

