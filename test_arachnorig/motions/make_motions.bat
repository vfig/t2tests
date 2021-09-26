@echo off
set cal=../mesh/face.cal
set map=../mesh/spidey.map
python bvh2mi.py facelook.bvh %map% 1FFFFFFF facelook
