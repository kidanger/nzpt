local sprites = {
	image="data/spritesheet.png",
	balise={x=2,y=2,w=11,h=11},
	lightmap={x=15,y=2,w=258,h=258},
	ombre_null={x=275,y=2,w=32,h=32},
	parquet={x=309,y=2,w=52,h=52},
	perso_d_1={x=363,y=2,w=32,h=24},
	perso_d_2={x=397,y=2,w=32,h=24},
	perso_g_1={x=431,y=2,w=32,h=24},
	perso_g_2={x=465,y=2,w=32,h=24},
	perso_null={x=2,y=262,w=32,h=24},
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