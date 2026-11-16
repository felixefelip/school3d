# Escola (Godot 4)

Projeto Godot 4 com a cena `scenes/main.tscn`, que instancia o modelo da escola
(sala de aula, corredor, banheiro e refeitório).

## Como abrir

1. Abra o Godot 4 e clique em **Importar**.
2. Selecione o arquivo `project.godot` desta pasta.
3. Aguarde a importação do modelo e pressione **F5** para rodar.

## Controles

- **WASD**: andar (relativo à câmera)
- **Shift**: correr
- **Mouse**: girar a câmera em volta da personagem
- **E**: interagir com o que estiver mais perto: abrir/fechar portas (sala, banheiro e as duas folhas
  do refeitório) e sentar/levantar nas cadeiras da sala (carteiras e cadeira do professor)
- **Botão direito ou Tab**: capturar/soltar o mouse
- **Esc**: soltar o mouse; **Esc de novo** (com o mouse já solto): fechar o jogo

## Estrutura

- `models/school.gltf` + `school_0.bin` / `school_1.bin`: o modelo
  (mesmo conteúdo do `.glb` original, apenas separado em glTF + binários).
- `scenes/main.tscn`: cena principal com a escola, teto, luminárias, decoração, luz do sol, céu e a jogadora.
- `scenes/player.tscn` + `scripts/player.gd`: a jogadora (`models/characters/brunette_student_walking.glb`)
  em terceira pessoa, com a animação "Walk".
- `scripts/main.gd`: gera a colisão do cenário ao iniciar.
- `scripts/door.gd`: porta que abre e fecha com E, sempre para o mesmo lado (sinal de `open_angle_degrees`).
  As portas ficam no nó `Doors` da cena principal.
- `scripts/seats.gd` + `scripts/seat.gd`: tornam as cadeiras da sala interativas; a animação de sentar
  ("Sit") e a pose parada ("Idle") são geradas em `scripts/student_animations.gd` (poses em `SIT_POSES`),
  compartilhado pela jogadora e pelas colegas.
- `scenes/npc_student.tscn` + `scripts/npc_student.gd`: estudante ruiva (`models/characters/redhead_student_walking.glb`)
  parada ou sentada numa cadeira (`chair_path`). Ficam no nó `Students` da cena principal.
  `scenes/npc_student_brunette.tscn` é a mesma colega com o modelo da morena (o mesmo da jogadora).
  `npc_student_blonde.tscn` e `npc_student_bluehair.tscn` usam o modelo da ruiva com o cabelo recolorido
  (`models/characters/blonde_student_walking.glb` e `bluehair_student_walking.glb`).
  `npc_student_boy.tscn` usa o estudante (`models/characters/boy_student_walking.glb`, editado a partir de
  `estudante_menino_andando.glb`: cabelo preto, gravata listrada, calça mais justa e com o cós mais baixo).
  `npc_student_blond_boy.tscn` é o mesmo estudante com cabelo loiro escuro (`blond_boy_student_walking.glb`).
- `scenes/bedroom.tscn` + `scripts/bedroom.gd`: o quarto da jogadora (cama, criado-mudo com abajur,
  guarda-roupa, escrivaninha com notebook e cadeira sentável, estante, tapete, janela e decoração).
  Para abrir, selecione a cena no editor e pressione **F6** (a cena principal continua sendo a escola).
- `scripts/free_camera.gd`: câmera livre (não usada na cena atual).
