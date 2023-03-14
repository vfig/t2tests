from math import *

g_fNoiseTimer = 0.0;

def frac(f):
    return modf(f)[0]

def dot(ax, ay, bx, by):
    return ax*bx + ay*by

def rsqrt(f):
    return 1.0/sqrt(f);

def sign(f):
    return copysign(1.0, f)

def NoiseRand(nx, ny):
    return frac(sin(dot(nx, ny, 12.9898, 78.233))*43758.5453)

def GenNoise(posx, posy):
    n = NoiseRand(posx + g_fNoiseTimer * 0.01, posy + g_fNoiseTimer * 0.01)
    f = n * 2.0 - 1.0
    n = rsqrt(abs(f)) * f
    n = max(-1.0, n)
    n = n - sign(f)
    return n * (1.0/128.0)

def main():
    i = 0.0
    while (i<16.0):
        noise = GenNoise(i, i)
        print(f"{i}: {noise}")
        i += 1.0

main()
