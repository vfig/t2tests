@echo off
bsp compass3.e compass3.bin -l0 -V -A1
copy /y compass3.bin ..\obj\
copy /y cstar1.png ..\obj\txt\
copy /y cstar2.png ..\obj\txt\
copy /y ceye.png ..\obj\txt\
