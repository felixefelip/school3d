# Escola (Godot 4)

Projeto Godot 4 com a cena `scenes/main.tscn`, que instancia o modelo da escola
(sala de aula, corredor, banheiro e refeitório).

## Como abrir

1. Abra o Godot 4 e clique em **Importar**.
2. Selecione o arquivo `project.godot` desta pasta.
3. Aguarde a importação do modelo e pressione **F5** para rodar.

## Controles

- **WASD**: andar (relativo à câmera)
- **Shift**: correr (andando ~1,9 m/s; correndo ~3,4 m/s)
- **Mouse**: girar a câmera em volta da personagem
- **E**: interagir com o que estiver mais perto: abrir/fechar portas (sala, banheiro e as duas folhas
  do refeitório) e sentar/levantar nas cadeiras da sala (carteiras e cadeira do professor)
- **Botão direito ou Tab**: capturar/soltar o mouse
- **1–0 / roda do mouse**: escolher o slot da barra de itens
- **C**: menu de roupa (vestir e tirar roupas)
- **Esc**: menu de pausa (o jogo para): **Resume**, **Outfit** (menu de roupa), **Relationships** (lista de
  amizades) e **Quit game**; **Esc** de novo volta ao jogo. Com uma janela aberta (guarda-roupa, roupa), **Esc** fecha a janela

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
- `scenes/house.tscn` + `scripts/house.gd`: o apartamento da jogadora (um andar só, no 5º andar de um prédio):
  - quarto (cama, criado-mudo com abajur, guarda-roupa, escrivaninha com notebook e cadeira sentável,
    estante, tapete, janela, ar-condicionado split com controle remoto, violão e decoração), com a
    porta abrindo com E;
  - corredor com passadeira, aparador e quadros, ligando os quartos, o banheiro e a área de serviço à sala;
  - quarto dos pais (cama de casal, criados-mudos, guarda-roupa, cômoda com espelho, ar-condicionado),
    porta abrindo com E;
  - banheiro (porta abrindo com E): vaso, papel higiênico, lixeira, pia de coluna com espelho e
    prateleira, box de vidro com chuveiro, toalheiro com toalha, máquina de lavar com prateleira de
    sabão e amaciante, tapete e janela alta;
  - cozinha americana (bancada com pia, cooktop e cafeteira, forno, armários, geladeira, aparador com
    micro-ondas, air fryer e liquidificador, balcão com banquetas) integrada à sala (sofá, TV, ar-condicionado, mesa de centro, mesinha de jantar, estante) e
    porta de entrada, que com **E** leva para a rua (`scenes/street.tscn`);
  - varanda com guarda-corpo de vidro, mesinha, cadeiras e plantas, com vista para a rua principal: a cidade
    em volta é a mesma da rua (`scenes/city.tscn`), vista do 5º andar do Residencial Aurora;
  - área de serviço com tanque, varal e produtos de limpeza.
  Para abrir, selecione a cena no editor e pressione **F6** (a cena principal continua sendo a escola).
- Inventário (estilo Stardew Valley):
  - `scripts/inventory/item.gd` (`Item`): um item, com nome, ícone e descrição. As roupas ficam em
    `items/clothes/*.tres` e os ícones em `assets/icons/clothes/`.
  - `scripts/inventory/inventory.gd` (`Inventory`): um conjunto de slots.
  - `scripts/inventory/player_inventory.gd`: autoload `PlayerInventory`, com os 10 slots da jogadora
    (continuam com ela ao trocar de cena).
  - `scripts/ui/`: barra de itens (`hotbar.gd`), slot com arrastar e soltar (`inventory_slot.gd`),
    janela de armazenamento (`storage_window.gd`), dica do item (`item_tooltip.gd`) e estilos (`ui_style.gd`).
  - Uniforme: a jogadora começa vestindo **School shirt**, **School skirt** e **School shoes**, que também
    são itens (dá para tirar e guardar pelo menu C). Com o slot vazio ela fica de **top e short brancos**
    (`models/clothes/top.glb` e `shorts.glb`) e descalça (`bare_feet.glb`: o corpo do modelo termina
    no tornozelo, então os pés descalços são um modelo à parte, feito a partir do formato do sapato).
  - Roupas: cada peça tem um slot (cabeça, tronco, pernas, pés) e fica **suja** depois de 3 minutos
    vestida (manchas no ícone). Roupa suja não pode ser vestida: lave na **máquina de lavar** do banheiro
    (E, arraste a roupa e aperte **Wash**).
  - `scripts/inventory/outfit.gd` (`Outfit`): mostra a roupa vestida na personagem (blusa e tênis
    recoloridos, calça jeans no lugar da saia, boné na cabeça). A calça é `models/clothes/jeans.glb`,
    tirada do modelo do estudante (mesmo esqueleto); o boné é `models/clothes/cap.tscn`.
  - `scripts/ui/outfit_window.gd`: o menu de roupa (C), com prévia 3D girando e os quatro slots.
  - `scripts/washing_machine.gd`: a máquina de lavar (armazenamento com o botão Wash).
- `scenes/street.tscn` + `scripts/street.gd`: o bairro em volta do prédio (os prédios, ruas, carros e objetos
  ficam em `scenes/city.tscn`, que o apartamento também usa para a vista das janelas), com três ruas:
  - **rua principal** (leste–oeste): de um lado o prédio da jogadora (Residencial Aurora, com a porta do
    saguão), uma farmácia e uma padaria; do outro, o restaurante Bella Cucina (mesas com guarda-sol), a
    Cafe Aroma (mesinhas e cavalete com o cardápio) e um mini mercado. Depois do cruzamento, uma livraria
    e uma sorveteria;
  - **rua nova** (norte–sul), cruzando a principal na ponta leste, com ponto de ônibus;
  - **rua 3** (leste–oeste), um quarteirão ao sul: papelaria e prédios de um lado, casas com quintal do outro;
  - **escola**, na esquina da rua nova com a rua 3 (lado leste): muro com grade, pátio com árvores, bancos,
    mastro e quadra, prédio de três andares e o portão virado para a rua nova. Com **E** no portão, a
    jogadora entra na escola (`scenes/main.tscn`); a porta **EXIT** no fim do corredor da escola leva de
    volta para a frente do portão.
  É uma cidade grande: os prédios têm de 9 a 42 andares (alguns com fachada de vidro), letreiros verticais
  em neon, caixas-d'água, antenas e painéis nos terraços, e cada rua termina num prédio, fechando o mapa.
  Os cruzamentos têm faixas de pedestres nos quatro lados e semáforos. Há carros estacionados, postes,
  árvores, bancos, lixeiras, hidrantes, caixa de correio e bicicletários. Por enquanto só a Cafe Aroma
  tem interior (os outros estabelecimentos são só fachada). `street.gd` gera a colisão; as rampas invisíveis do meio-fio (para subir e descer da
  calçada) ficam no nó `CurbRamps`, e paredes invisíveis (`Boundaries`) fecham as pontas das ruas.
- `scenes/cafe.tscn` + `scripts/cafe.gd`: o interior da Cafe Aroma (entra com **E** pela porta da cafeteria
  na rua). Balcão de mármore com vitrine de doces, caixa, máquina de espresso, moedor e cardápio de giz;
  prateleiras com pacotes de café; mesinhas na janela, uma mesa comprida, um cantinho com sofá, poltronas,
  luminária e estante; luminárias pendentes, quadros, relógio, letreiro "aroma" em neon e porta do banheiro.
  A sala fica no mesmo lugar do prédio na cidade (`city.tscn`), então pelas vitrines se vê a rua de verdade.
  As cadeiras livres são sentáveis (**E**), há cinco colegas sentados tomando café, e no balcão
  (`scripts/cafe_counter.gd`) **E** pede um café, que vai para a barra de itens.
- Relacionamentos: dois clientes da cafeteria, **Bia** (na mesinha da janela) e **Lucas** (na mesa comprida),
  têm nome sobre a cabeça e dá para conversar com eles (**E**). Com a roupa toda limpa, eles são simpáticos e a
  amizade sobe 1 ponto; com qualquer peça suja, eles reclamam e a amizade cai 1 ponto (não fica abaixo de 0).
  Cada pessoa fala uma coisa só por dia (a primeira conversa do dia escolhe a fala, e conversar de novo
  repete a mesma) e só muda os pontos nessa primeira conversa. A fala aparece
  numa caixa acima da barra de itens, com "+1 friendship" ou "-1 friendship" na primeira conversa do dia.
  - `scripts/relationships.gd`: autoload `Relationships`, com os pontos de cada NPC (continuam ao trocar de cena).
  - `scripts/npc_student.gd`: com `npc_name` preenchido, o NPC vira relacionável (`friendly_lines` e
    `rude_lines` são as falas).
  - `scripts/ui/dialogue_box.gd`: a caixa de diálogo.
  - `scripts/ui/relationships_window.gd` + `heart_row.gd`: a lista de relacionamentos do menu de pausa, com
    todos que dá para conhecer (`Relationships.PEOPLE`), o rosto (renderizado do modelo do personagem em
    `scripts/ui/portrait.gd`; quem ainda não foi conhecido aparece como silhueta), o nível de amizade (Stranger, Acquaintance, Friend,
    Good friend, Best friend), onde encontrar a pessoa, os corações (até 10) e os pontos.
- Horário e calendário (como no Stardew Valley), autoload `GameClock` (`scripts/game_clock.gd`):
  - o dia começa às 6:00 am e o relógio anda de 10 em 10 minutos, a cada 7 segundos (um dia dura uns 15
    minutos); para enquanto o jogo está pausado. O relógio no canto superior direito
    (`scripts/ui/clock_panel.gd`) mostra o dia da semana, a data, a estação e o ano, e a hora;
  - o calendário tem 4 estações (Spring, Summer, Fall, Winter) de 28 dias e semanas de 7 dias;
  - na cama do quarto, **E** (**Go to sleep**) dorme a qualquer hora e acaba o dia; se ainda estiver acordada
    às 3:00 am, ela desmaia onde estiver. Nos dois casos ela acorda ao lado da cama no dia seguinte, às
    6:00 am (`scripts/bed.gd`, ponto `Bedside` no apartamento);
  - a luz do sol, do céu e o ambiente de cada cena acompanham a hora: amanhece das 6:00 às 7:30 e
    escurece das 5:00 às 8:00 pm.
- `scripts/ui/pause_menu.gd`: o menu de pausa (**Esc**), que pausa a árvore de cenas enquanto está aberto.
- `scripts/scene_door.gd`: porta que troca de cena (escurece a tela, carrega a outra cena e coloca a
  jogadora no ponto `target_spawn`, um nó em `SpawnPoints`). Liga a porta de entrada do apartamento à rua,
  a porta do saguão de volta ao apartamento, o portão da escola à escola e a saída da escola à rua.
- `scripts/coffee_maker.gd`: a cafeteira da cozinha. Com **E** ela começa a passar o café: uma barra de
  progresso horizontal aparece sobre ela, a luz acende em vermelho e a jarra enche. Pronto, a luz fica
  verde e **E** de novo pega uma
  xícara de café (`items/food/coffee.tres`) para a barra de itens.
- Geladeira (`FridgeStorage` na casa, mesmo script do guarda-roupa): com **E** abre com leite, ovos, maçã,
  banana, laranja, queijo, iogurte e suco de laranja (`items/food/`), que são arrastados para a barra.
  - `scripts/storage.gd`: móvel que guarda itens. Na casa, o guarda-roupa (`WardrobeStorage`) começa com
    camiseta, calça jeans, moletom, pijama, tênis e boné; com **E** a janela abre e os itens são
    arrastados com o mouse entre ela e a barra.
- `scripts/free_camera.gd`: câmera livre (não usada na cena atual).

## Testes automatizados

Os testes usam o [GdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) (v6.2.3, em `addons/gdUnit4`) e
ficam em `tests/`:

- `tests/logic/`: lógica sem cena — inventário (`add`, `move`), inventário da jogadora (uniforme inicial,
  slot selecionado, roupa suja depois de 3 minutos), itens de `items/` (id, nome e ícone preenchidos, ids
  únicos) e máquina de lavar.
- `tests/scenes/`: integridade das cenas — todo `NodePath` dos scripts aponta para um nó que existe, e toda
  porta que troca de cena leva a uma cena e a um ponto de chegada (`SpawnPoints`) que existem, com uma
  porta de volta.
- `tests/gameplay/`: jogabilidade com física — a jogadora começa no chão em cada cena, chega no ponto
  certo ao passar por cada porta, sobe e desce o meio-fio, não atravessa o muro da escola nem as pontas
  das ruas, e anda/corre nas velocidades configuradas.

Para rodar tudo sem abrir janela (informe o executável do Godot em `GODOT_BIN`):

```bash
GODOT_BIN=/caminho/para/godot ./run_tests.sh
```

O resultado aparece no terminal e em `reports/` (HTML e XML, fora do git). No editor, os testes também
podem ser rodados pelo painel do GdUnit4 (o plugin já está ativado no projeto).
