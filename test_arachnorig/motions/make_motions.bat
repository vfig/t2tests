@echo off
set cal=../mesh/spidalb2.cal
set map=../mesh/spidey.map
python bvh2mi.py bstotalbs.bvh %map% 1FFFFFFF bstotalbs
