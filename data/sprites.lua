local sprites = {
	image="data/spritesheet.png",
	lightmap={x=2,y=2,w=258,h=258},
	perso_d_1={x=262,y=2,w=32,h=24},
	perso_d_2={x=296,y=2,w=32,h=24},
	perso_g_1={x=330,y=2,w=32,h=24},
	perso_g_2={x=364,y=2,w=32,h=24},
	perso_null={x=398,y=2,w=32,h=24},
}
sprites.perso_anim = {
	sprites.perso_null,
	sprites.perso_d_1,
	sprites.perso_d_2,
	sprites.perso_d_1,
	sprites.perso_null,
	sprites.perso_g_1,
	sprites.perso_g_2,
	sprites.perso_g_1,
}
return sprites