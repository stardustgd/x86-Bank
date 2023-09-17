#!/bin/bash

case $1 in
    clean)
    # Remove build files and executable
    rm -f bin/*
    rm -f build/*
    ;;

    *)

    JWASM=native/JWasm.exe
    JWASMFLAGS="/Zd /coff"

    JWLINK=native/JWlink.exe
    JWLINKFLAGS="format windows pe"
    LIBPATH="include/Irvine32"
    LIBRARY="LIBRARY $LIBPATH/Irvine32.lib LIBRARY $LIBPATH/Kernel32.lib LIBRARY $LIBPATH/User32.lib"

    BIN=bin
    BUILD=build
    TARGET=$BIN/x86Bank.exe

    SRCS="src/*.asm"
    OBJS="build/\*.obj"

    mkdir -p $BIN
    mkdir -p $BUILD

    wine $JWASM $JWASMFLAGS $SRCS
    mv *.obj $BUILD

    JWLINKPRM="$JWLINKFLAGS LIBPATH $LIBPATH $LIBRARY file $OBJS"

    wine $JWLINK $JWLINKPRM
    mv $BUILD/BankApp.exe $TARGET
    ;;
esac
