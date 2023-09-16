# (Windows Only)
# This script also assumes that you have the MASM Runner extension
# installed in VSCode as it uses its JWASM and JWlink executables.
param (
    [string]$param1
)

if ($param1 -eq "clean") {
    echo "rm -f bin/*"
    rm -Force bin/*
    
    echo "rm -f build/*"
    rm -Force build/*
    Exit
}

$MASMRUNNER = "$HOME\.vscode\extensions\istareatscreens.masm-runner-0.4.5\native\"

$JWASM = "$MASMRUNNER\JWASM\JWASM.EXE"
$JWASMFLAGS = "/Zd /coff" 

$JWLINK= "$MASMRUNNER\JWLINK\JWlink.exe"
$JWLINKFLAGS = "format windows pe"
$LIBPATH = "include"
$LIBRARY = "$LIBPATH\Irvine32.lib",
           "$LIBPATH\Kernel32.lib",
           "$LIBPATH\User32.lib"

$BIN = "bin"
$BUILD = "build"
$TARGET = "$BIN\x86Bank.exe"

if (!(Test-Path $BUILD)) {
    mkdir $BUILD
}

if (!(Test-Path $BIN)) {
    mkdir $BIN
}

foreach ($lib in $LIBRARY) {
    $LIBCOMPLETE += "LIBRARY " + $lib + " "
}

$JWASMPRM = $JWASMFLAGS, "src\BankApp.asm", "src\BankUtils.asm", "src\DatabaseUtils.asm"

& $JWASM $JWASMPRM
mv -Force *.obj build

# Create the JWlink command (it needs to be all in one line)
$JWLINKPRM = $JWLINKFLAGS + " LIBPATH " + $LIBPATH + " " + $LIBCOMPLETE + " file build\BankApp.obj file build\BankUtils.obj file build\DatabaseUtils.obj"
$JWLINKCMD = $JWLINK + " " + $JWLINKPRM

Invoke-Expression $JWLINKCMD

mv -Force $BUILD/BankApp.exe $TARGET