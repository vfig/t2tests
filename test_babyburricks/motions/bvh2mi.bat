@echo off
if "%~1"=="" goto usage
if "%~2"=="" goto makefilename
set OUTPUT="%~2"
goto run

:usage
echo "bvh2mi input.bvh [output.mi]"
exit /B 1

:makefilename
set OUTPUT="%~dpn1.mi"

:run
python bvh2mi.py %1 burrick.map 7FFFF %OUTPUT%
