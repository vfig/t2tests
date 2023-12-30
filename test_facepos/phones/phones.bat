@echo off
REM Uses Rhubarb 1.13.0 from https://github.com/DanielSWolf/rhubarb-lip-sync
REM try:  -r phonetic 
REM try:  -f json
REM try:  -d sg11101a.txt
REM try:  --extendedShapes GHX
REM  or:  --extendedshapes ""
REM try:  -o sg11101a.tsv
REM  or:  -o sg11101a.json
REM try:  -q
.\rhubarb\rhubarb.exe x_sg11101a.wav -f json -o sg11101a.json
