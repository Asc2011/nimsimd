# https://stackoverflow.com/questions/13772567/how-to-get-the-cpu-cycle-count-in-x86-64-from-c/51907627#51907627

# MSVC might need "intrin.h", Linux maybe "X86intrin.h" ?

{.push header: "immintrin.h".}

func rdtscp*( aux :ptr uint64 ) :uint64 {.importc: "__rdtscp".}

{.pop.}