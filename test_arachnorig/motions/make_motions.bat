@echo off
set cal=../mesh/spidalb.cal
set map=../mesh/spidey.map
python bvh2mi.py xxxxxx.bvh %map% 1FFFFFFF xxxxxx
