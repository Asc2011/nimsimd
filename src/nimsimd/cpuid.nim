import std/cmdline
from strutils import parseEnum
import nimsimd/runtimecheck 

template dbg( code :untyped ) :untyped =
  when defined(debug) :
    code

when isMainModule :
  let params = commandLineParams()
  for featureStr in params :
    try :
      let feat = { parseEnum[InstructionSet]( featureStr ) }
      if checkInstructionSets feat : 
        dbg: echo "  ", featureStr, " ..ok"
        continue
      else :
        dbg: echo "  ", featureStr, " ..failed"
        quit "false"
    except ValueError :
      dbg: echo "given feature '", featureStr, "' does not exist ?"
      quit "false"

  quit "true"


