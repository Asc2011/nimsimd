/*
  normalized version-info for GCC, Clang, MSC(VCC), TinyC and ARM
  via CPredef-Prj see https://github.com/cpredef/predef/blob/master/VersionNormalization.md
  more if needed for eg. Oracle, ICC etc.
    https://github.com/cpredef/predef/blob/master/Compilers.md
  !Only! tested with clang.12.0.1.macosx llvm=true
*/


/* Version is int32 = 0x VV RR PPPP */

#define PREDEF_VERSION(v,r,p) (((v) << 24) + ((r) << 16) + (p))


/* q&d - test values

#define __CC_ARM 1
#define __ARMCC_VERSION 321999

#define __tinyc__ 1

#define __MINGW64__ 1
#define __MINGW64_MAJOR_VERSION 6
#define __MINGW64_MINOR_VERSION 4

#define __MINGW32__ 1
#define __MINGW32_MAJOR_VERSION 3
#define __MINGW32_MINOR_VERSION 2

#define _MSC_FULL_VER 3021111
*/


/* Test for LLVM */

#if defined(__llvm__)
const int isLLVM = 1;
#else
const int isLLVM = 0;
#endif


/* Normalize ARM version, __ARMCC_VERSION-format =  V R P BBB */

#if defined(__CC_ARM)
# define PREDEF_COMPILER_ARM PREDEF_VERSION( __ARMCC_VERSION / 100000, __ARMCC_VERSION % 100000 / 10000, __ARMCC_VERSION % 10000 / 1000 )
#endif


/* Normalize GCC version */

#if defined(__GNUC__)
# if defined(__GNUC_PATCHLEVEL__)
#  define PREDEF_COMPILER_GNUC PREDEF_VERSION(__GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__)
# else
#  define PREDEF_COMPILER_GNUC PREDEF_VERSION(__GNUC__, __GNUC_MINOR__, 0)
# endif
#endif


/* Normalize Visual C++ version  VV RR PPPP */

#if defined(_MSC_FULL_VER)
# define PREDEF_COMPILER_MSC PREDEF_VERSION(_MSC_FULL_VER / 1000000, (_MSC_FULL_VER % 1000000) / 10000, _MSC_FULL_VER % 10000)
#else
# if defined(_MSC_VER)
#  define PREDEF_COMPILER_MSC CDETECT_MKVER(_MSC_VER / 100, _MSC_VER % 100, 0)
# endif
#endif


/* Normalize Clang version */

#if defined(__clang__)
# if defined(__clang_patchlevel__)
#  define PREDEF_COMPILER_CLANG PREDEF_VERSION(__clang_major__, __clang_minor__, __clang_patchlevel__)
# else
#  define PREDEF_COMPILER_CLANG PREDEF_VERSION(__clang__, __clang_minor__, 0)
# endif
#endif


/* Normalize MingW64 and MingW32 version(s) 
  The patchlevel signalizes :
  - MingW64 compiles 32bit -> 6432
  - MingW64 compiles 64bit -> 6464
  - MingW32 compiles 32bit ->   32
*/
#if defined(__MINGW64__) && defined(__MINGW32__)
# define PREDEF_COMPILER_MINGW64 PREDEF_VERSION( __MINGW32_MAJOR_VERSION, __MINGW32_MINOR_VERSION, 6432 )
#elif defined(__MINGW64__)
# define PREDEF_COMPILER_MINGW64 PREDEF_VERSION( __MINGW64_MAJOR_VERSION, __MINGW64_MINOR_VERSION, 6464 )
#elif defined( __MINGW32__ )
# define PREDEF_COMPILER_MINGW32 PREDEF_VERSION( __MINGW32_MAJOR_VERSION, __MINGW32_MINOR_VERSION, 32 )
#endif


/* Normalize Tiny-C version -> set to 0.0.0 */

#if defined(__tinyc__)
# define PREDEF_COMPILER_TINYC PREDEF_VERSION( 0,0,0 )
#endif


typedef struct {
   int 		versionI;
   int    isLLVM;
   char 	ident[8];
} CompilerVI ;

#if defined(PREDEF_COMPILER_CLANG)
const CompilerVI vi = { PREDEF_COMPILER_CLANG,   isLLVM, "clang"};
#elif defined(PREDEF_COMPILER_ARM)
const CompilerVI vi = { PREDEF_COMPILER_ARM,     isLLVM, "armcc"};
#elif defined(PREDEF_COMPILER_GCC)
const CompilerVI vi = { PREDEF_COMPILER_GCC,     isLLVM, "gcc"};
#elif defined(PREDEF_COMPILER_MSC)
const CompilerVI vi = { PREDEF_COMPILER_MSC,     isLLVM, "msc"};
#elif defined(PREDEF_COMPILER_MINGW32)
const CompilerVI vi = { PREDEF_COMPILER_MINGW32, isLLVM, "mingw32"};
#elif defined(PREDEF_COMPILER_MINGW64)
const CompilerVI vi = { PREDEF_COMPILER_MINGW64, isLLVM, "mingw64"};
#elif defined(PREDEF_COMPILER_TINYC)
const CompilerVI vi = { PREDEF_COMPILER_TINYC,   isLLVM, "tinyc"};
#else
const CompilerVI vi = { 			           	  0,   isLLVM, "unknown"} ;
#endif

