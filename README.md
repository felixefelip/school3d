# Escola (Godot 4)

Projeto Godot 4 com a cena `scenes/main.tscn`, que instancia o modelo da escola
(sala de aula, corredor, banheiro e refeitório).

## Como abrir

1. Abra o Godot 4 e clique em **Importar**.
2. Selecione o arquivo `project.godot` desta pasta.
3. Aguarde a importação do modelo e pressione **F5** para rodar.

## Controles

- **WASD**: mover
- **Q / E**: descer / subir
- **Shift**: correr
- **Mouse**: olhar
- **Botão direito ou Tab**: capturar/soltar o mouse
- **Esc**: soltar o mouse

## Estrutura

- `models/escola_completa.gltf` + `escola_completa_0.bin` / `escola_completa_1.bin`: o modelo
  (mesmo conteúdo do `.glb` original, apenas separado em glTF + binários).
- `scenes/main.tscn`: cena principal com a escola, luz do sol, céu e câmera.
- `scripts/free_camera.gd`: câmera livre.
