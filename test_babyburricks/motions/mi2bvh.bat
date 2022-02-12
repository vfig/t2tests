@echo off
if "%~1"=="" goto usage
if "%~2"=="" goto makefilename
set OUTPUT="%~2"
goto run

:usage
echo "mi2bvh input.mi [output.bvh]"
exit /B 1

:makefilename
set OUTPUT="%~dpn1.bvh"

:run
python mi2bvh.py %1 burrick.cal burrick.map %OUTPUT%
