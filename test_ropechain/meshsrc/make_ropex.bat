@echo off
meshbld.exe -V ropex.e ropex.bin ropechn.map -mropechn.mjo
copy /Y ropex.bin ..\mesh\
copy /Y ropex.cal ..\mesh\
