@echo off
meshbld.exe -V ropechn.e ropechn.bin ropechn.map -mropechn.mjo
copy /Y ropechn.bin ..\mesh\
copy /Y ropechn.cal ..\mesh\
copy /Y rails.dds ..\mesh\txt16\
