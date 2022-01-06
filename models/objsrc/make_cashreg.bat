@echo off
bsp cashreg1.e cashreg1.bin -l0 -V -o -M0.173648 -es2 -N
bsp cashreg1a.e cashreg1a.bin -l0 -V -o -M0.173648 -es2 -N
bsp cashreg1b.e cashreg1b.bin -l0 -V -o -M0.173648
copy /y cashreg1.bin ..\obj\
copy /y cashreg1a.bin ..\obj\
copy /y cashreg1b.bin ..\obj\
copy /y cashreg.png ..\obj\txt16\
