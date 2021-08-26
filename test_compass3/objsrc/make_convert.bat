@echo off
REM cls && clang -std=c99 convert.c -o convert.exe && convert.exe
cls && tcc convert.c -o convert.exe && convert.exe
