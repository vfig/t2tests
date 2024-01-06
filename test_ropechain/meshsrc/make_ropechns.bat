@echo off
meshbld.exe -V ropechns.e ropechns.bin ropechn.map -mropechn.mjo
copy /Y ropechns.bin ..\mesh\
copy /Y ropechns.cal ..\mesh\
copy /Y ropechns.tga ..\mesh\txt16\
