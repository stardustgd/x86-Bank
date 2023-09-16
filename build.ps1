# (Windows Only)
# This script uses the JWasm and JWlink binaries in native/

param (
    [string]$param1
)

if ($param1 -eq "clean") {
    echo "rm -f bin\*"
    rm -Force bin/*
    
    echo "rm -f build\*"
    rm -Force build/*
    Exit
}

$JWASM = "native\JWasm"
$JWASMFLAGS = "/Zd /coff" 

$JWLINK = "native\JWlink"
$JWLINKFLAGS = "format windows pe"
$LIBPATH = "include\Irvine"
$LIBRARY = "$LIBPATH\Irvine32.lib",
           "$LIBPATH\Kernel32.lib",
           "$LIBPATH\User32.lib"

$BIN = "bin"
$BUILD = "build"
$TARGET = "$BIN\x86Bank.exe"

$SRCS = "src\*.asm"
$OBJS = "build\*.obj"

if (!(Test-Path $BUILD)) {
    mkdir $BUILD
}

if (!(Test-Path $BIN)) {
    mkdir $BIN
}

foreach ($lib in $LIBRARY) {
    $LIBCOMPLETE += "LIBRARY " + $lib + " "
}

$JWASMPRM = $JWASMFLAGS, $SRCS

& $JWASM $JWASMPRM
mv -Force *.obj build

# Create the JWlink command (it needs to be all in one line)
$JWLINKPRM = $JWLINKFLAGS + " LIBPATH " + $LIBPATH + " " + $LIBCOMPLETE + " file " + $OBJS
$JWLINKCMD = $JWLINK + " " + $JWLINKPRM

Invoke-Expression $JWLINKCMD

mv -Force $BUILD\BankApp.exe $TARGET