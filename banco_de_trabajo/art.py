"""Create actual ZX Spectrum 48K bitmaps (6912 bytes) and native 24x32 sprites.
All artwork is purpose-drawn; no external graphics.
"""
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
from collections import Counter
P=Path(__file__).parent
COLORS=[(0,0,0),(0,0,205),(205,0,0),(205,0,205),(0,205,0),(0,205,205),(205,205,0),(205,205,205),
        (0,0,0),(0,0,255),(255,0,0),(255,0,255),(0,255,0),(0,255,255),(255,255,0),(255,255,255)]
fontpath='/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf'
mono='/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf'

def canvas(w=256,h=192):
 im=Image.new('P',(w,h),0); im.putpalette([v for c in COLORS for v in c]+[0,0,0]*240);return im,ImageDraw.Draw(im)

def txt(d,xy,msg,fill=14,sz=10,center=False,font=fontpath):
 f=ImageFont.truetype(font,sz)
 x,y=xy
 if center:
  bbox=d.textbbox((0,0),msg,font=f)
  x-=int((bbox[2]-bbox[0])/2)
 d.text((x,y),msg,font=f,fill=fill,stroke_width=0)

def panel(d,x0,y0,x1,y1,c0=10,c1=14):
 d.rectangle((x0,y0,x1,y1),outline=c1)
 d.rectangle((x0+2,y0+2,x1-2,y1-2),outline=c0)

LANES=[16,64,112,160,208]  # sprites left x: 16,64,112,160,208
CENTERS=[x+12 for x in LANES]

def stars(d,seed=4,top=65,bottom=164):
 import random
 rr=random.Random(seed)
 for _ in range(30):
  x=rr.randrange(15,242);y=rr.randrange(top,bottom)
  if any(abs(x-c)<19 for c in CENTERS):continue
  c=[9,11,12,13,14,15][rr.randrange(6)]
  d.point((x,y),fill=c)
  if rr.random()<0.25:d.line((x-1,y,x+1,y),fill=c)

def octo_draw(d,x,y,s=1):
 # head with forehead and brow, eyes and six tentacles
 def ellipse(a,b,c,e,fill,outline=None):d.ellipse((x+a*s,y+b*s,x+c*s,y+e*s),fill=fill,outline=outline)
 def line(points,fill,width=1):d.line([(x+a*s,y+b*s) for a,b in points],fill=fill,width=width*s)
 ellipse(3,3,20,18,13)
 ellipse(5,1,18,13,11)
 ellipse(7,3,9,5,15);ellipse(14,3,16,5,15)
 ellipse(5,10,10,14,0);ellipse(13,10,18,14,0)
 ellipse(7,11,8,12,15);ellipse(15,11,16,12,15)
 line([(4,15),(2,19),(1,24),(4,26),(6,23)],13,2)
 line([(7,18),(5,23),(8,27),(7,29)],11,2)
 line([(10,19),(9,25),(12,28)],13,2)
 line([(14,19),(16,25),(13,29)],11,2)
 line([(17,18),(21,24),(18,27)],13,2)
 line([(20,15),(23,19),(22,24),(19,25)],11,2)


def tamer_draw(d,x,y,s=1):
 def R(a,b,c,e,fill):d.rectangle((x+a*s,y+b*s,x+c*s,y+e*s),fill=fill)
 def E(a,b,c,e,fill):d.ellipse((x+a*s,y+b*s,x+c*s,y+e*s),fill=fill)
 def L(p,fill,w=1):d.line([(x+a*s,y+b*s) for a,b in p],fill=fill,width=w*s)
 # top hat: a recognizable ringmaster with brim, white band
 R(7,1,17,6,9);R(6,6,18,8,15);R(8,4,16,4,14)
 # face + big red moustache
 R(9,9,16,14,14);R(10,11,11,11,0);R(15,11,15,11,0)
 L([(10,14),(12,13),(14,13),(16,14)],10,1)
 # hair / shoulder
 R(8,15,18,17,15)
 # coat blue outline then red body
 R(5,18,20,26,9);R(7,18,18,27,10)
 R(10,18,13,26,15);R(12,19,13,25,14)
 R(3,19,6,24,10);R(19,19,22,23,10)
 # whip hand raised on the right
 R(21,18,23,20,14);L([(22,18),(22,15)],15,1)
 # pants + boots
 R(8,27,11,30,14);R(15,27,18,30,14)
 R(6,30,11,31,9);R(15,30,21,31,9)

def portal(d,x,y):
 # x is center, y top. Portal 32x20, pixel & color deliberate
 d.ellipse((x-14,y+1,x+14,y+21),outline=11,width=2)
 d.ellipse((x-11,y+3,x+11,y+19),outline=13,width=2)
 d.ellipse((x-8,y+5,x+8,y+17),outline=9,width=2)
 d.ellipse((x-5,y+7,x+5,y+15),fill=1)
 d.line((x-1,y+7,x+1,y+15),fill=14,width=1)
 d.point((x+13,y+3),fill=15);d.point((x-12,y+17),fill=14)

def tent(d):
 # roof and bright pennants, structural beams. Keeps enemies area black.
 d.rectangle((0,0,255,1),fill=14)
 for x in range(0,256,16):
  d.rectangle((x,0,x+7,2),fill=10 if (x//16)%2 else 14)
 d.polygon([(0,49),(128,20),(255,49)],fill=10)
 for i in range(0,256,24):
  xc=i+12; tip=max(22,49-int(27*(1-abs(xc-128)/128)))
  d.polygon([(i,49),(min(i+16,255),49),(min(i+20,255),tip)],fill=14 if (i//24)%2==0 else 9)
 d.line([(0,49),(128,19),(255,49)],fill=15,width=2)
 d.line((0,50,255,50),fill=14,width=2)
 for x in range(8,253,16):
  d.ellipse((x-2,49,x+2,54),fill=14)
 for x in range(0,13,4):
  d.line((x,55,x,168),fill=10 if x%8==0 else 11,width=2)
 for x in range(244,256,4):
  d.line((x,55,x,168),fill=10 if x%8==0 else 11,width=2)
 d.line((11,56,11,168),fill=14,width=1);d.line((244,56,244,168),fill=14,width=1)
 for y in range(65,165,16):
  d.ellipse((5,y,8,y+3),fill=14); d.ellipse((248,y,251,y+3),fill=14)

def stage(d):
 # Lower ring: preserve the action plane and the domador's last sprite row.
 d.line((11,169,244,169),fill=14,width=2)
 d.line((12,172,244,172),fill=10,width=2)
 # Two framed, double-outline panels: white numerals + red heart icons.
 d.rectangle((0,175,255,191),fill=1)
 d.line((0,175,255,175),fill=14,width=1)
 d.line((0,191,255,191),fill=14,width=1)
 for xa,xb in ((4,148),(152,251)):
  d.rectangle((xa,175,xb,190),outline=14,width=1)
  d.line((xa+2,177,xa+2,188),fill=10)
  d.line((xb-2,177,xb-2,188),fill=10)
 # Separating stars are decorative but remain OUTSIDE the dynamic 16px glyphs.
 d.point((150,177),fill=15)
 d.point((150,189),fill=15)


def game_screen():
 im,d=canvas()
 tent(d)
 # central banner hides part of roof and gives readable title
 d.rectangle((28,4,229,23),fill=0,outline=14,width=1)
 txt(d,(128,5),'CIRCO DIMENSIONAL',14,16,True)
 stars(d,top=73,bottom=160)
 for x in CENTERS:portal(d,x,54)
 # pentagonal ropes and miniature bulb ornaments (between lanes)
 for x in [52,100,148,196]:
  d.line((x,75,x,164),fill=1)
  for y in (84,124,157):d.point((x,y),fill=14)
 stage(d)
 # clean classic 1985 score panel: score to left, lives to right.
 # Letter/heart color domains fall on separate Spectrum attribute cells.
 txt(d,(13,178),'PUNTOS',15,10)
 txt(d,(159,178),'VIDAS',15,10)
 return im

def title_screen():
 im,d=canvas();tent(d)
 # Cabecera y enfrentamiento originales, sin alterar los sprites del juego.
 d.rectangle((17,4,239,44),fill=0,outline=14,width=2)
 txt(d,(128,4),'EL CIRCO',14,21,True)
 txt(d,(128,24),'DIMENSIONAL',13,19,True)
 d.line((24,47,231,47),fill=11,width=2)
 d.line((128,62,128,140),fill=14,width=2)
 tamer_draw(d,27,79,2)
 octo_draw(d,183,80,2)
 d.ellipse((119,67,136,81),outline=15,width=2)
 d.line((124,85,131,136),fill=14,width=2)
 # Banda inferior: informacion en tres alturas independientes de atributos.
 # El credito queda DENTRO de los 192 pixeles y no pisa los controles.
 d.rectangle((21,143,234,191),fill=0)
 d.line((24,144,231,144),fill=14)
 txt(d,(128,147),'PULSA ESPACIO PARA JUGAR',15,11,True)
 d.line((33,161,223,161),fill=14)
 txt(d,(128,163),'O/P MOVER   ESPACIO LATIGO',13,9,True)
 d.line((49,179,207,179),fill=14)
 txt(d,(128,181),'2026 Tony C. Ware',14,9,True)
 return im

def over_screen():
 im,d=canvas();tent(d)
 d.rectangle((17,4,239,46),fill=0,outline=10,width=2)
 txt(d,(128,7),'FIN DE FUNCION',14,20,True)
 txt(d,(128,30),'LOS PULPOS HAN ESCAPADO',15,11,True)
 octo_draw(d,105,57,2)
 d.ellipse((72,50,184,140),outline=11,width=2)
 d.ellipse((83,58,174,133),outline=13,width=1)
 txt(d,(104,143),'PUNTOS:',14,9,False)
 d.rectangle((16,158,239,174),fill=1,outline=14)
 txt(d,(128,158),'ESPACIO: VOLVER AL CIRCO',14,11,True)
 txt(d,(128,180),'PREPARATE PARA OTRA FUNCION',13,10,True)
 return im

def player_sprite():
 im,d=canvas(24,32);tamer_draw(d,0,0);return im

def enemy_sprite():
 im,d=canvas(24,32);octo_draw(d,0,0);return im

def enemy_sprite_alt():
 im,d=canvas(24,32);octo_draw(d,0,0)
 # second frame, eight lively tentacles, deliberately different silhouettes
 d.rectangle((0,19,23,31),fill=0)
 for pts,color in [([(5,18),(3,21),(4,25),(1,27)],13),
                   ([(8,18),(6,23),(7,27),(5,30)],11),
                   ([(11,19),(9,24),(12,29)],13),
                   ([(14,18),(16,24),(14,30)],11),
                   ([(17,18),(19,22),(17,26),(20,29)],13),
                   ([(19,17),(22,20),(21,24),(23,26)],11)]:
  d.line(pts,fill=color,width=2)
 return im

def player_sprite_fire():
 im,d=canvas(24,32);tamer_draw(d,0,0)
 # raised mechanical whip-handle and a spark just above the glove
 d.rectangle((19,12,23,23),fill=0)
 d.line([(18,20),(21,16),(22,12)],fill=10,width=3)
 d.line([(21,12),(21,9)],fill=14,width=2)
 d.point((21,8),fill=15)
 return im

def sparkle_sprite():
 im,d=canvas(24,32)
 d.line((12,2,12,29),fill=14,width=2)
 d.line((2,15,21,15),fill=15,width=2)
 d.line((5,6,19,24),fill=14,width=2)
 d.line((19,6,5,24),fill=14,width=2)
 d.ellipse((9,12,15,18),fill=15)
 return im

def pack_screen(im):
 assert im.size==(256,192)
 buf=bytearray(6912)
 pix=im.load()
 for ry in range(24):
  for cx in range(32):
   colors=[pix[cx*8+dx,ry*8+dy] for dy in range(8) for dx in range(8)]
   counts=Counter(colors)
   common=counts.most_common(2)
   if len(common)==1:
    paper=0 if common[0][0] else 0; ink=common[0][0]
   else:
    # choose black paper when available, keep foreground ink
    if 0 in counts:
     paper=0
     others={c:n for c,n in counts.items() if c!=0}
     ink=max(others,key=others.get) if others else 7
    else:
     paper=common[0][0];ink=common[1][0]
   if (ink&7)==(paper&7):
    paper=0
   bright=int(bool(ink&8 or paper&8))
   attr=(bright<<6)|((paper&7)<<3)|(ink&7)
   buf[6144+ry*32+cx]=attr
   for dy in range(8):
    y=ry*8+dy
    off=((y&0xC0)<<5)|((y&7)<<8)|((y&0x38)<<2)|cx
    v=0
    for dx in range(8):
     c=pix[cx*8+dx,y]
     if c==ink or (c!=paper and c!=0 and ink!=0):v|=1<<(7-dx)
    buf[off]=v
 return bytes(buf)

def pack_sprite(im):
 assert im.size==(24,32)
 pix=im.load(); bits=bytearray()
 for yy in range(32):
  for xx in range(0,24,8):
   b=0
   for dx in range(8):
    if pix[xx+dx,yy]:b|=1<<(7-dx)
   bits.append(b)
 attrs=bytearray()
 for yy in range(0,32,8):
  for xx in range(0,24,8):
   colors=[pix[xx+dx,yy+dy] for dy in range(8) for dx in range(8)]
   count=Counter([c for c in colors if c])
   ink=count.most_common(1)[0][0] if count else 15
   attrs.append(0x40|(ink&7))
 assert len(bits)==96 and len(attrs)==12
 return bytes(bits+attrs)

def render_screen(data):
 # Decode the true 48K screen bytes to RGB; no preview-only fake assets.
 assert len(data)==6912
 o=Image.new('RGB',(256,192));px=o.load()
 for y in range(192):
  for x in range(256):
   cx=x//8;cy=y//8;attr=data[6144+cy*32+cx]
   ink=(attr&7)+(8 if attr&0x40 else 0)
   paper=((attr>>3)&7)+(8 if attr&0x40 else 0)
   off=((y&0xc0)<<5)|((y&7)<<8)|((y&0x38)<<2)|cx
   idx=ink if data[off]&(1<<(7-(x%8))) else paper
   px[x,y]=COLORS[idx]
 return o

SCREENS={}
for name,fun in [('title',title_screen),('game',game_screen),('over',over_screen)]:
 im=fun();buf=pack_screen(im);SCREENS[name]=buf
 (P/f'{name}.scr').write_bytes(buf)
 render_screen(buf).resize((768,576),Image.Resampling.NEAREST).save(P/f'{name}_pixel.png')
SPRITES={}
for name,fun in [('tamer',player_sprite),('tamer_fire',player_sprite_fire),('octopus',enemy_sprite),('octopus_alt',enemy_sprite_alt),('spark',sparkle_sprite)]:
 b=pack_sprite(fun());SPRITES[name]=b;(P/f'{name}.spr').write_bytes(b)
print('screens',len(SCREENS),'sprites',len(SPRITES))
