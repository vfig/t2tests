@echo off
set cal=../mesh/burrick.cal
set map=../mesh/burrick.map
python bvh2mi.py burrheadbang.bvh %map% 7FFFF burrheadbang
python bvh2mi.py bk111011s.bvh %map% 7FFFF bk111011s
python bvh2mi.py bk111012s.bvh %map% 7FFFF bk111012s
