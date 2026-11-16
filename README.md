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
- **Botão direito ou Tab**: capturar/soltar o mouse
- **Esc**: soltar o mouse

## Estrutura

- `models/escola_completa.gltf` + `escola_completa_0.bin` / `escola_completa_1.bin`: o modelo
  (mesmo conteúdo do `.glb` original, apenas separado em glTF + binários).
- `scenes/main.tscn`: cena principal com a escola, teto, luminárias, decoração, luz do sol, céu e a jogadora.
- `scenes/player.tscn` + `scripts/player.gd`: a jogadora (`models/characters/estudante_morena_andando.glb`)
  em terceira pessoa, com a animação "Andar".
- `scripts/main.gd`: gera a colisão do cenário ao iniciar.
- `scripts/free_camera.gd`: câmera livre (não usada na cena atual).
