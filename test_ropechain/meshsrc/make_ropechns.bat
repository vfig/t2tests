@echo off
meshbld.exe -V ropechns8.e ropechns8.bin ropechn.map -mropechn.mjo
meshbld.exe -V ropechns16.e ropechns16.bin ropechn.map -mropechn.mjo
meshbld.exe -V ropechns24.e ropechns24.bin ropechn.map -mropechn.mjo
meshbld.exe -V ropechns32.e ropechns32.bin ropechn.map -mropechn.mjo

meshbld.exe -V ropechnm8.e ropechnm8.bin ropechn.map -mropechn.mjo
meshbld.exe -V ropechnm16.e ropechnm16.bin ropechn.map -mropechn.mjo
meshbld.exe -V ropechnm24.e ropechnm24.bin ropechn.map -mropechn.mjo
meshbld.exe -V ropechnm32.e ropechnm32.bin ropechn.map -mropechn.mjo

meshbld.exe -V ropechnl8.e ropechnl8.bin ropechn.map -mropechn.mjo
meshbld.exe -V ropechnl16.e ropechnl16.bin ropechn.map -mropechn.mjo
meshbld.exe -V ropechnl24.e ropechnl24.bin ropechn.map -mropechn.mjo
meshbld.exe -V ropechnl32.e ropechnl32.bin ropechn.map -mropechn.mjo

copy /Y ropechns8.bin ..\mesh\
copy /Y ropechns8.cal ..\mesh\
copy /Y ropechns16.bin ..\mesh\
copy /Y ropechns16.cal ..\mesh\
copy /Y ropechns24.bin ..\mesh\
copy /Y ropechns24.cal ..\mesh\
copy /Y ropechns32.bin ..\mesh\
copy /Y ropechns32.cal ..\mesh\

copy /Y ropechnm8.bin ..\mesh\
copy /Y ropechnm8.cal ..\mesh\
copy /Y ropechnm16.bin ..\mesh\
copy /Y ropechnm16.cal ..\mesh\
copy /Y ropechnm24.bin ..\mesh\
copy /Y ropechnm24.cal ..\mesh\
copy /Y ropechnm32.bin ..\mesh\
copy /Y ropechnm32.cal ..\mesh\

copy /Y ropechnl8.bin ..\mesh\
copy /Y ropechnl8.cal ..\mesh\
copy /Y ropechnl16.bin ..\mesh\
copy /Y ropechnl16.cal ..\mesh\
copy /Y ropechnl24.bin ..\mesh\
copy /Y ropechnl24.cal ..\mesh\
copy /Y ropechnl32.bin ..\mesh\
copy /Y ropechnl32.cal ..\mesh\

copy /Y ropechns.tga ..\mesh\txt16\
copy /Y ropechns.mtl ..\mesh\txt16\
