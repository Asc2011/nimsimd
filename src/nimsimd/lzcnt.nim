#[
when defined( gcc ) or defined( clang ):
  {.passc: "-mlzcnt".}
]#

{.push header: "immintrin.h".}

func lzcnt_u32*(a :uint32) :int32 {.importc: "_lzcnt_u32".}

{.pop.}
