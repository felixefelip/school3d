extends Node3D
## Gera colisão para o cenário ao iniciar, para a jogadora não atravessar
## paredes, móveis e o chão. O modelo glTF não traz colisão própria.
##
## Pisos viram uma caixa lisa: a malha deles tem milhares de triângulos (as
## tábuas) e uma colisão copiada dela empurra a personagem de forma errada.
## O resto usa um invólucro convexo, mais leve que copiar todos os triângulos.

const CENARIO := ["Escola", "ParedeFundoSala", "DecoracaoSala", "Teto"]


func _ready() -> void:
	for nome in CENARIO:
		var no := get_node(nome)
		var malhas := no.find_children("*", "MeshInstance3D", true, false)
		if no is MeshInstance3D:
			malhas.append(no)
		for malha: MeshInstance3D in malhas:
			if malha.name.begins_with("Piso"):
				_criar_caixa(malha)
			else:
				malha.create_convex_collision(true, false)


func _criar_caixa(malha: MeshInstance3D) -> void:
	var limites := malha.global_transform * malha.get_aabb()
	var forma := BoxShape3D.new()
	forma.size = limites.size
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	var corpo := StaticBody3D.new()
	corpo.name = malha.name + "_col"
	corpo.add_child(colisao)
	add_child(corpo)
	corpo.global_position = limites.get_center()
