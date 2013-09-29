#!/usr/bin/env python2

import math
import Image

img = Image.new('RGBA', (256, 256))

def gauss(x, y):
    d = math.sqrt((x - 128) ** 2 + (y - 128) ** 2) / 90
    return math.exp(- d*d*d*d)

for x in range(256):
    for y in range(256):
        p = gauss(x, y)
        img.putpixel((x, y), (int(p*255),) * 4)

img.save('datasrc/lightmap.png')
