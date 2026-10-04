extends RefCounted

## English → Brazilian Portuguese (pt-BR) translations, keyed by the exact English
## source string used at the call site. Locale.t() looks strings up here when the
## language is Portuguese; a missing key falls back to the English source, so
## partial coverage is safe.
##
## Keep keys byte-for-byte identical to the source (including the curly
## apostrophe ’, guillemets « », em dash —, ellipsis …, and \n line breaks).

const MAP := {
	# ══════════════════════════════════════════════════════════════════════════
	#  UI — title, menus, common buttons
	# ══════════════════════════════════════════════════════════════════════════
	"LOAD GAME": "CARREGAR",
	"NEW GAME": "NOVO JOGO",
	"HIGH SCORES": "MELHORES PONTUAÇÕES",
	"EXIT GAME": "SAIR",
	"📊 Statistics": "📊 Estatísticas",
	"STATISTICS": "ESTATÍSTICAS",
	"Run Stats": "Estatísticas de descida",
	"Runs Played": "Descidas jogadas",
	"Runs Won": "Descidas vencidas",
	"Win Rate": "Taxa de vitória",
	"Best Score": "Melhor pontuação",
	"Best Time": "Melhor tempo",
	"Total Score": "Pontuação total",
	"Game Stats": "Estatísticas de jogo",
	"Games Played": "Partidas jogadas",
	"Games Won": "Partidas vencidas",
	"By Variant": "Por variante",
	"Variant": "Variante",
	"Played": "Jogadas",
	"Won": "Vencidas",
	"Win %": "Vit. %",
	"OPTIONS": "OPÇÕES",
	"CREDITS": "CRÉDITOS",
	"Options": "Opções",
	"Game Design, Art & Writing": "Design, arte e roteiro",
	"aka Emjayhar": "vulgo Emjayhar",
	"AI tools were used to assist with the game's source code.": "Ferramentas de IA auxiliaram no código-fonte do jogo.",
	"Music": "Música",
	"Made With": "Feito com",
	"Fonts": "Fontes",
	"Licensed under the SIL Open Font License": "Sob licença SIL Open Font License",
	"All rights reserved.": "Todos os direitos reservados.",
	"Solitaire Tower of Doom™ is a trademark of Mario Jorge Ramos.": "Solitaire Tower of Doom™ é uma marca de Mario Jorge Ramos.",
	"Back": "Voltar",
	"Back ▸": "Voltar ▸",
	"◂ Back": "◂ Voltar",
	"Done": "Concluído",
	"Cancel": "Cancelar",
	"Continue ▸": "Continuar ▸",
	"Begin": "Começar",
	"Skip ▸▸": "Pular ▸▸",
	"Language": "Idioma",
	"Audio": "Áudio",
	"♪  Music": "♪  Música",
	"🔊  Sound Effects": "🔊  Efeitos sonoros",
	"🔊  Sound": "🔊  Som",
	"🔊 Sound": "🔊 Som",

	# ══════════════════════════════════════════════════════════════════════════
	#  Map / tower hub
	# ══════════════════════════════════════════════════════════════════════════
	"Royalty-free music from Pixabay.com": "Música livre de direitos de pixabay.com",
	"A narrative horror roguelike Solitaire by Emjayhar": "Um Paciência roguelike, narrativo e de horror, por Emjayhar",
	"Face the Cult of Patience and uncover the occult secret history of Solitaire": "Enfrente o Culto da Paciência e descubra a história secreta e oculta do Paciência",
	"PLAYER": "JOGADOR",
	"LIVES": "VIDAS",
	"Player": "Jogador",
	"Lives": "Vidas",
	"🏆 HIGH SCORES": "🏆 MELHORES PONTUAÇÕES",
	"Time Patron": "Patrono do Tempo",
	"Time Credits": "Créditos Temporais",
	"Time Energy": "Energia Temporal",
	"🎒 Inventory": "🎒 Inventário",
	"[ EMPTY ]": "[ VAZIO ]",
	"Lore": "Saber",
	"📖 Compendium": "📖 Compêndio",
	"Customize": "Personalizar",
	"🂠 Cardback": "🂠 Verso da carta",
	"▶ Watch Intro": "▶ Rever a introdução",
	"🏠 Main Menu": "🏠 Menu principal",
	"⚑ New Run": "⚑ Nova descida",
	"HIGH SCORES ": "MELHORES PONTUAÇÕES ",
	"🏆 High Scores": "🏆 Melhores pontuações",
	"New Run": "Nova descida",
	"Start a New Run?\n\nThis ends your current descent — the rest of your lives are forfeit and your run is scored now.": "Começar uma nova descida?\n\nIsto encerra sua descida atual — suas vidas restantes são perdidas e sua partida é pontuada agora.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Game screen — HUD, toolbar, status, overlays
	# ══════════════════════════════════════════════════════════════════════════
	"↩ Undo (%d)": "↩ Desfazer (%d)",
	"⟳ Shuffle": "⟳ Reembaralhar",
	"⏸ Pause": "⏸ Pausar",
	"✕ Abandon": "✕ Abandonar",
	"Floor %d of %d": "Andar %d de %d",
	"%d/%d floors": "%d/%d andares",
	"★ %d pts": "★ %d pts",
	"Paused": "Em pausa",
	"Resume": "Retomar",
	"Restart Floor": "Reiniciar o andar",
	"Abandon Run": "Abandonar a descida",
	"Re-deal this floor with a fresh shuffle?\n\nYou will lose a life.": "Redistribuir este andar com um novo embaralhamento?\n\nVocê perderá uma vida.",
	"Abandon this floor?\n\nYou will lose a life and return to the map.": "Abandonar este andar?\n\nVocê perderá uma vida e voltará ao mapa.",
	"Floor Cleared!": "Andar concluído!",
	"You Win!": "Vitória!",
	"No moves left": "Nenhuma jogada possível",
	"No legal move": "Jogada inválida",
	"Descend ▸": "Descer ▸",
	"CHEAT: floor cleared": "TRAPAÇA: andar concluído",
	"CHEAT: inventory rerolled": "TRAPAÇA: inventário resorteado",
	"Recorded at #%d": "Registrado na posição #%d",

	# ══════════════════════════════════════════════════════════════════════════
	#  Variant names & rules
	# ══════════════════════════════════════════════════════════════════════════
	"Spider": "Spider",
	"Pyramid": "Pirâmide",
	# (Klondike, FreeCell, TriPeaks keep their names in Portuguese.)
	"Build 4 foundation piles A→K by suit": "Construa 4 fundações do Ás ao Rei por naipe",
	"Tableau: descending rank, alternating colour": "Tableau: valor decrescente, cores alternadas",
	"Draw from stock to waste; move waste top card to play": "Compre do monte para o descarte; jogue a carta do topo do descarte",
	"Flip hidden cards by clearing cards above them": "Vire as cartas ocultas removendo as que estão acima delas",
	"All cards dealt face-up — every deal is solvable": "Todas as cartas viradas para cima — toda distribuição tem solução",
	"Build foundations A→K by suit": "Construa as fundações do Ás ao Rei por naipe",
	"Use free cells as temporary card parking": "Use as células livres para estacionar cartas temporariamente",
	"Pair cards that sum to 13 (A=1, J=11, Q=12, K=13)": "Junte cartas que somem 13 (A=1, V=11, D=12, R=13)",
	"Kings are removed alone": "Os Reis são removidos sozinhos",
	"Use the waste top to pair with pyramid cards": "Use o topo do descarte para parear com as cartas da pirâmide",
	"Clear all pyramid cards to win": "Remova todas as cartas da pirâmide para vencer",
	"Build complete K→A sequences of the same suit": "Construa sequências completas do Rei ao Ás do mesmo naipe",
	"Completed sequences removed to foundations": "As sequências completas vão para as fundações",
	"Deal 10 new cards from stock when stuck": "Distribua 10 cartas novas do monte quando estiver travado",
	"Clear all 8 sequences to win": "Complete as 8 sequências para vencer",
	"Play cards +1 or -1 rank from waste top (A↔K wrap)": "Jogue cartas de valor +1 ou -1 em relação ao topo do descarte (o Ás e o Rei se ligam)",
	"Click pyramid cards to chain onto the waste": "Clique nas cartas da pirâmide para encadear no descarte",
	"Draw from stock when no move available": "Compre do monte quando não houver jogada possível",
	"Clear all 28 pyramid cards to win": "Remova as 28 cartas da pirâmide para vencer",

	# ══════════════════════════════════════════════════════════════════════════
	#  Shop
	# ══════════════════════════════════════════════════════════════════════════
	"The Merchant": "O Mercador",
	"Shop": "Loja",
	"Buy": "Comprar",
	"Owned": "Adquirido",
	"Sold Out": "Esgotado",
	"Can't afford": "Saldo insuficiente",
	"Descend to the next floor ▸": "Descer para o próximo andar ▸",
	"⏳ %d": "⏳ %d",
	"Floor Rewards": "Recompensas do andar",
	"⏳  Floor %d Cleared — Time Credits Awarded": "⏳  Andar %d concluído — Créditos Temporais concedidos",
	"🏪  John Dee's Cabinet of Curiosities — %d Items Available": "🏪  O Gabinete de Curiosidades de John Dee — %d itens disponíveis",
	"🎒  Your Inventory (%d/%d slots)": "🎒  Seu inventário (%d/%d espaços)",
	"Floor Cleared": "Andar concluído",
	"No Undos": "Sem desfazer",
	"Under 3 min": "Menos de 3 min",
	"Full Lives": "Vidas intactas",
	"Score Bonus": "Bônus de pontos",
	"TOTAL EARNED": "TOTAL GANHO",
	"YOUR BALANCE": "SEU SALDO",
	"CHEAP": "BARATO",
	"MEDIUM": "MÉDIO",
	"PRICEY": "CARO",
	"RARE": "RARO",

	# ── item names ──
	"Scrying Glass": "Vidro de Vidência",
	"Knotted Cord": "Corda de Nós",
	"Mortlake Brew": "Poção de Mortlake",
	"Quill of Ravens": "Pena de Corvos",
	"Sealing Wax": "Cera de Lacre",
	"Athame": "Athame",
	"Obsidian Mirror": "Espelho de Obsidiana",
	"Wax Seal Press": "Prensa de Selo",
	"Philosopher's Sponge": "Esponja do Filósofo",
	"Sealed Letter": "Carta Selada",
	"Brass Compass": "Bússola de Latão",
	"Astrolabe": "Astrolábio",
	"Hermetic Casket": "Cofre Hermético",
	"Skeleton Key": "Chave-mestra",
	"Alchemist's Cabinet": "Gabinete do Alquimista",
	"Angelic Besom": "Vassoura Angelical",
	"Enochian Key": "Chave Enoquiana",
	"Vial of Quicksilver": "Frasco de Mercúrio",
	"Queen's Patronage": "Favor da Rainha",

	# ── item descriptions ──
	"Highlights one valid move on the board.": "Destaca uma jogada válida no tabuleiro.",
	"You only get 3 undos per floor. This adds 5 more.": "Você só tem 3 desfazeres por andar. Isto adiciona mais 5.",
	"Draw 1 extra card from stock for free.": "Compre 1 carta extra do monte de graça.",
	"Peek at the top 3 cards in the stock pile.": "Espie as 3 primeiras cartas do monte.",
	"Get one free waste→stock recycle.": "Ganhe uma reciclagem descarte→monte gratuita.",
	"Remove any one face-up card from the board entirely.": "Remove por completo do tabuleiro qualquer carta virada para cima.",
	"Reveal all face-down cards for 8 seconds.": "Revela todas as cartas viradas para baixo por 8 segundos.",
	"Digs an Ace out from anywhere — even buried or face-down — and sends it to its foundation.": "Desenterra um Ás de qualquer lugar — mesmo soterrado ou virado para baixo — e o envia à sua fundação.",
	"Mega-undo: rewind up to 10 moves at once.": "Mega-desfazer: volte até 10 jogadas de uma só vez.",
	"Shuffle waste back into stock for free.": "Reembaralha o descarte de volta no monte de graça.",
	"Flip any face-down tableau card face-up.": "Vire para cima qualquer carta oculta do tableau.",
	"Flash ALL valid moves for 8 seconds.": "Exibe TODAS as jogadas válidas por 8 segundos.",
	"Bring any buried waste card to the top to play next.": "Traz qualquer carta soterrada do descarte para o topo, pronta para jogar.",
	"Unlock a 5th free cell for this entire floor.": "Libera uma 5ª célula livre para todo este andar.",
	"Creates a temporary off-board card stash (1 card, 8 uses).": "Cria um esconderijo temporário fora do tabuleiro (1 carta, 8 usos).",
	"Sweep the top card of any pile to the first empty column.": "Varre a carta do topo de qualquer pilha para a primeira coluna vazia.",
	"Pull any card from stock to the top of the waste pile.": "Puxe qualquer carta do monte para o topo do descarte.",
	"Abandon this floor without losing a life.": "Abandone este andar sem perder uma vida.",
	"Skip this floor entirely -- counts as cleared!": "Pule este andar por completo — ele conta como concluído!",

	# ── item use hints ──
	"Instant: glows on valid source & target.": "Instantâneo: ilumina origem e destino válidos.",
	"Instant: adds 5 undos to your budget.": "Instantâneo: adiciona 5 desfazeres à sua reserva.",
	"Instant: free stock draw.": "Instantâneo: compra gratuita do monte.",
	"Shows a 6-second preview window.": "Mostra uma janela de prévia de 6 segundos.",
	"Instant: recycles without counting.": "Instantâneo: recicla sem ser contabilizado.",
	"Click mode: pick a card to vanish it.": "Modo clique: escolha uma carta para fazê-la sumir.",
	"Instant: temporary x-ray vision.": "Instantâneo: visão de raio-X temporária.",
	"Instant: finds an Ace anywhere.": "Instantâneo: encontra um Ás em qualquer lugar.",
	"Instant: pops 10 undo states.": "Instantâneo: desfaz até 10 jogadas de uma vez.",
	"Instant: free recycle.": "Instantâneo: reciclagem gratuita.",
	"Click mode: pick a face-down card.": "Modo clique: escolha uma carta virada para baixo.",
	"Instant: full board hint glow.": "Instantâneo: ilumina o tabuleiro inteiro.",
	"Opens waste picker -- select a card.": "Abre o seletor de descarte — escolha uma carta.",
	"Instant: adds a free cell slot.": "Instantâneo: adiciona uma célula livre.",
	"Drag any card in/out of the stash.": "Arraste qualquer carta para dentro/fora do esconderijo.",
	"Click mode: pick a source pile top.": "Modo clique: escolha o topo de uma pilha de origem.",
	"Opens stock browser -- pick your card.": "Abre o explorador do monte — escolha sua carta.",
	"Instant: safe retreat to the map.": "Instantâneo: retirada segura para o mapa.",
	"Instant: auto-win current floor.": "Instantâneo: vitória automática no andar atual.",

	# ── item best_for ──
	"All games": "Todos os jogos",
	"Klondike · TriPeaks": "Klondike · TriPeaks",
	"Klondike · Pyramid": "Klondike · Pirâmide",
	"Pyramid · TriPeaks": "Pirâmide · TriPeaks",
	"Spider · Klondike": "Spider · Klondike",
	"Klondike · FreeCell": "Klondike · FreeCell",
	"FreeCell": "FreeCell",
	"Spider · FreeCell · Klondike": "Spider · FreeCell · Klondike",
	"Spider · FreeCell": "Spider · FreeCell",
	"All games (emergency!)": "Todos os jogos (emergência!)",
	"All games (boss skip!)": "Todos os jogos (pular o chefe!)",

	# ══════════════════════════════════════════════════════════════════════════
	#  Cardbacks
	# ══════════════════════════════════════════════════════════════════════════
	"The Solitaire Tower": "A Torre do Paciência",
	"The King of Hearts": "O Rei de Copas",
	"John Dee's portrait": "Retrato de John Dee",
	"Mary Stuart's portrait": "Retrato de Mary Stuart",

	# ══════════════════════════════════════════════════════════════════════════
	#  Patron select
	# ══════════════════════════════════════════════════════════════════════════
	"Choose Your Time Patron": "Escolha seu Patrono do Tempo",
	"An ally for this descent, lending their nature to the wares you can purchase along the way.": "Um aliado para esta descida, emprestando sua natureza aos itens que você poderá comprar pelo caminho.",
	"Select John Dee to begin your descent.": "Escolha John Dee para começar sua descida.",
	"🔒": "🔒",

	# ══════════════════════════════════════════════════════════════════════════
	#  Cardback select
	# ══════════════════════════════════════════════════════════════════════════
	"Choose Your Cardback": "Escolha o verso da sua carta",
	"Locked designs are revealed by uncovering a Time Patron's connection to Solitaire in the Compendium.": "Os modelos bloqueados são revelados ao descobrir, no Compêndio, a ligação de um Patrono do Tempo com o Paciência.",
	"← Back to Tower": "← Voltar à Torre",

	# ══════════════════════════════════════════════════════════════════════════
	#  Slots
	# ══════════════════════════════════════════════════════════════════════════
	"SLOT %d": "ESPAÇO %d",
	"No run in progress": "Nenhuma descida em andamento",
	"— Empty —": "— Vazio —",
	"⚡ %d   ✓ %d": "⚡ %d   ✓ %d",

	# ══════════════════════════════════════════════════════════════════════════
	#  High scores
	# ══════════════════════════════════════════════════════════════════════════
	"⟳ Sync now": "⟳ Sincronizar",
	"No scores to show yet.": "Nenhuma pontuação para mostrar ainda.",
	"Local": "Local",
	"Online": "Online",

	# ══════════════════════════════════════════════════════════════════════════
	#  Compendium — dynamic bits
	# ══════════════════════════════════════════════════════════════════════════
	"⚡ Time Energy: %d": "⚡ Energia Temporal: %d",
	"🔒  Unknown Patron": "🔒  Patrono desconhecido",
	"TIMELINE OF CIVILIZATION": "CRONOLOGIA DA CIVILIZAÇÃO",
	"No connections to the historical record have been uncovered yet.": "Nenhuma ligação com os registros históricos foi descoberta ainda.",
	"UNCOVER (%d ⚡)": "REVELAR (%d ⚡)",
	"You: ": "Você: ",
	"⚙ This Time Patron is still in development and cannot yet be selected.": "⚙ Este Patrono do Tempo ainda está em desenvolvimento e não pode ser escolhido.",
	"Unknown Patron": "Patrono desconhecido",
	"You": "Você",
	"Strategy": "Estratégia",
	"Connection to Solitaire": "Ligação com o Paciência",
	"This Time Patron has not yet revealed themselves to you.": "Este Patrono do Tempo ainda não se revelou a você.",
	"The First Contact": "O primeiro contato",
	"A Moment's Respite": "Um momento de descanso",
	"More Than Halfway": "Mais da metade",
	"The Final Threshold": "O limiar final",
	"The Compendium": "O Compêndio",
	"← Prev": "← Ant.",
	"Next →": "Próx. →",
	"NEED %d MORE ⚡": "FALTAM %d ⚡",
	"Online ✓": "Online ✓",

	# ══════════════════════════════════════════════════════════════════════════
	#  Game screen — HUD, overlays, item card, score ledger
	# ══════════════════════════════════════════════════════════════════════════
	"Solitaire Tower of Doom · Early Access v%s": "Solitaire Tower of Doom · Acesso antecipado v%s",
	"Solitaire Tower of Doom — %s (Floor %d)": "Solitaire Tower of Doom — %s (Andar %d)",
	"Floor %d of 10": "Andar %d de 10",
	"🚪 ESCAPED!": "🚪 ESCAPOU!",
	"✅ FLOOR CLEARED": "✅ ANDAR CONCLUÍDO",
	"You burst into the streets! You are FREE!": "Você irrompe nas ruas! Você está LIVRE!",
	"Staircase found. Descending…": "Escada encontrada. Descendo…",
	"[ ESCAPE ]": "[ ESCAPAR ]",
	"[ DESCEND ]": "[ DESCER ]",
	"⏸ PAUSED": "⏸ EM PAUSA",
	"▶ Continue": "▶ Continuar",
	"★ Score History — Floor %d": "★ Histórico de pontos — Andar %d",
	"No scoring events this floor yet.": "Nenhum ponto marcado neste andar ainda.",
	"Close": "Fechar",
	"🗄️ stash empty (%d)": "🗄️ esconderijo vazio (%d)",

	# ══════════════════════════════════════════════════════════════════════════
	#  Shop — buttons & states
	# ══════════════════════════════════════════════════════════════════════════
	"Best for: %s": "Ideal para: %s",
	"[ ALREADY OWNED ]": "[ JÁ ADQUIRIDO ]",
	"[ INVENTORY FULL ]": "[ INVENTÁRIO CHEIO ]",
	"[ NEED %d MORE ⏳ ]": "[ FALTAM %d ⏳ ]",
	"[ BUY ]": "[ COMPRAR ]",
	"⚠ Inventory full! Use or drop items in-game.": "⚠ Inventário cheio! Use ou descarte itens durante o jogo.",
	"[ empty ]": "[ vazio ]",
	"⚔  Continue to the Tower": "⚔  Seguir para a Torre",
	"Acquired %s": "%s adquirido",

	# ══════════════════════════════════════════════════════════════════════════
	#  Compendium — headings
	# ══════════════════════════════════════════════════════════════════════════
	"Compendium": "Compêndio",
	"Time Patrons": "Patronos do Tempo",
	"Adversaries": "Adversários",
	"Connections": "Conexões",
	"Recorded Transmissions": "Transmissões registradas",
	"Locked": "Bloqueado",
	"Unlock": "Desbloquear",
	"Reveal": "Revelar",
	"In development": "Em desenvolvimento",
	"Under development": "Em desenvolvimento",

	# ══════════════════════════════════════════════════════════════════════════
	#  Patrons & lore (compendium prose)
	# ══════════════════════════════════════════════════════════════════════════
	"The Other Queen": "A Outra Rainha",
	"The Sun King": "O Rei Sol",
	"The Old Lion": "O Velho Leão",
	"The Emperor": "O Imperador",
	"The Prisoner": "O Prisioneiro",
	"Mary, Queen of Scots": "Mary, Rainha dos Escoceses",
	"Elizabeth I's astrologer and master spy": "Astrólogo e mestre-espião de Elizabeth I",
	"Queen of Scots, England's royal prisoner": "Rainha dos Escoceses, prisioneira real da Inglaterra",
	"The astrologer trades in sight — see what is hidden, know what approaches.": "O astrólogo negocia com a visão — veja o que está oculto, saiba o que se aproxima.",
	"The Cult of Patience": "O Culto da Paciência",
	"The Digitization Strategy": "A estratégia de digitalização",

	"John Dee was the most accomplished intellectual of Elizabethan England — a mathematician, cartographer, astronomer, and the personal astrologer of Queen Elizabeth I. It was Dee who calculated the most auspicious date for her coronation. His library at Mortlake was the largest private collection in England, until a mob ransacked it.": "John Dee foi o intelectual mais completo da Inglaterra elisabetana — matemático, cartógrafo, astrônomo e astrólogo pessoal da rainha Elizabeth I. Foi Dee quem calculou a data mais auspiciosa para a coroação dela. Sua biblioteca em Mortlake era a maior coleção particular da Inglaterra, até que uma multidão a saqueou.",
	"He spent years trying to communicate with angels through a crystal ball and a medium named Edward Kelley, recording these conversations in an elaborate cipher. His notation system; Enochian, the supposed language of angels, became a cornerstone of Western occultism.": "Ele passou anos tentando se comunicar com anjos por meio de uma bola de cristal e de um médium chamado Edward Kelley, registrando essas conversas em uma cifra elaborada. Seu sistema de notação, o enoquiano, suposta língua dos anjos, tornou-se um pilar do ocultismo ocidental.",
	"Dee also traveled undercover as an intelligence agent for Elizabeth's court. He signed his correspondence to the queen \"007\". The two zeros representing a spy's watching eyes, the seven a lucky number.": "Dee também viajou disfarçado como agente de inteligência da corte de Elizabeth. Ele assinava sua correspondência à rainha como \"007\". Os dois zeros representavam os olhos vigilantes de um espião, e o sete era um número da sorte.",
	"Legend has it that Dee visited Mary, Queen of Scots during her captivity, perhaps at Chartley or Fotheringhay, and taught her a card layout he presented as a method of divination. The game was supposedly meant to occupy her mind through the long nights before her execution.": "Reza a lenda que Dee visitou Mary, Rainha dos Escoceses, durante seu cativeiro, talvez em Chartley ou Fotheringhay, e lhe ensinou uma disposição de cartas que apresentou como método de adivinhação. O jogo supostamente serviria para ocupar a mente dela nas longas noites que antecederam sua execução.",
	"More deeply, Dee believed the universe itself was encoded, that behind the apparent randomness of the cards lay a divine mathematical order. He was one of the first to suspect that the Sacred Shuffle is a source of immense power.": "Mais profundamente, Dee acreditava que o próprio universo era codificado, que por trás da aparente aleatoriedade das cartas havia uma ordem matemática divina. Foi um dos primeiros a suspeitar que o Embaralhamento Sagrado é fonte de um poder imenso.",

	"Mary became Queen of Scotland when she was just six days old, after her father, James V, died in 1542. Because she was an infant, Scotland was ruled by regents while Mary spent much of her childhood in France, where she was raised at the French court and eventually married the Dauphin, François. When he became King of France in 1559, Mary was briefly Queen of both Scotland and France, but François died only a year later, in 1560, leaving her a widow at eighteen.": "Mary tornou-se Rainha da Escócia com apenas seis dias de vida, após a morte de seu pai, Jaime V, em 1542. Por ser um bebê, a Escócia foi governada por regentes enquanto Mary passava boa parte da infância na França, criada na corte francesa e, por fim, casada com o delfim François. Quando ele se tornou Rei da França em 1559, Mary foi brevemente Rainha da Escócia e da França, mas François morreu apenas um ano depois, em 1560, deixando-a viúva aos dezoito anos.",
	"Mary returned to Scotland in 1561 to rule in person, landing in a country deeply divided by the Protestant Reformation, while she herself remained Catholic. Her reign was turbulent: she married her cousin Henry Stuart, Lord Darnley, in 1565, and the marriage quickly soured amid political plotting and violence, including Darnley's involvement in the murder of Mary's secretary, David Rizzio. Darnley himself was murdered in 1567, and Mary's swift marriage afterward to James Hepburn, Earl of Bothwell, widely suspected in Darnley's death, scandalized the nobility and triggered a rebellion.": "Mary voltou à Escócia em 1561 para governar pessoalmente, chegando a um país profundamente dividido pela Reforma Protestante, enquanto ela própria permanecia católica. Seu reinado foi turbulento: casou-se com o primo Henry Stuart, Lorde Darnley, em 1565, e o casamento azedou rapidamente em meio a tramas políticas e violência, incluindo o envolvimento de Darnley no assassinato do secretário de Mary, David Rizzio. O próprio Darnley foi assassinado em 1567, e o rápido casamento de Mary em seguida com James Hepburn, Conde de Bothwell, amplamente suspeito da morte de Darnley, escandalizou a nobreza e provocou uma rebelião.",
	"Forced to abdicate in favor of her infant son (who became James VI of Scotland, and later James I of England), Mary fled to England in 1568, seeking the protection of her cousin, Queen Elizabeth I. Instead, Elizabeth had her held in a long series of confinements lasting nearly two decades. Mary became a magnet for Catholic plots aiming to depose Elizabeth and place Mary on the English throne; most damningly the Babington Plot of 1586, in which intercepted letters appeared to show Mary endorsing Elizabeth's assassination. Tried and convicted of treason, Mary was executed at Fotheringhay Castle in February 1587.": "Forçada a abdicar em favor de seu filho ainda bebê (que se tornou Jaime VI da Escócia e, mais tarde, Jaime I da Inglaterra), Mary fugiu para a Inglaterra em 1568, buscando a proteção de sua prima, a rainha Elizabeth I. Em vez disso, Elizabeth a manteve em uma longa série de confinamentos que durou quase duas décadas. Mary tornou-se um ímã para conspirações católicas que visavam depor Elizabeth e colocá-la no trono inglês; a mais incriminadora foi a Conspiração de Babington, de 1586, na qual cartas interceptadas pareciam mostrar Mary endossando o assassinato de Elizabeth. Julgada e condenada por traição, Mary foi executada no Castelo de Fotheringhay em fevereiro de 1587.",
	"Her son James VI later united the crowns of Scotland and England as James I, making Mary, in a sense, the ancestress of the joint British monarchy; a final ironic twist to a reign defined by intrigue, religious conflict, and tragedy.": "Seu filho Jaime VI mais tarde uniu as coroas da Escócia e da Inglaterra como Jaime I, fazendo de Mary, em certo sentido, a ancestral da monarquia britânica unificada; uma última ironia para um reinado marcado por intriga, conflito religioso e tragédia.",

	"The Cult of Patience is an organization whose origins date back at least to the 17th century, perhaps further. Its members share one core conviction: the Sacred Shuffle exists, it is attainable, and whoever possesses it possesses time itself.": "O Culto da Paciência é uma organização cujas origens remontam pelo menos ao século XVII, talvez mais longe. Seus membros compartilham uma convicção central: o Embaralhamento Sagrado existe, é alcançável, e quem o possui possui o próprio tempo.",
	"Unlike the Time Patrons, who guard the secret out of caution and respect, the Cult wants it for domination. They do not seek to understand Solitaire, they seek to exploit it.": "Ao contrário dos Patronos do Tempo, que guardam o segredo por cautela e respeito, o Culto o quer para dominar. Eles não buscam compreender o Paciência, buscam explorá-lo.",
	"The digitization of Solitaire in the 1990s was seen by the Cult as a historic windfall. For the first time, millions of games could be played simultaneously, by ordinary people, unaware of what they were searching for.": "A digitalização do Paciência nos anos 1990 foi vista pelo Culto como uma dádiva histórica. Pela primeira vez, milhões de partidas podiam ser jogadas simultaneamente, por pessoas comuns, sem saber o que procuravam.",
	"Their current plan is brutally simple: seize a building, an office tower, a building full of office workers, and force its occupants to play Solitaire continuously, around the clock. By the sheer law of large numbers, the Sacred Shuffle will eventually appear on one of the screens.": "Seu plano atual é de uma simplicidade brutal: tomar um edifício, uma torre de escritórios, um prédio cheio de funcionários, e forçar seus ocupantes a jogar Paciência continuamente, dia e noite. Pela simples lei dos grandes números, o Embaralhamento Sagrado acabará aparecendo em uma das telas.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — shared chrome
	# ══════════════════════════════════════════════════════════════════════════
	"📞  Incoming Transmission -- John Dee": "📞  Transmissão recebida -- John Dee",
	"What would you like to ask?": "O que você gostaria de perguntar?",
	"That's all for now.": "Isso é tudo por enquanto.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — victory
	# ══════════════════════════════════════════════════════════════════════════
	"You have shown why you were chosen by the Sacred Shuffle. I am afraid, though, this journey is only beginning.": "Você mostrou por que foi escolhido pelo Embaralhamento Sagrado. Temo, porém, que esta jornada esteja apenas começando.",
	"Our victory over the Cult of Doom will only be complete when all Time Patrons are revealed.": "Nossa vitória sobre o Culto da Perdição só estará completa quando todos os Patronos do Tempo forem revelados.",
	"Alright, reset time!": "Certo, vamos reiniciar o tempo!",
	"I just want to go home.": "Eu só quero ir para casa.",
	"That is the spirit!": "Esse é o espírito!",
	"Not until our work is done.": "Não antes de nossa obra estar concluída.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — Dee check-in (after floor 3)
	# ══════════════════════════════════════════════════════════════════════════
	"You are doing well. You have a moment’s respite. If you have any questions, I will answer them to the extent of my knowledge.": "Você está indo bem. Tem um momento de descanso. Se tiver perguntas, responderei na medida do meu conhecimento.",
	"Who are these guys, anyway?": "Quem são esses caras, afinal?",
	"Why do they want the Sacred Shuffle?": "Por que eles querem o Embaralhamento Sagrado?",
	"Why are you involved in all this?": "Por que você está envolvido nisso tudo?",
	"What is my role in all this?": "Qual é o meu papel nisso tudo?",
	"They call themselves the Cult of Patience. I call them the Cult of Doom.": "Eles se chamam de Culto da Paciência. Eu os chamo de Culto da Perdição.",
	"The earlier traces of their existence date back to the 17th century, but they may have existed even before then.": "Os primeiros vestígios de sua existência remontam ao século XVII, mas talvez já existissem antes disso.",
	"They have been trying to play the Sacred Shuffle for centuries. In the shadows.": "Eles tentam jogar o Embaralhamento Sagrado há séculos. Nas sombras.",
	"What’s different now?": "O que mudou agora?",
	"The Digital Age.": "A era digital.",
	"A single game of cards, dealt and shuffled by hand, takes no small measure of time to set in order and play to its end. With these machines of your time, hundreds, thousands shuffles can be generated and played in mere seconds.": "Uma única partida de cartas, distribuída e embaralhada à mão, exige um tempo nada desprezível para ser posta em ordem e levada ao fim. Com estas máquinas da sua época, centenas, milhares de embaralhamentos podem ser gerados e jogados em meros segundos.",
	"Who’s behind the masks?": "Quem está por trás das máscaras?",
	"Nobility rejects, revolution survivors, ex-political prisoners. People who fell from high, in terms of their position in society. Their obsessive need for wealth, power and stature has twisted their minds beyond recognition.": "Rejeitados da nobreza, sobreviventes de revoluções, ex-presos políticos. Pessoas que caíram do alto, em termos de posição na sociedade. Sua necessidade obsessiva de riqueza, poder e prestígio retorceu suas mentes a ponto de torná-las irreconhecíveis.",
	"They have extended their lives with dangerous dark arts. The longer they live, the less human they become. Only the obsession remains.": "Eles prolongaram suas vidas com perigosas artes das trevas. Quanto mais vivem, menos humanos se tornam. Só a obsessão permanece.",
	"Their masks are not meant to hide their identity, they’re meant to hide from themselves their own hideous faces.": "Suas máscaras não servem para esconder sua identidade, servem para esconder deles mesmos seus próprios rostos medonhos.",
	"Time and change are their enemies. They believe the Sacred Shuffle can take them back to a time where they were at the height of their power, and keep them there, forever.": "O tempo e a mudança são seus inimigos. Eles acreditam que o Embaralhamento Sagrado pode levá-los de volta a uma época em que estavam no auge de seu poder, e mantê-los ali, para sempre.",
	"They want to make everything great again, huh.": "Eles querem fazer tudo ser grande de novo, né.",
	"Hardly. Time would be broken. It would no longer pass. They would be princes, kings, emperors, in their own individual timeloops. At least, that’s my theory. It’s better to not find out.": "Longe disso. O tempo seria quebrado. Deixaria de passar. Eles seriam príncipes, reis, imperadores, cada um em seu próprio laço temporal. Ao menos, essa é a minha teoria. É melhor não descobrir.",
	"I get the picture; everyone else would be their NPCs.": "Entendi; todo mundo seria NPC deles.",
	"NPC?": "NPC?",
	"Never mind.": "Deixa pra lá.",
	"I have been studying the history and variants of the game you call Solitaire since my years spent in Rudolf II’s court in Prague, the center of Kabbalistic scholarship.": "Estudo a história e as variantes do jogo que vocês chamam de Paciência desde os anos que passei na corte de Rodolfo II em Praga, o centro da erudição cabalística.",
	"Another name Solitaire goes by is Patience. The Scandinavian word for patience is kabale.": "Outro nome pelo qual o Paciência é conhecido é Patience. A palavra escandinava para paciência é kabale.",
	"While it did become a game of patience for the impatient, it’s roots lie in divination. You could say I have a passion for ciphers, secret languages, the mathematical codes that rule the cosmos.": "Embora tenha se tornado um jogo de paciência para os impacientes, suas raízes estão na adivinhação. Pode-se dizer que tenho paixão por cifras, línguas secretas, os códigos matemáticos que regem o cosmos.",
	"As I came to understand the power of a deck of cards, I managed to establish connections through time with other souls who became aware of the existence of the Sacred Shuffle, and shared my concern about the Cult of Doom.": "À medida que compreendi o poder de um baralho, consegui estabelecer ligações através do tempo com outras almas que tomaram ciência da existência do Embaralhamento Sagrado e compartilhavam minha preocupação com o Culto da Perdição.",
	"Like a group of super good guys.": "Tipo um grupo de super mocinhos.",
	"Good? Don’t fool yourself into thinking I operate in the name of good, or that any other of the Time Patrons have good intentions. We each have our own incentives.": "Bons? Não se iluda pensando que eu ajo em nome do bem, nem que qualquer outro dos Patronos do Tempo tenha boas intenções. Cada um de nós tem seus próprios interesses.",
	"Like what?": "Como o quê?",
	"Wealth, power and stature.": "Riqueza, poder e prestígio.",
	"…": "…",
	"The only difference between the Time Patrons and the Cult of Doom is that we accept time and change, and rather achieve wealth, power and stature by the natural order of things.": "A única diferença entre os Patronos do Tempo e o Culto da Perdição é que nós aceitamos o tempo e a mudança, e preferimos alcançar riqueza, poder e prestígio pela ordem natural das coisas.",
	"And by NOT destroying human civilization as we know it.": "E por NÃO destruir a civilização humana como a conhecemos.",
	"You can trust that, but don’t trust anybody.": "Nisso você pode confiar, mas não confie em ninguém.",
	"You are destined to play the Sacred Shuffle.": "Você está destinado a jogar o Embaralhamento Sagrado.",
	"Great, so we’ve already won in the future?": "Ótimo, então a gente já venceu no futuro?",
	"No. Some things are written. Others remain in ceaseless... shuffle.": "Não. Algumas coisas estão escritas. Outras permanecem em incessante… embaralhamento.",
	"Ha.": "Ha.",
	"You WILL play the Sacred Shuffle. But, who will profit from it? The Cult? You? Humanity?": "Você VAI jogar o Embaralhamento Sagrado. Mas quem lucrará com isso? O Culto? Você? A humanidade?",
	"You?": "Você?",
	"I’m afraid you have no choice but to trust me.": "Temo que você não tenha escolha senão confiar em mim.",
	"I guess.": "Acho que sim.",
	"OK, I will trust you for now.": "Certo, vou confiar em você por ora.",
	"We hold one great advantage over the Cult. A card up our sleeve, in a manner of speaking!": "Temos uma grande vantagem sobre o Culto. Uma carta na manga, por assim dizer!",
	"Were you the Queen's official punster?": "Você era o trocadilhista oficial da Rainha?",
	"The Cult does not know that the Sacred Shuffle does not choose a screen. It chooses a player. They do not know you have been chosen. They cannot know. You have to keep playing and beat a shuffle on every floor.": "O Culto não sabe que o Embaralhamento Sagrado não escolhe uma tela. Ele escolhe um jogador. Eles não sabem que você foi escolhido. Não podem saber. Você precisa continuar jogando e vencer um embaralhamento em cada andar.",
	"Ten floors. So ten games and that’s it?": "Dez andares. Então dez partidas e pronto?",
	"Not quite. When you leave the building, time will reset. You will have to do it again. To put it in simple terms: we cannot do it alone. You are performing a summoning ritual.": "Não exatamente. Quando você deixar o edifício, o tempo se reiniciará. Você terá de fazer tudo de novo. Em termos simples: não conseguimos fazer isso sozinhos. Você está executando um ritual de invocação.",
	"Who I am summoning?": "Quem eu estou invocando?",
	"Your other patrons through the ages. People who by fate or by chance got close to the Sacred Shuffle and whose destinies were forever intertwined with the cosmic mathematics of Solitaire.": "Seus outros patronos através das eras. Pessoas que, por destino ou acaso, se aproximaram do Embaralhamento Sagrado e cujos destinos se entrelaçaram para sempre com a matemática cósmica do Paciência.",
	"Kings, Queens, Emperors, Prisoners, Poets and Adventurers, among others.": "Reis, rainhas, imperadores, prisioneiros, poetas e aventureiros, entre outros.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — Dee (third transmission, after floor 6)
	# ══════════════════════════════════════════════════════════════════════════
	"You are now more than halfway through. Take a break. Go drink some water.": "Você já passou da metade. Faça uma pausa. Vá beber água.",
	"I don’t think The Cult of Doom brought any water bottles.": "Acho que o Culto da Perdição não trouxe garrafas de água.",
	"Oh, I wasn’t talking to you.": "Ah, eu não estava falando com você.",
	"Huh?": "Hã?",
	"Never mind. Do you have any other questions? The other Time Patrons might not be as helpful as I.": "Deixa pra lá. Você tem outras perguntas? Os outros Patronos do Tempo podem não ser tão prestativos quanto eu.",
	"You keep mentioning other Time Patrons…": "Você não para de mencionar outros Patronos do Tempo…",
	"Who are they?": "Quem são eles?",
	"What is their connection to Solitaire?": "Qual é a ligação deles com o Paciência?",
	"When will I meet them?": "Quando eu vou conhecê-los?",
	"Mostly nobles, kings, princesses, lords…": "Em sua maioria nobres, reis, princesas, lordes…",
	"Great, I’m caught between two groups of rich people fighting for more power.": "Ótimo, estou preso entre dois grupos de ricos brigando por mais poder.",
	"I’m afraid that’s how human history goes. I presume it’s still the case in your time.": "Temo que seja assim que a história humana funciona. Presumo que ainda seja o caso na sua época.",
	"…pretty much.": "…basicamente, sim.",
	"A lot of them also fell from high, found hardship, exile, captivity, and in duress, almost touched the Sacred Shuffle.": "Muitos deles também caíram do alto, conheceram a privação, o exílio, o cativeiro e, sob coação, quase tocaram o Embaralhamento Sagrado.",
	"What do you mean « almost »?": "O que você quer dizer com « quase »?",
	"They got close to the Sacred Shuffle by helping you find it.": "Eles se aproximaram do Embaralhamento Sagrado ao ajudarem você a encontrá-lo.",
	"I’m confused.": "Estou confuso.",
	"Time paradoxes tend to do that.": "Paradoxos temporais costumam causar isso.",
	"You are.": "Você.",
	"Through Solitaire, they will talk to you from their time period, as I am doing. Through you, they are connected to the Sacred Shuffle.": "Através do Paciência, eles falarão com você desde suas épocas, como eu faço. Através de você, estão ligados ao Embaralhamento Sagrado.",
	"Which I haven’t found yet.": "Que eu ainda não encontrei.",
	"Our crude human senses can only perceive time as linear, but it is not. All of this has happened before…": "Nossos rudimentares sentidos humanos só percebem o tempo como linear, mas ele não é. Tudo isto já aconteceu antes…",
	"…all of this will happen again. How did I know that?": "…e tudo isto acontecerá de novo. Como eu sabia disso?",
	"Your memory is starting to leak through time. Even if you think this is the first time we’re having this conversation, it could be the millionth time.": "Sua memória está começando a vazar através do tempo. Mesmo que você ache que esta é a primeira vez que temos esta conversa, pode ser a milionésima.",
	"That’s encouraging.": "Que encorajador.",
	"You have to contact them.": "Você precisa contatá-los.",
	"How?": "Como?",
	"You need to generate Time Energy, but also you need to weave the threads of time, find the connections between the Time Patrons. Even I do not know their all their identities. There is one from my time...": "Você precisa gerar Energia Temporal, mas também tecer os fios do tempo, encontrar as conexões entre os Patronos do Tempo. Nem eu conheço todas as suas identidades. Há uma da minha época…",
	"Who?": "Quem?",
	"Mary Stuart, Queen of the Scots.": "Mary Stuart, Rainha dos Escoceses.",
	"Don’t they teach history in your time? Never mind. Just remember her name.": "Não ensinam história na sua época? Deixa pra lá. Apenas lembre-se do nome dela.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — Dee final (before floor 10)
	# ══════════════════════════════════════════════════════════════════════════
	"You’re almost at the end of the loop. You’re about to face your greatest challenge yet.": "Você está quase no fim do laço. Está prestes a enfrentar seu maior desafio até agora.",
	"Any advice?": "Algum conselho?",
	"Yes. Patience.": "Sim. Paciência.",
	"Another pun?": "Outro trocadilho?",
	"No. All you need to win is patience.": "Não. Tudo o que você precisa para vencer é paciência.",
	"What if I win?": "E se eu vencer?",
	"Go through the challenges of the Cult of Doom again, keep weaving the threads of the secret history of Solitaire and find the Sacred Shuffle!": "Enfrente novamente os desafios do Culto da Perdição, continue tecendo os fios da história secreta do Paciência e encontre o Embaralhamento Sagrado!",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — the intro (before Dee's face appears, then the first call)
	# ══════════════════════════════════════════════════════════════════════════
	"Click. Click. Click.": "Clique. Clique. Clique.",
	"Click!": "Clique!",
	"Click! Click! Click!": "Clique! Clique! Clique!",
	"Click! Click!": "Clique! Clique!",
	"You’ve done it again.": "Você conseguiu de novo.",
	"As you rub the armrests of your cheap office chair, you watch the cards bounce, bounce and bounce with profound satisfaction.": "Enquanto esfrega os braços da sua cadeira de escritório barata, você observa as cartas quicarem, quicarem e quicarem com profunda satisfação.",
	"Another Solitaire game completed, and you’ve beaten your personal record at that!": "Mais uma partida de Paciência concluída, e ainda por cima você bateu seu recorde pessoal!",
	"As the screen suddenly flickers…": "Quando a tela de repente pisca…",
	"You catch a glimpse of a face.": "Você vislumbra um rosto.",
	"It takes a moment to realize it's yours.": "Leva um instante até perceber que é o seu.",
	"You feel strangely compelled to keep looking at your screen, but by the corner of your eye, you notice everyone on the office floor is also mindlessly playing Solitaire.": "Você se sente estranhamente compelido a continuar olhando para a tela, mas, pelo canto do olho, nota que todos no andar do escritório também jogam Paciência de forma automática.",
	"Eyes so dead, skin so pale, lips so dry.": "Olhos tão mortos, peles tão pálidas, lábios tão secos.",
	"And then you see them.\nWho, or what, are they?\nHow long have they been here?": "E então você os vê.\nQuem, ou o quê, são eles?\nHá quanto tempo estão aqui?",
	"You feel like you're waking up from a long nightmare... into something worse.\n\nStartled, you ask yourself…": "Você sente que está acordando de um longo pesadelo… para algo pior.\n\nSobressaltado, você se pergunta…",
	"How long have I been playing Solitaire?": "Há quanto tempo eu estou jogando Paciência?",
	"Before you can even think of an answer, your screen flickers again.": "Antes mesmo de pensar numa resposta, sua tela pisca de novo.",
	"This time, you’re not looking at your face.": "Desta vez, não é o seu rosto que você está vendo.",
	"It's a bearded man with a look straight out of an 17th century painting.": "É um homem barbudo, com um aspecto saído diretamente de uma pintura do século XVII.",
	"I have definitely been playing too long…": "Eu definitivamente joguei tempo demais…",
	"Is this a feature or a bug?": "Isso é um recurso ou um bug?",
	"The face starts talking. It’s talking to you.": "O rosto começa a falar. Está falando com você.",
	"You wonder if you’re more confused by the fact that it’s talking to you or by the fact that it somehow knows what you were thinking.": "Você se pergunta o que o confunde mais: o fato de ele falar com você ou o fato de ele, de algum modo, saber o que você estava pensando.",
	"You have been playing a long time. But that is not important for now.": "Você está jogando há muito tempo. Mas isso não importa por ora.",
	"Who are you?": "Quem é você?",
	"My name is John Dee. Advisor and astrologer of Queen Elizabeth the First. I will die in 1608. From your point of view, I have been dead since 1608.": "Meu nome é John Dee. Conselheiro e astrólogo da rainha Elizabeth I. Morrerei em 1608. Do seu ponto de vista, estou morto desde 1608.",
	"What the hell?": "Que diabos?",
	"A peculiar phrasing, but hell indeed! Hear me now, and hear me well. I wish I had a calmer way to say this, but I do not: the fate of human civilization hangs in the balance.": "Uma expressão peculiar, mas diabos, de fato! Ouça-me agora, e ouça-me bem. Gostaria de ter um modo mais sereno de dizer isto, mas não tenho: o destino da civilização humana está em jogo.",
	"The Cult of Patience has seized the counting-house where you work, through means I won’t dignify to qualify as magic. They have been making you play Solitaire repeatedly, endlessly. Has it been days? Weeks? Months? I am not sure myself.": "O Culto da Paciência tomou a casa de contas onde você trabalha, por meios que não me rebaixarei a qualificar como magia. Eles têm feito você jogar Paciência repetidamente, sem fim. Já se passaram dias? Semanas? Meses? Nem eu tenho certeza.",
	"Let’s say I believe you. Why Solitaire?": "Digamos que eu acredite em você. Por que o Paciência?",
	"There are 52 cards in a standard deck in Solitaire. There are 80,658,175,170,943,878,571,660,636,856,403,\n766,975,289,505,440,883,277,824,000,000,000,000 possible arrangements.": "Há 52 cartas num baralho padrão de Paciência. Existem 80.658.175.170.943.878.571.660.636.856.403,\n766.975.289.505.440.883.277.824.000.000.000.000 arranjos possíveis.",
	"To better understand the magnitude of this number : It is more than the quantity of atoms that form the Earth.": "Para compreender melhor a magnitude deste número: ele é maior que a quantidade de átomos que formam a Terra.",
	"Whoa.": "Uau.",
	"There is one particular arrangement. The Sacred Shuffle. It does something extraordinary.": "Existe um arranjo específico. O Embaralhamento Sagrado. Ele realiza algo extraordinário.",
	"It gives dominion over time, way beyond the childish dark arts the Cult currently dabbles in, and way beyond the simple time projection I am using to contact you.": "Ele concede domínio sobre o tempo, muito além das artes das trevas infantis com que o Culto se entretém no momento, e muito além da simples projeção temporal que uso para contatá-lo.",
	"But what does all this have to do with me?": "Mas o que tudo isso tem a ver comigo?",
	"Only you can stop them.": "Só você pode detê-los.",
	"Huh, OK? How?": "Hã, tá? Como?",
	"By playing Solitaire. Repeatedly. Endlessly.": "Jogando Paciência. Repetidamente. Sem fim.",
	"Great.": "Ótimo.",
	"We will talk more later. Now, you must play or the Cult will notice you and kill you!": "Conversaremos mais depois. Agora, você precisa jogar ou o Culto notará você e o matará!",
	"Play Solitaire or die!": "Jogue Paciência ou morra!",

	# ══════════════════════════════════════════════════════════════════════════
	#  End / game-over screen
	# ══════════════════════════════════════════════════════════════════════════
	"You Escaped the Tower": "Você escapou da Torre",
	"The Tower Keeps You": "A Torre fica com você",
	"Local High Scores": "Melhores pontuações locais",
	"No runs recorded yet.": "Nenhuma partida registrada ainda.",
	"Your name": "Seu nome",
	"RECORD SCORE": "REGISTRAR PONTUAÇÃO",
	"NEW RUN": "NOVA PARTIDA",
	"TITLE": "MENU INICIAL",
	"★ %d pts    ⏳ %d credits    %d/%d floors    %s": "★ %d pts    ⏳ %d créditos    %d/%d andares    %s",
	"%d pts": "%d pts",

	# ══════════════════════════════════════════════════════════════════════════
	#  Misc / toasts
	# ══════════════════════════════════════════════════════════════════════════
	"Save reset: %s": "Save reiniciado: %s",

	# ══════════════════════════════════════════════════════════════════════════
	#  Patron coach — the rule named aloud when the table refuses a move
	# ══════════════════════════════════════════════════════════════════════════
	"No dealing while a column stands empty. Fill every gap first, then the stock will give.": "Nada de distribuir enquanto houver uma coluna vazia. Preencha primeiro cada vão e o monte cederá.",
	"The stock is spent — what lies on the table is all that remains.": "O monte acabou — o que está na mesa é tudo o que resta.",
	"A foundation takes one card at a time, never a run.": "Uma fundação recebe uma carta de cada vez, nunca uma sequência.",
	"Each foundation keeps to a single suit — that pile is not yours to fill.": "Cada fundação atém-se a um único naipe — essa pilha não é sua para preencher.",
	"Foundations climb from the Ace upward, one rank at a time.": "As fundações sobem a partir do Ás, um grau de cada vez.",
	"A free cell holds a single card, and that one is taken.": "Uma célula livre guarda uma só carta, e essa já está ocupada.",
	"A card only lands on the rank just above it. Suit matters when you lift a run, not when you place one.": "Uma carta só assenta sobre o grau imediatamente acima. O naipe importa ao levantar uma sequência, não ao pousá-la.",
	"Columns run down in alternating colours — red on black, black on red.": "As colunas descem alternando as cores — vermelho sobre preto, preto sobre vermelho.",
	"Only a King may open an empty column.": "Só um Rei pode abrir uma coluna vazia.",
	"The tableau runs down in alternating colours — red on black, black on red.": "O tableau desce alternando as cores — vermelho sobre preto, preto sobre vermelho.",
	"That card lies face down. Clear the cards above it and it will turn.": "Essa carta está virada para baixo. Limpe as que estão por cima e ela virará.",
	"Only a run descending in one suit travels as a block. A mixed run moves one card at a time.": "Só uma sequência descendente do mesmo naipe viaja em bloco. Uma sequência misturada avança carta a carta.",
	"A run travels whole only while it descends in alternating colours.": "Uma sequência viaja inteira apenas enquanto desce alternando as cores.",
	"You can carry %d cards at once, not %d — each free cell and each empty column raises the count.": "Pode levar %d cartas de cada vez, não %d — cada célula livre e cada coluna vazia aumentam esse número.",
	"That card is still covered. Clear the two below it first.": "Essa carta ainda está coberta. Limpe primeiro as duas que a bloqueiam.",
	"Take only a card one rank above or below the waste. The Ace bridges King and Two.": "Tire apenas uma carta um grau acima ou abaixo do descarte. O Ás liga o Rei ao Dois.",
	"Pair cards that add to thirteen. A King is worth thirteen alone.": "Emparelhe cartas que somem treze. Um Rei vale treze sozinho.",
	"Nowhere for that card to go. Deal a new row once every column holds a card.": "Essa carta não tem para onde ir. Distribua uma nova fila assim que cada coluna tiver uma carta.",
	"Nowhere for that card to go — park it in a free cell and dig deeper.": "Essa carta não tem para onde ir — guarde-a numa célula livre e escave mais fundo.",
	"Nowhere for that card to go. Draw from the stock and come back to it.": "Essa carta não tem para onde ir. Compre do monte e volte a ela.",
	"Nowhere for that card to go just now.": "Essa carta não tem para onde ir por agora.",

	"Interface Size": "Tamanho da interface",

	# ══════════════════════════════════════════════════════════════════════════
	#  Patron coach — the corner controls and the How to play briefings
	# ══════════════════════════════════════════════════════════════════════════
	"HOW TO PLAY": "COMO JOGAR",
	"MUTE": "SILENCIAR",
	"MUTED": "SILENCIADO",
	"Klondike. Four foundations, one suit each, climbing Ace to King — fill all four and the floor is yours.\n• The tableau runs down in alternating colours: red on black, black on red.\n• Only a King may open an empty column.\n• Draw from the stock to the waste and play the waste's top card.\n• Clearing the cards above a face-down one turns it over.": "Klondike. Quatro fundações, uma por naipe, subindo do Ás ao Rei — complete as quatro e o andar é seu.\n• O tableau desce alternando as cores: vermelho sobre preto, preto sobre vermelho.\n• Só um Rei pode abrir uma coluna vazia.\n• Compre do monte para o descarte e jogue a carta do topo do descarte.\n• Limpar as cartas que cobrem uma carta virada para baixo faz com que ela vire.",
	"Spider. Eight runs, King down to Ace in a single suit; each run you finish leaves the table.\n• A card lands on the rank just above it, whatever the suit.\n• Only a run already in one suit travels as a block — a mixed one moves card by card.\n• Deal ten more cards when you are stuck, but never while a column stands empty.\n• Clear all eight runs to win.": "Spider. Oito sequências, do Rei ao Ás num mesmo naipe; cada sequência concluída deixa a mesa.\n• Uma carta assenta sobre o grau imediatamente acima, seja qual for o naipe.\n• Só uma sequência já de um mesmo naipe viaja em bloco — uma misturada avança carta a carta.\n• Distribua mais dez cartas quando estiver travado, mas nunca enquanto houver uma coluna vazia.\n• Complete as oito sequências para vencer.",
	"FreeCell. Every card is face up from the first move, and every deal can be won. Build four foundations, Ace to King, one suit each.\n• Columns run down in alternating colours: red on black, black on red.\n• Each free cell parks a single card.\n• One move carries (free cells + 1) cards, doubled for every empty column.\n• Nothing is hidden. The whole puzzle is in front of you from the start.": "FreeCell. Todas as cartas estão viradas para cima desde a primeira jogada, e toda partida tem solução. Construa quatro fundações, do Ás ao Rei, uma por naipe.\n• As colunas descem alternando as cores: vermelho sobre preto, preto sobre vermelho.\n• Cada célula livre acomoda uma só carta.\n• Uma jogada transporta (células livres + 1) cartas, e esse número dobra a cada coluna vazia.\n• Nada está escondido. O quebra-cabeça inteiro está à sua frente desde o início.",
	"TriPeaks. Clear all twenty-eight cards from the three peaks.\n• Take any uncovered card one rank above or below the top of the waste.\n• The Ace bridges King and Two, so a chain never has to stop there.\n• A card is uncovered once the two below it are gone.\n• Draw from the stock when nothing fits — it breaks your chain, and a long chain scores far more.": "TriPeaks. Limpe as vinte e oito cartas dos três picos.\n• Tire qualquer carta descoberta um grau acima ou abaixo do topo do descarte.\n• O Ás liga o Rei ao Dois, por isso uma corrente nunca precisa parar aí.\n• Uma carta fica descoberta assim que as duas abaixo dela desaparecem.\n• Compre do monte quando nada servir — isso quebra a sua corrente, e uma corrente longa pontua muito mais.",
	"Pyramid. Clear every card of the pyramid by pairing them to thirteen.\n• The Ace counts one, the Jack eleven, the Queen twelve, the King thirteen.\n• A King is thirteen on its own and clears alone.\n• Only an uncovered card can be paired: the two below it must go first.\n• Pair with the top of the waste, or turn the stock for a new one.": "Pyramid. Limpe todas as cartas da pirâmide emparelhando-as para somar treze.\n• O Ás vale um, o Valete onze, a Dama doze, o Rei treze.\n• Um Rei vale treze sozinho e sai sozinho.\n• Só uma carta descoberta pode ser emparelhada: as duas abaixo dela têm de sair primeiro.\n• Emparelhe com o topo do descarte, ou compre do monte para descobrir outra.",
}
