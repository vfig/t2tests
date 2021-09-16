@echo off
set cal=../mesh/burrick.cal
set map=../mesh/burrick.map
python bvh2mi.py burrheadbang.bvh %map% 7FFFF burrheadbang
