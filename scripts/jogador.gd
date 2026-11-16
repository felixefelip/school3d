extends CharacterBody3D
## Jogadora em terceira pessoa.
## WASD: andar | Shift: correr | Mouse: girar a câmera
## Botão direito do mouse (ou Tab): capturar/soltar o mouse | Esc: soltar

## Velocidade de caminhada (m/s). 1.05 é o passo medido na animação "Andar",
## então os pés não deslizam no chão.
@export var velocidade: float = 1.05
## Correr acelera o deslocamento e a animação na mesma proporção.
@export var multiplicador_corrida: float = 1.8
@export var sensibilidade_mouse: float = 0.003
## Quão rápido a personagem vira para a direção do movimento.
@export var velocidade_giro: float = 10.0
## Tempo de transição entre parada e andando (s).
@export var tempo_transicao: float = 0.2

@onready var modelo: Node3D = $Modelo
@onready var esqueleto: Skeleton3D = $Modelo/Skeleton3D
@onready var animacao: AnimationPlayer = $Modelo/AnimationPlayer
@onready var pivo_camera: Node3D = $PivoCamera
@onready var braco_camera: SpringArm3D = $PivoCamera/BracoCamera

var _gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	_usar_cores_dos_vertices()
	animacao.get_animation("Andar").loop_mode = Animation.LOOP_LINEAR
	_criar_animacao_parada()
	animacao.play("Parada")
	braco_camera.add_excluded_object(get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## As cores da personagem estão nos vértices da malha, mas o importador não
## liga essa opção nos materiais dela (na escola liga). Sem isso ela fica branca.
func _usar_cores_dos_vertices() -> void:
	for malha: MeshInstance3D in esqueleto.find_children("*", "MeshInstance3D", true, false):
		for i in malha.mesh.get_surface_count():
			var material := malha.mesh.surface_get_material(i) as StandardMaterial3D
			if material:
				material.vertex_color_use_as_albedo = true


## O modelo só tem a animação "Andar". Para ficar parada, criamos uma animação
## com a pose de descanso do esqueleto, assim dá para fazer a transição suave.
func _criar_animacao_parada() -> void:
	var andar := animacao.get_animation("Andar")
	var parada := Animation.new()
	for i in andar.get_track_count():
		var caminho := andar.track_get_path(i)
		var osso := esqueleto.find_bone(caminho.get_concatenated_subnames())
		if osso < 0:
			continue
		var descanso := esqueleto.get_bone_rest(osso)
		var tipo := andar.track_get_type(i)
		var faixa := parada.add_track(tipo)
		parada.track_set_path(faixa, caminho)
		match tipo:
			Animation.TYPE_POSITION_3D:
				parada.position_track_insert_key(faixa, 0.0, descanso.origin)
			Animation.TYPE_ROTATION_3D:
				parada.rotation_track_insert_key(faixa, 0.0, descanso.basis.get_rotation_quaternion())
			Animation.TYPE_SCALE_3D:
				parada.scale_track_insert_key(faixa, 0.0, descanso.basis.get_scale())
	animacao.get_animation_library("").add_animation("Parada", parada)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pivo_camera.rotation.y -= event.relative.x * sensibilidade_mouse
		pivo_camera.rotation.x = clamp(pivo_camera.rotation.x - event.relative.y * sensibilidade_mouse, -1.2, 0.4)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_alternar_mouse()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.physical_keycode == KEY_TAB:
			_alternar_mouse()


func _alternar_mouse() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravidade * delta

	var entrada := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		entrada.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		entrada.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		entrada.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		entrada.x += 1.0

	# Direção relativa à câmera, sem a inclinação vertical.
	var direcao := pivo_camera.global_basis * Vector3(entrada.x, 0.0, entrada.y)
	direcao.y = 0.0
	direcao = direcao.normalized()

	if direcao != Vector3.ZERO:
		var correndo := Input.is_physical_key_pressed(KEY_SHIFT)
		var escala := multiplicador_corrida if correndo else 1.0
		velocity.x = direcao.x * velocidade * escala
		velocity.z = direcao.z * velocidade * escala
		# O modelo olha para +Z.
		modelo.rotation.y = lerp_angle(modelo.rotation.y, atan2(direcao.x, direcao.z), velocidade_giro * delta)
		if animacao.current_animation != "Andar":
			animacao.play("Andar", tempo_transicao)
		animacao.speed_scale = escala
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if animacao.current_animation != "Parada":
			animacao.speed_scale = 1.0
			animacao.play("Parada", tempo_transicao)

	move_and_slide()
