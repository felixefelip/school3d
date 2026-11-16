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
- **Esc**: soltar o mouse

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
- `scripts/free_camera.gd`: câmera livre (não usada na cena atual).
