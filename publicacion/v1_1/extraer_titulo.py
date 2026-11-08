#!/usr/bin/env python3
"""Extrae de la cinta v1.1 la imagen real de título, sin pintar elementos nuevos."""
from pathlib import Path
import argparse, struct, hashlib, functools
from PIL import Image

PALETTE=[
    (0,0,0),(0,0,205),(205,0,0),(205,0,205),(0,205,0),(0,205,205),(205,205,0),(205,205,205),
    (0,0,0),(0,0,255),(255,0,0),(255,0,255),(0,255,0),(0,255,255),(255,255,0),(255,255,255)
]
SHA_V11='9105d9679319aae0f4de445142276c1bfe7c65df36993e6f86ad87ddfa03dac1'

def extract(tap):
    assert hashlib.sha256(tap).hexdigest()==SHA_V11, 'Solo se permite el TAP v1.1 oficial'
    i=0;blocks=[]
    while i<len(tap):
        n=struct.unpack_from('<H',tap,i)[0];i+=2
        b=tap[i:i+n];i+=n
        assert n>=2 and len(b)==n and functools.reduce(lambda a,v:a^v,b,0)==0
        blocks.append(b)
    assert i==len(tap) and len(blocks)==6
    scr=blocks[3][1:-1]
    assert len(scr)==6912
    return scr

def render(scr):
    pic=Image.new('RGB',(256,192))
    px=pic.load()
    for y in range(192):
        for x in range(256):
            cx=x//8; cy=y//8
            a=scr[6144+cy*32+cx]
            ink=(a&7)+(8 if a&64 else 0)
            paper=((a>>3)&7)+(8 if a&64 else 0)
            addr=((y&0xc0)<<5)|((y&7)<<8)|((y&0x38)<<2)|cx
            px[x,y]=PALETTE[ink if scr[addr]&(1<<(7-(x%8))) else paper]
    return pic.resize((768,576), Image.Resampling.NEAREST)

if __name__=='__main__':
    a=argparse.ArgumentParser()
    a.add_argument('tap',type=Path);a.add_argument('png',type=Path)
    p=a.parse_args()
    p.png.parent.mkdir(parents=True, exist_ok=True)
    render(extract(p.tap.read_bytes())).save(p.png)
    print('Captura de título real generada:',p.png)
