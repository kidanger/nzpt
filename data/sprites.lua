local sprites = {
	image="data/spritesheet.png",
	lightmap={x=2,y=2,w=258,h=258},
	parquet={x=262,y=2,w=52,h=52},
	perso_d_1={x=316,y=2,w=32,h=24},
	perso_d_2={x=350,y=2,w=32,h=24},
	perso_g_1={x=384,y=2,w=32,h=24},
	perso_g_2={x=418,y=2,w=32,h=24},
	perso_null={x=452,y=2,w=32,h=24},
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