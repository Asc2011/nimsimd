when NimVersion == "1.6.10" :
  let
    (dir, name) = splitPath( cwd )
    cpuidExe    = joinPath( dir ,"cpuid" )
    feature     = toUpperAscii name[0..^5]
else :
  let
    (dir,name, _) = Path( cwd ).splitFile
    cpuidExe      = dir / Path("cpuid")
    feature       = toUpperAscii $name

#echo "testing |" & cpuidExe & "|"

if fileExists( cpuidExe ) :
  let r = staticExec( $cpuidExe & " " & feature )
  if r == "false" :
    quit "CPU-Feature '" & feature & "' not supported by this host. quitting now.."
  else :
    echo "  cpuid :: detected cpu-feature '", feature, "'"