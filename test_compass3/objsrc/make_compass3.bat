@echo off
bsp compass3.e compass3.bin -N -l0 -V
copy /y compass3.bin ..\obj\
copy /y cstar1.png ..\obj\txt\
copy /y cstar2.png ..\obj\txt\
copy /y ceye.png ..\obj\txt\
