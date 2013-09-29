#!/usr/bin/env python3
# coding: utf-8

import json

data = json.loads(open('data/sprites.lua').read())

code = 'local sprites = {\n'
code += '\timage="data/%s",\n' % data['meta']['image']

for s in data['frames']:
    code += "\t%s={x=%d,y=%d,w=%d,h=%d},\n" % \
        (s['filename'].replace('.png', ''), s['frame']['x'], s['frame']['y'],
         s['frame']['w'], s['frame']['h'])
code += '}'

code += """
sprites.perso_anim = {
	sprites.perso_null,
	sprites.perso_d_1,
	sprites.perso_d_2,
	sprites.perso_d_1,
	sprites.perso_null,
	sprites.perso_g_1,
	sprites.perso_g_2,
	sprites.perso_g_1,
}\n"""
code += 'return sprites'

open('data/sprites.lua', 'w').write(code)
