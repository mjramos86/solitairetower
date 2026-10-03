extends RefCounted

## English → Latin American Spanish (es-419) translations, keyed by the exact
## English source string used at the call site. Locale.t() looks strings up here
## when the language is Spanish; a missing key falls back to the English source,
## so partial coverage is safe.
##
## Register: John Dee addresses the player with "usted" (period-appropriate and
## matching the French "vous"); UI copy stays neutral. Latin American vocabulary
## throughout — no "vosotros", no Spain-only terms.
##
## Keep keys byte-for-byte identical to the source (including the curly
## apostrophe ’, guillemets « », em dash —, ellipsis …, and \n line breaks).

const MAP := {
	# ══════════════════════════════════════════════════════════════════════════
	#  UI — title, menus, common buttons
	# ══════════════════════════════════════════════════════════════════════════
	"LOAD GAME": "CARGAR",
	"NEW GAME": "NUEVA PARTIDA",
	"HIGH SCORES": "MEJORES PUNTAJES",
	"EXIT GAME": "SALIR",
	"📊 Statistics": "📊 Estadísticas",
	"STATISTICS": "ESTADÍSTICAS",
	"Run Stats": "Estadísticas de descenso",
	"Runs Played": "Descensos jugados",
	"Runs Won": "Descensos ganados",
	"Win Rate": "Tasa de victoria",
	"Best Score": "Mejor puntaje",
	"Best Time": "Mejor tiempo",
	"Total Score": "Puntaje total",
	"Game Stats": "Estadísticas de juego",
	"Games Played": "Partidas jugadas",
	"Games Won": "Partidas ganadas",
	"By Variant": "Por variante",
	"Variant": "Variante",
	"Played": "Jugadas",
	"Won": "Ganadas",
	"Win %": "Vict. %",
	"OPTIONS": "OPCIONES",
	"CREDITS": "CRÉDITOS",
	"Options": "Opciones",
	"Game Design, Art & Writing": "Diseño, arte y guion",
	"aka Emjayhar": "alias Emjayhar",
	"AI tools were used to assist with the game's source code.": "Se usaron herramientas de IA para apoyar el código fuente del juego.",
	"Music": "Música",
	"Made With": "Hecho con",
	"Fonts": "Tipografías",
	"Licensed under the SIL Open Font License": "Bajo licencia SIL Open Font License",
	"All rights reserved.": "Todos los derechos reservados.",
	"Solitaire Tower of Doom™ is a trademark of Mario Jorge Ramos.": "Solitaire Tower of Doom™ es una marca de Mario Jorge Ramos.",
	"Back": "Volver",
	"Back ▸": "Volver ▸",
	"◂ Back": "◂ Volver",
	"Done": "Listo",
	"Cancel": "Cancelar",
	"Continue ▸": "Continuar ▸",
	"Begin": "Comenzar",
	"Skip ▸▸": "Saltar ▸▸",
	"Language": "Idioma",
	"Audio": "Audio",
	"♪  Music": "♪  Música",
	"🔊  Sound Effects": "🔊  Efectos de sonido",
	"🔊  Sound": "🔊  Sonido",
	"🔊 Sound": "🔊 Sonido",

	# ══════════════════════════════════════════════════════════════════════════
	#  Map / tower hub
	# ══════════════════════════════════════════════════════════════════════════
	"Royalty-free music from Pixabay.com": "Música libre de regalías de pixabay.com",
	"A narrative horror roguelike Solitaire by Emjayhar": "Un Solitario roguelike, narrativo y de horror, por Emjayhar",
	"Face the Cult of Patience and uncover the occult secret history of Solitaire": "Enfrenta al Culto de la Paciencia y descubre la historia secreta y oculta del Solitario",
	"PLAYER": "JUGADOR",
	"LIVES": "VIDAS",
	"Player": "Jugador",
	"Lives": "Vidas",
	"🏆 HIGH SCORES": "🏆 MEJORES PUNTAJES",
	"Time Patron": "Mecenas del Tiempo",
	"Time Credits": "Créditos Temporales",
	"Time Energy": "Energía Temporal",
	"🎒 Inventory": "🎒 Inventario",
	"[ EMPTY ]": "[ VACÍO ]",
	"Lore": "Saber",
	"📖 Compendium": "📖 Compendio",
	"Customize": "Personalizar",
	"🂠 Cardback": "🂠 Reverso",
	"▶ Watch Intro": "▶ Ver la intro",
	"🏠 Main Menu": "🏠 Menú principal",
	"⚑ New Run": "⚑ Nuevo descenso",
	"HIGH SCORES ": "MEJORES PUNTAJES ",
	"🏆 High Scores": "🏆 Mejores puntajes",
	"New Run": "Nuevo descenso",
	"Start a New Run?\n\nThis ends your current descent — the rest of your lives are forfeit and your run is scored now.": "¿Comenzar un nuevo descenso?\n\nEsto termina tu descenso actual: pierdes las vidas que te quedan y tu partida se puntúa ahora.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Game screen — HUD, toolbar, status, overlays
	# ══════════════════════════════════════════════════════════════════════════
	"↩ Undo (%d)": "↩ Deshacer (%d)",
	"⟳ Shuffle": "⟳ Rebarajar",
	"⏸ Pause": "⏸ Pausa",
	"✕ Abandon": "✕ Abandonar",
	"Floor %d of %d": "Piso %d de %d",
	"%d/%d floors": "%d/%d pisos",
	"★ %d pts": "★ %d pts",
	"Paused": "En pausa",
	"Resume": "Reanudar",
	"Restart Floor": "Reiniciar el piso",
	"Abandon Run": "Abandonar el descenso",
	"Re-deal this floor with a fresh shuffle?\n\nYou will lose a life.": "¿Repartir este piso con una nueva mezcla?\n\nPerderás una vida.",
	"Abandon this floor?\n\nYou will lose a life and return to the map.": "¿Abandonar este piso?\n\nPerderás una vida y volverás al mapa.",
	"Floor Cleared!": "¡Piso superado!",
	"You Win!": "¡Victoria!",
	"No moves left": "No quedan movimientos",
	"No legal move": "Movimiento no permitido",
	"Descend ▸": "Descender ▸",
	"CHEAT: floor cleared": "TRUCO: piso superado",
	"CHEAT: inventory rerolled": "TRUCO: inventario resorteado",
	"Recorded at #%d": "Registrado en el puesto n.º %d",

	# ══════════════════════════════════════════════════════════════════════════
	#  Variant names & rules
	# ══════════════════════════════════════════════════════════════════════════
	"Spider": "Spider",
	"Pyramid": "Pirámide",
	# (Klondike, FreeCell, TriPeaks keep their names in Spanish.)
	"Build 4 foundation piles A→K by suit": "Construye 4 fundaciones del As al Rey por palo",
	"Tableau: descending rank, alternating colour": "Tableau: valor descendente, colores alternados",
	"Draw from stock to waste; move waste top card to play": "Roba del mazo al descarte; juega la carta superior del descarte",
	"Flip hidden cards by clearing cards above them": "Voltea las cartas ocultas quitando las que están encima",
	"All cards dealt face-up — every deal is solvable": "Todas las cartas boca arriba: todo reparto tiene solución",
	"Build foundations A→K by suit": "Construye las fundaciones del As al Rey por palo",
	"Use free cells as temporary card parking": "Usa las celdas libres para estacionar cartas temporalmente",
	"Pair cards that sum to 13 (A=1, J=11, Q=12, K=13)": "Empareja cartas que sumen 13 (A=1, J=11, Q=12, K=13)",
	"Kings are removed alone": "Los Reyes se retiran solos",
	"Use the waste top to pair with pyramid cards": "Usa la carta superior del descarte para emparejar con la pirámide",
	"Clear all pyramid cards to win": "Retira todas las cartas de la pirámide para ganar",
	"Build complete K→A sequences of the same suit": "Construye secuencias completas del Rey al As del mismo palo",
	"Completed sequences removed to foundations": "Las secuencias completas pasan a las fundaciones",
	"Deal 10 new cards from stock when stuck": "Reparte 10 cartas nuevas del mazo cuando te atasques",
	"Clear all 8 sequences to win": "Completa las 8 secuencias para ganar",
	"Play cards +1 or -1 rank from waste top (A↔K wrap)": "Juega cartas de valor +1 o -1 respecto al descarte (el As y el Rey se enlazan)",
	"Click pyramid cards to chain onto the waste": "Haz clic en las cartas de la pirámide para encadenarlas al descarte",
	"Draw from stock when no move available": "Roba del mazo cuando no haya movimiento posible",
	"Clear all 28 pyramid cards to win": "Retira las 28 cartas de la pirámide para ganar",

	# ══════════════════════════════════════════════════════════════════════════
	#  Shop
	# ══════════════════════════════════════════════════════════════════════════
	"The Merchant": "El Mercader",
	"Shop": "Tienda",
	"Buy": "Comprar",
	"Owned": "Adquirido",
	"Sold Out": "Agotado",
	"Can't afford": "Saldo insuficiente",
	"Descend to the next floor ▸": "Descender al siguiente piso ▸",
	"⏳ %d": "⏳ %d",
	"Floor Rewards": "Recompensas del piso",
	"⏳  Floor %d Cleared — Time Credits Awarded": "⏳  Piso %d superado — Créditos Temporales otorgados",
	"🏪  John Dee's Cabinet of Curiosities — %d Items Available": "🏪  El Gabinete de Curiosidades de John Dee — %d objetos disponibles",
	"🎒  Your Inventory (%d/%d slots)": "🎒  Tu inventario (%d/%d espacios)",
	"Floor Cleared": "Piso superado",
	"No Undos": "Sin deshacer",
	"Under 3 min": "Menos de 3 min",
	"Full Lives": "Vidas intactas",
	"Score Bonus": "Bono de puntos",
	"TOTAL EARNED": "TOTAL GANADO",
	"YOUR BALANCE": "TU SALDO",
	"CHEAP": "BARATO",
	"MEDIUM": "MEDIO",
	"PRICEY": "COSTOSO",
	"RARE": "RARO",

	# ── item names ──
	"Scrying Glass": "Cristal de Videncia",
	"Knotted Cord": "Cuerda de Nudos",
	"Mortlake Brew": "Brebaje de Mortlake",
	"Quill of Ravens": "Pluma de Cuervos",
	"Sealing Wax": "Lacre",
	"Athame": "Athame",
	"Obsidian Mirror": "Espejo de Obsidiana",
	"Wax Seal Press": "Prensa de Sellos",
	"Philosopher's Sponge": "Esponja del Filósofo",
	"Sealed Letter": "Carta Sellada",
	"Brass Compass": "Brújula de Latón",
	"Astrolabe": "Astrolabio",
	"Hermetic Casket": "Cofre Hermético",
	"Skeleton Key": "Llave Maestra",
	"Alchemist's Cabinet": "Gabinete del Alquimista",
	"Angelic Besom": "Escoba Angelical",
	"Enochian Key": "Llave Enoquiana",
	"Vial of Quicksilver": "Vial de Azogue",
	"Queen's Patronage": "Favor de la Reina",

	# ── item descriptions ──
	"Highlights one valid move on the board.": "Resalta un movimiento válido en el tablero.",
	"You only get 3 undos per floor. This adds 5 more.": "Solo tienes 3 deshacer por piso. Esto añade 5 más.",
	"Draw 1 extra card from stock for free.": "Roba 1 carta extra del mazo gratis.",
	"Peek at the top 3 cards in the stock pile.": "Echa un vistazo a las 3 primeras cartas del mazo.",
	"Get one free waste→stock recycle.": "Obtén un reciclaje descarte→mazo gratis.",
	"Remove any one face-up card from the board entirely.": "Retira por completo del tablero cualquier carta boca arriba.",
	"Reveal all face-down cards for 8 seconds.": "Revela todas las cartas boca abajo durante 8 segundos.",
	"Digs an Ace out from anywhere — even buried or face-down — and sends it to its foundation.": "Desentierra un As desde cualquier parte —incluso sepultado o boca abajo— y lo envía a su fundación.",
	"Mega-undo: rewind up to 10 moves at once.": "Mega-deshacer: retrocede hasta 10 movimientos de una vez.",
	"Shuffle waste back into stock for free.": "Rebaraja el descarte dentro del mazo gratis.",
	"Flip any face-down tableau card face-up.": "Voltea boca arriba cualquier carta oculta del tableau.",
	"Flash ALL valid moves for 8 seconds.": "Muestra TODOS los movimientos válidos durante 8 segundos.",
	"Bring any buried waste card to the top to play next.": "Lleva cualquier carta sepultada del descarte a la cima para jugarla.",
	"Unlock a 5th free cell for this entire floor.": "Desbloquea una 5.ª celda libre durante todo el piso.",
	"Creates a temporary off-board card stash (1 card, 8 uses).": "Crea un escondite temporal fuera del tablero (1 carta, 8 usos).",
	"Sweep the top card of any pile to the first empty column.": "Barre la carta superior de cualquier pila a la primera columna vacía.",
	"Pull any card from stock to the top of the waste pile.": "Saca cualquier carta del mazo a la cima del descarte.",
	"Abandon this floor without losing a life.": "Abandona este piso sin perder una vida.",
	"Skip this floor entirely -- counts as cleared!": "¡Sáltate este piso por completo: cuenta como superado!",

	# ── item use hints ──
	"Instant: glows on valid source & target.": "Instantáneo: ilumina origen y destino válidos.",
	"Instant: adds 5 undos to your budget.": "Instantáneo: añade 5 deshacer a tu reserva.",
	"Instant: free stock draw.": "Instantáneo: robo gratis del mazo.",
	"Shows a 6-second preview window.": "Muestra una ventana de vista previa de 6 segundos.",
	"Instant: recycles without counting.": "Instantáneo: recicla sin contar.",
	"Click mode: pick a card to vanish it.": "Modo clic: elige una carta para hacerla desaparecer.",
	"Instant: temporary x-ray vision.": "Instantáneo: visión de rayos X temporal.",
	"Instant: finds an Ace anywhere.": "Instantáneo: encuentra un As donde sea.",
	"Instant: pops 10 undo states.": "Instantáneo: deshace hasta 10 movimientos de golpe.",
	"Instant: free recycle.": "Instantáneo: reciclaje gratis.",
	"Click mode: pick a face-down card.": "Modo clic: elige una carta boca abajo.",
	"Instant: full board hint glow.": "Instantáneo: ilumina todo el tablero.",
	"Opens waste picker -- select a card.": "Abre el selector de descarte: elige una carta.",
	"Instant: adds a free cell slot.": "Instantáneo: añade una celda libre.",
	"Drag any card in/out of the stash.": "Arrastra cualquier carta dentro/fuera del escondite.",
	"Click mode: pick a source pile top.": "Modo clic: elige la cima de una pila de origen.",
	"Opens stock browser -- pick your card.": "Abre el explorador del mazo: elige tu carta.",
	"Instant: safe retreat to the map.": "Instantáneo: retirada segura al mapa.",
	"Instant: auto-win current floor.": "Instantáneo: victoria automática en el piso actual.",

	# ── item best_for ──
	"All games": "Todos los juegos",
	"Klondike · TriPeaks": "Klondike · TriPeaks",
	"Klondike · Pyramid": "Klondike · Pirámide",
	"Pyramid · TriPeaks": "Pirámide · TriPeaks",
	"Spider · Klondike": "Spider · Klondike",
	"Klondike · FreeCell": "Klondike · FreeCell",
	"FreeCell": "FreeCell",
	"Spider · FreeCell · Klondike": "Spider · FreeCell · Klondike",
	"Spider · FreeCell": "Spider · FreeCell",
	"All games (emergency!)": "Todos los juegos (¡emergencia!)",
	"All games (boss skip!)": "Todos los juegos (¡saltarse al jefe!)",

	# ══════════════════════════════════════════════════════════════════════════
	#  Cardbacks
	# ══════════════════════════════════════════════════════════════════════════
	"The Solitaire Tower": "La Torre del Solitario",
	"The King of Hearts": "El Rey de Corazones",
	"John Dee's portrait": "Retrato de John Dee",
	"Mary Stuart's portrait": "Retrato de Mary Estuardo",

	# ══════════════════════════════════════════════════════════════════════════
	#  Patron select
	# ══════════════════════════════════════════════════════════════════════════
	"Choose Your Time Patron": "Elige tu Mecenas del Tiempo",
	"An ally for this descent, lending their nature to the wares you can purchase along the way.": "Un aliado para este descenso, que presta su naturaleza a los objetos que podrás comprar en el camino.",
	"Select John Dee to begin your descent.": "Elige a John Dee para comenzar tu descenso.",
	"🔒": "🔒",

	# ══════════════════════════════════════════════════════════════════════════
	#  Cardback select
	# ══════════════════════════════════════════════════════════════════════════
	"Choose Your Cardback": "Elige tu reverso",
	"Locked designs are revealed by uncovering a Time Patron's connection to Solitaire in the Compendium.": "Los diseños bloqueados se revelan al descubrir, en el Compendio, el vínculo de un Mecenas del Tiempo con el Solitario.",
	"← Back to Tower": "← Volver a la Torre",

	# ══════════════════════════════════════════════════════════════════════════
	#  Slots
	# ══════════════════════════════════════════════════════════════════════════
	"SLOT %d": "RANURA %d",
	"No run in progress": "Ningún descenso en curso",
	"— Empty —": "— Vacío —",
	"⚡ %d   ✓ %d": "⚡ %d   ✓ %d",

	# ══════════════════════════════════════════════════════════════════════════
	#  High scores
	# ══════════════════════════════════════════════════════════════════════════
	"⟳ Sync now": "⟳ Sincronizar",
	"No scores to show yet.": "Aún no hay puntajes que mostrar.",
	"Local": "Local",
	"Online": "En línea",

	# ══════════════════════════════════════════════════════════════════════════
	#  Compendium — dynamic bits
	# ══════════════════════════════════════════════════════════════════════════
	"⚡ Time Energy: %d": "⚡ Energía Temporal: %d",
	"🔒  Unknown Patron": "🔒  Mecenas desconocido",
	"TIMELINE OF CIVILIZATION": "CRONOLOGÍA DE LA CIVILIZACIÓN",
	"No connections to the historical record have been uncovered yet.": "Aún no se ha descubierto ningún vínculo con el registro histórico.",
	"UNCOVER (%d ⚡)": "REVELAR (%d ⚡)",
	"You: ": "Tú: ",
	"⚙ This Time Patron is still in development and cannot yet be selected.": "⚙ Este Mecenas del Tiempo sigue en desarrollo y aún no puede elegirse.",
	"Unknown Patron": "Mecenas desconocido",
	"You": "Tú",
	"Strategy": "Estrategia",
	"Connection to Solitaire": "Vínculo con el Solitario",
	"This Time Patron has not yet revealed themselves to you.": "Este Mecenas del Tiempo aún no se te ha revelado.",
	"The First Contact": "El primer contacto",
	"A Moment's Respite": "Un momento de respiro",
	"More Than Halfway": "Más de la mitad",
	"The Final Threshold": "El umbral final",
	"The Compendium": "El Compendio",
	"← Prev": "← Ant.",
	"Next →": "Sig. →",
	"NEED %d MORE ⚡": "FALTAN %d ⚡",
	"Online ✓": "En línea ✓",

	# ══════════════════════════════════════════════════════════════════════════
	#  Game screen — HUD, overlays, item card, score ledger
	# ══════════════════════════════════════════════════════════════════════════
	"Solitaire Tower of Doom · Early Access v%s": "Solitaire Tower of Doom · Acceso anticipado v%s",
	"Solitaire Tower of Doom — %s (Floor %d)": "Solitaire Tower of Doom — %s (Piso %d)",
	"Floor %d of 10": "Piso %d de 10",
	"🚪 ESCAPED!": "🚪 ¡ESCAPASTE!",
	"✅ FLOOR CLEARED": "✅ PISO SUPERADO",
	"You burst into the streets! You are FREE!": "¡Irrumpes en las calles! ¡Eres LIBRE!",
	"Staircase found. Descending…": "Escalera encontrada. Descendiendo…",
	"[ ESCAPE ]": "[ ESCAPAR ]",
	"[ DESCEND ]": "[ DESCENDER ]",
	"⏸ PAUSED": "⏸ EN PAUSA",
	"▶ Continue": "▶ Continuar",
	"★ Score History — Floor %d": "★ Historial de puntos — Piso %d",
	"No scoring events this floor yet.": "Aún no hay puntos anotados en este piso.",
	"Close": "Cerrar",
	"🗄️ stash empty (%d)": "🗄️ escondite vacío (%d)",

	# ══════════════════════════════════════════════════════════════════════════
	#  Shop — buttons & states
	# ══════════════════════════════════════════════════════════════════════════
	"Best for: %s": "Ideal para: %s",
	"[ ALREADY OWNED ]": "[ YA ADQUIRIDO ]",
	"[ INVENTORY FULL ]": "[ INVENTARIO LLENO ]",
	"[ NEED %d MORE ⏳ ]": "[ FALTAN %d ⏳ ]",
	"[ BUY ]": "[ COMPRAR ]",
	"⚠ Inventory full! Use or drop items in-game.": "⚠ ¡Inventario lleno! Usa o descarta objetos durante la partida.",
	"[ empty ]": "[ vacío ]",
	"⚔  Continue to the Tower": "⚔  Seguir hacia la Torre",
	"Acquired %s": "%s adquirido",

	# ══════════════════════════════════════════════════════════════════════════
	#  Compendium — headings
	# ══════════════════════════════════════════════════════════════════════════
	"Compendium": "Compendio",
	"Time Patrons": "Mecenas del Tiempo",
	"Adversaries": "Adversarios",
	"Connections": "Conexiones",
	"Recorded Transmissions": "Transmisiones registradas",
	"Locked": "Bloqueado",
	"Unlock": "Desbloquear",
	"Reveal": "Revelar",
	"In development": "En desarrollo",
	"Under development": "En desarrollo",

	# ══════════════════════════════════════════════════════════════════════════
	#  Patrons & lore (compendium prose)
	# ══════════════════════════════════════════════════════════════════════════
	"The Other Queen": "La Otra Reina",
	"The Sun King": "El Rey Sol",
	"The Old Lion": "El Viejo León",
	"The Emperor": "El Emperador",
	"The Prisoner": "El Prisionero",
	"Mary, Queen of Scots": "María, Reina de los Escoceses",
	"Elizabeth I's astrologer and master spy": "Astrólogo y maestro espía de Isabel I",
	"Queen of Scots, England's royal prisoner": "Reina de los Escoceses, prisionera real de Inglaterra",
	"The astrologer trades in sight — see what is hidden, know what approaches.": "El astrólogo comercia con la visión: ve lo que está oculto, sabe lo que se aproxima.",
	"The Cult of Patience": "El Culto de la Paciencia",
	"The Digitization Strategy": "La estrategia de digitalización",

	"John Dee was the most accomplished intellectual of Elizabethan England — a mathematician, cartographer, astronomer, and the personal astrologer of Queen Elizabeth I. It was Dee who calculated the most auspicious date for her coronation. His library at Mortlake was the largest private collection in England, until a mob ransacked it.": "John Dee fue el intelectual más completo de la Inglaterra isabelina: matemático, cartógrafo, astrónomo y astrólogo personal de la reina Isabel I. Fue Dee quien calculó la fecha más propicia para su coronación. Su biblioteca de Mortlake era la mayor colección privada de Inglaterra, hasta que una turba la saqueó.",
	"He spent years trying to communicate with angels through a crystal ball and a medium named Edward Kelley, recording these conversations in an elaborate cipher. His notation system; Enochian, the supposed language of angels, became a cornerstone of Western occultism.": "Pasó años intentando comunicarse con ángeles mediante una bola de cristal y un médium llamado Edward Kelley, registrando esas conversaciones en una cifra elaborada. Su sistema de notación, el enoquiano, supuesta lengua de los ángeles, se volvió una piedra angular del ocultismo occidental.",
	"Dee also traveled undercover as an intelligence agent for Elizabeth's court. He signed his correspondence to the queen \"007\". The two zeros representing a spy's watching eyes, the seven a lucky number.": "Dee también viajó de incógnito como agente de inteligencia de la corte de Isabel. Firmaba su correspondencia a la reina como \"007\". Los dos ceros representaban los ojos vigilantes de un espía, y el siete era un número de buena suerte.",
	"Legend has it that Dee visited Mary, Queen of Scots during her captivity, perhaps at Chartley or Fotheringhay, and taught her a card layout he presented as a method of divination. The game was supposedly meant to occupy her mind through the long nights before her execution.": "Cuenta la leyenda que Dee visitó a María, Reina de los Escoceses, durante su cautiverio, quizá en Chartley o en Fotheringhay, y le enseñó una disposición de cartas que presentó como método de adivinación. Se supone que el juego servía para ocupar su mente durante las largas noches previas a su ejecución.",
	"More deeply, Dee believed the universe itself was encoded, that behind the apparent randomness of the cards lay a divine mathematical order. He was one of the first to suspect that the Sacred Shuffle is a source of immense power.": "Más hondamente, Dee creía que el universo mismo estaba codificado, que tras la aparente aleatoriedad de las cartas yacía un orden matemático divino. Fue de los primeros en sospechar que la Mezcla Sagrada es fuente de un poder inmenso.",

	"Mary became Queen of Scotland when she was just six days old, after her father, James V, died in 1542. Because she was an infant, Scotland was ruled by regents while Mary spent much of her childhood in France, where she was raised at the French court and eventually married the Dauphin, François. When he became King of France in 1559, Mary was briefly Queen of both Scotland and France, but François died only a year later, in 1560, leaving her a widow at eighteen.": "María fue Reina de Escocia con apenas seis días de vida, tras la muerte de su padre, Jacobo V, en 1542. Por ser una bebé, Escocia fue gobernada por regentes mientras María pasaba buena parte de su infancia en Francia, criada en la corte francesa y casada finalmente con el delfín Francisco. Cuando él fue Rey de Francia en 1559, María fue brevemente Reina de Escocia y de Francia, pero Francisco murió apenas un año después, en 1560, dejándola viuda a los dieciocho.",
	"Mary returned to Scotland in 1561 to rule in person, landing in a country deeply divided by the Protestant Reformation, while she herself remained Catholic. Her reign was turbulent: she married her cousin Henry Stuart, Lord Darnley, in 1565, and the marriage quickly soured amid political plotting and violence, including Darnley's involvement in the murder of Mary's secretary, David Rizzio. Darnley himself was murdered in 1567, and Mary's swift marriage afterward to James Hepburn, Earl of Bothwell, widely suspected in Darnley's death, scandalized the nobility and triggered a rebellion.": "María regresó a Escocia en 1561 para gobernar en persona, llegando a un país hondamente dividido por la Reforma protestante, mientras ella seguía siendo católica. Su reinado fue turbulento: se casó con su primo Enrique Estuardo, lord Darnley, en 1565, y el matrimonio se agrió pronto entre intrigas políticas y violencia, incluida la participación de Darnley en el asesinato del secretario de María, David Rizzio. El propio Darnley fue asesinado en 1567, y el apresurado matrimonio posterior de María con Jacobo Hepburn, conde de Bothwell, ampliamente sospechoso de la muerte de Darnley, escandalizó a la nobleza y desató una rebelión.",
	"Forced to abdicate in favor of her infant son (who became James VI of Scotland, and later James I of England), Mary fled to England in 1568, seeking the protection of her cousin, Queen Elizabeth I. Instead, Elizabeth had her held in a long series of confinements lasting nearly two decades. Mary became a magnet for Catholic plots aiming to depose Elizabeth and place Mary on the English throne; most damningly the Babington Plot of 1586, in which intercepted letters appeared to show Mary endorsing Elizabeth's assassination. Tried and convicted of treason, Mary was executed at Fotheringhay Castle in February 1587.": "Obligada a abdicar en favor de su hijo aún bebé (que llegó a ser Jacobo VI de Escocia y, más tarde, Jacobo I de Inglaterra), María huyó a Inglaterra en 1568 buscando la protección de su prima, la reina Isabel I. En cambio, Isabel la mantuvo en una larga serie de encierros que duró casi dos décadas. María se volvió un imán para conspiraciones católicas que buscaban deponer a Isabel y ponerla a ella en el trono inglés; la más incriminatoria fue la Conspiración de Babington, de 1586, en la que unas cartas interceptadas parecían mostrar a María respaldando el asesinato de Isabel. Juzgada y condenada por traición, María fue ejecutada en el castillo de Fotheringhay en febrero de 1587.",
	"Her son James VI later united the crowns of Scotland and England as James I, making Mary, in a sense, the ancestress of the joint British monarchy; a final ironic twist to a reign defined by intrigue, religious conflict, and tragedy.": "Su hijo Jacobo VI unió más tarde las coronas de Escocia e Inglaterra como Jacobo I, lo que hace de María, en cierto sentido, la antepasada de la monarquía británica unificada; una última ironía para un reinado marcado por la intriga, el conflicto religioso y la tragedia.",

	"The Cult of Patience is an organization whose origins date back at least to the 17th century, perhaps further. Its members share one core conviction: the Sacred Shuffle exists, it is attainable, and whoever possesses it possesses time itself.": "El Culto de la Paciencia es una organización cuyos orígenes se remontan al menos al siglo XVII, quizá más atrás. Sus miembros comparten una convicción central: la Mezcla Sagrada existe, es alcanzable, y quien la posea posee el tiempo mismo.",
	"Unlike the Time Patrons, who guard the secret out of caution and respect, the Cult wants it for domination. They do not seek to understand Solitaire, they seek to exploit it.": "A diferencia de los Mecenas del Tiempo, que guardan el secreto por cautela y respeto, el Culto lo quiere para dominar. No buscan comprender el Solitario, buscan explotarlo.",
	"The digitization of Solitaire in the 1990s was seen by the Cult as a historic windfall. For the first time, millions of games could be played simultaneously, by ordinary people, unaware of what they were searching for.": "La digitalización del Solitario en los años noventa fue vista por el Culto como una fortuna histórica. Por primera vez, millones de partidas podían jugarse simultáneamente, por gente común, sin saber qué buscaban.",
	"Their current plan is brutally simple: seize a building, an office tower, a building full of office workers, and force its occupants to play Solitaire continuously, around the clock. By the sheer law of large numbers, the Sacred Shuffle will eventually appear on one of the screens.": "Su plan actual es de una simplicidad brutal: tomar un edificio, una torre de oficinas, un edificio lleno de empleados, y obligar a sus ocupantes a jugar al Solitario sin descanso, día y noche. Por la simple ley de los grandes números, la Mezcla Sagrada acabará apareciendo en una de las pantallas.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — shared chrome
	# ══════════════════════════════════════════════════════════════════════════
	"📞  Incoming Transmission -- John Dee": "📞  Transmisión entrante -- John Dee",
	"What would you like to ask?": "¿Qué te gustaría preguntar?",
	"That's all for now.": "Eso es todo por ahora.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — victory
	# ══════════════════════════════════════════════════════════════════════════
	"You have shown why you were chosen by the Sacred Shuffle. I am afraid, though, this journey is only beginning.": "Ha demostrado por qué la Mezcla Sagrada lo eligió. Me temo, sin embargo, que este viaje apenas comienza.",
	"Our victory over the Cult of Doom will only be complete when all Time Patrons are revealed.": "Nuestra victoria sobre el Culto de la Perdición solo será completa cuando todos los Mecenas del Tiempo sean revelados.",
	"Alright, reset time!": "¡Bien, reiniciemos el tiempo!",
	"I just want to go home.": "Solo quiero irme a casa.",
	"That is the spirit!": "¡Ese es el espíritu!",
	"Not until our work is done.": "No hasta que nuestra obra esté concluida.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — Dee check-in (after floor 3)
	# ══════════════════════════════════════════════════════════════════════════
	"You are doing well. You have a moment’s respite. If you have any questions, I will answer them to the extent of my knowledge.": "Lo está haciendo bien. Tiene un momento de respiro. Si tiene preguntas, las responderé hasta donde alcance mi conocimiento.",
	"Who are these guys, anyway?": "¿Quiénes son estos tipos, en todo caso?",
	"Why do they want the Sacred Shuffle?": "¿Por qué quieren la Mezcla Sagrada?",
	"Why are you involved in all this?": "¿Por qué está usted metido en todo esto?",
	"What is my role in all this?": "¿Cuál es mi papel en todo esto?",
	"They call themselves the Cult of Patience. I call them the Cult of Doom.": "Ellos se llaman el Culto de la Paciencia. Yo los llamo el Culto de la Perdición.",
	"The earlier traces of their existence date back to the 17th century, but they may have existed even before then.": "Los primeros rastros de su existencia se remontan al siglo XVII, pero quizá existían incluso antes.",
	"They have been trying to play the Sacred Shuffle for centuries. In the shadows.": "Llevan siglos intentando jugar la Mezcla Sagrada. En las sombras.",
	"What’s different now?": "¿Qué ha cambiado ahora?",
	"The Digital Age.": "La era digital.",
	"A single game of cards, dealt and shuffled by hand, takes no small measure of time to set in order and play to its end. With these machines of your time, hundreds, thousands shuffles can be generated and played in mere seconds.": "Una sola partida de cartas, repartida y barajada a mano, exige un tiempo nada escaso para ordenarse y jugarse hasta el final. Con estas máquinas de su época, cientos, miles de mezclas pueden generarse y jugarse en meros segundos.",
	"Who’s behind the masks?": "¿Quién está detrás de las máscaras?",
	"Nobility rejects, revolution survivors, ex-political prisoners. People who fell from high, in terms of their position in society. Their obsessive need for wealth, power and stature has twisted their minds beyond recognition.": "Desechos de la nobleza, sobrevivientes de revoluciones, expresos políticos. Gente que cayó desde lo alto, en cuanto a su posición en la sociedad. Su necesidad obsesiva de riqueza, poder y prestigio les ha retorcido la mente hasta volverla irreconocible.",
	"They have extended their lives with dangerous dark arts. The longer they live, the less human they become. Only the obsession remains.": "Han prolongado sus vidas con peligrosas artes oscuras. Cuanto más viven, menos humanos son. Solo queda la obsesión.",
	"Their masks are not meant to hide their identity, they’re meant to hide from themselves their own hideous faces.": "Sus máscaras no sirven para ocultar su identidad, sirven para ocultarse a sí mismos sus propios rostros espantosos.",
	"Time and change are their enemies. They believe the Sacred Shuffle can take them back to a time where they were at the height of their power, and keep them there, forever.": "El tiempo y el cambio son sus enemigos. Creen que la Mezcla Sagrada puede devolverlos a una época en que estaban en la cumbre de su poder, y mantenerlos ahí, para siempre.",
	"They want to make everything great again, huh.": "O sea que quieren que todo vuelva a ser grandioso, ¿eh?",
	"Hardly. Time would be broken. It would no longer pass. They would be princes, kings, emperors, in their own individual timeloops. At least, that’s my theory. It’s better to not find out.": "En absoluto. El tiempo quedaría roto. Dejaría de transcurrir. Serían príncipes, reyes, emperadores, cada uno en su propio bucle temporal. Al menos, esa es mi teoría. Es mejor no averiguarlo.",
	"I get the picture; everyone else would be their NPCs.": "Ya capto; todos los demás seríamos sus NPC.",
	"NPC?": "¿NPC?",
	"Never mind.": "Olvídelo.",
	"I have been studying the history and variants of the game you call Solitaire since my years spent in Rudolf II’s court in Prague, the center of Kabbalistic scholarship.": "He estudiado la historia y las variantes del juego que ustedes llaman Solitario desde mis años en la corte de Rodolfo II en Praga, el centro de la erudición cabalística.",
	"Another name Solitaire goes by is Patience. The Scandinavian word for patience is kabale.": "Otro nombre por el que se conoce al Solitario es Patience. La palabra escandinava para paciencia es kabale.",
	"While it did become a game of patience for the impatient, it’s roots lie in divination. You could say I have a passion for ciphers, secret languages, the mathematical codes that rule the cosmos.": "Si bien llegó a ser un juego de paciencia para los impacientes, sus raíces están en la adivinación. Podría decirse que tengo pasión por las cifras, las lenguas secretas, los códigos matemáticos que rigen el cosmos.",
	"As I came to understand the power of a deck of cards, I managed to establish connections through time with other souls who became aware of the existence of the Sacred Shuffle, and shared my concern about the Cult of Doom.": "A medida que comprendí el poder de una baraja, logré establecer vínculos a través del tiempo con otras almas que advirtieron la existencia de la Mezcla Sagrada y compartían mi inquietud por el Culto de la Perdición.",
	"Like a group of super good guys.": "Como un grupo de súper buenos.",
	"Good? Don’t fool yourself into thinking I operate in the name of good, or that any other of the Time Patrons have good intentions. We each have our own incentives.": "¿Buenos? No se engañe creyendo que obro en nombre del bien, ni que ningún otro de los Mecenas del Tiempo tenga buenas intenciones. Cada uno tiene sus propios incentivos.",
	"Like what?": "¿Como cuáles?",
	"Wealth, power and stature.": "Riqueza, poder y prestigio.",
	"…": "…",
	"The only difference between the Time Patrons and the Cult of Doom is that we accept time and change, and rather achieve wealth, power and stature by the natural order of things.": "La única diferencia entre los Mecenas del Tiempo y el Culto de la Perdición es que nosotros aceptamos el tiempo y el cambio, y preferimos alcanzar riqueza, poder y prestigio según el orden natural de las cosas.",
	"And by NOT destroying human civilization as we know it.": "Y por NO destruir la civilización humana tal como la conocemos.",
	"You can trust that, but don’t trust anybody.": "Eso puede creerlo, pero no confíe en nadie.",
	"You are destined to play the Sacred Shuffle.": "Usted está destinado a jugar la Mezcla Sagrada.",
	"Great, so we’ve already won in the future?": "Genial, ¿entonces ya ganamos en el futuro?",
	"No. Some things are written. Others remain in ceaseless... shuffle.": "No. Algunas cosas están escritas. Otras permanecen en incesante… mezcla.",
	"Ha.": "Ja.",
	"You WILL play the Sacred Shuffle. But, who will profit from it? The Cult? You? Humanity?": "Usted JUGARÁ la Mezcla Sagrada. Pero ¿quién se beneficiará de ello? ¿El Culto? ¿Usted? ¿La humanidad?",
	"You?": "¿Usted?",
	"I’m afraid you have no choice but to trust me.": "Me temo que no le queda más remedio que confiar en mí.",
	"I guess.": "Supongo.",
	"OK, I will trust you for now.": "Bien, confiaré en usted por ahora.",
	"We hold one great advantage over the Cult. A card up our sleeve, in a manner of speaking!": "Tenemos una gran ventaja sobre el Culto. ¡Un as bajo la manga, por así decirlo!",
	"Were you the Queen's official punster?": "¿Era usted el bromista oficial de la Reina?",
	"The Cult does not know that the Sacred Shuffle does not choose a screen. It chooses a player. They do not know you have been chosen. They cannot know. You have to keep playing and beat a shuffle on every floor.": "El Culto no sabe que la Mezcla Sagrada no elige una pantalla. Elige a un jugador. No saben que usted ha sido elegido. No pueden saberlo. Debe seguir jugando y vencer una mezcla en cada piso.",
	"Ten floors. So ten games and that’s it?": "Diez pisos. ¿Entonces diez partidas y ya?",
	"Not quite. When you leave the building, time will reset. You will have to do it again. To put it in simple terms: we cannot do it alone. You are performing a summoning ritual.": "No del todo. Cuando salga del edificio, el tiempo se reiniciará. Tendrá que hacerlo de nuevo. En términos simples: no podemos lograrlo solos. Usted está ejecutando un ritual de invocación.",
	"Who I am summoning?": "¿A quién estoy invocando?",
	"Your other patrons through the ages. People who by fate or by chance got close to the Sacred Shuffle and whose destinies were forever intertwined with the cosmic mathematics of Solitaire.": "A sus otros mecenas a través de las eras. Gente que por destino o por azar se acercó a la Mezcla Sagrada y cuyos destinos quedaron entrelazados para siempre con la matemática cósmica del Solitario.",
	"Kings, Queens, Emperors, Prisoners, Poets and Adventurers, among others.": "Reyes, reinas, emperadores, prisioneros, poetas y aventureros, entre otros.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — Dee (third transmission, after floor 6)
	# ══════════════════════════════════════════════════════════════════════════
	"You are now more than halfway through. Take a break. Go drink some water.": "Ya ha pasado más de la mitad. Tómese un descanso. Vaya a beber agua.",
	"I don’t think The Cult of Doom brought any water bottles.": "No creo que el Culto de la Perdición haya traído botellas de agua.",
	"Oh, I wasn’t talking to you.": "Ah, no le hablaba a usted.",
	"Huh?": "¿Eh?",
	"Never mind. Do you have any other questions? The other Time Patrons might not be as helpful as I.": "No importa. ¿Tiene otras preguntas? Los demás Mecenas del Tiempo quizá no sean tan serviciales como yo.",
	"You keep mentioning other Time Patrons…": "No deja de mencionar a otros Mecenas del Tiempo…",
	"Who are they?": "¿Quiénes son?",
	"What is their connection to Solitaire?": "¿Cuál es su vínculo con el Solitario?",
	"When will I meet them?": "¿Cuándo los conoceré?",
	"Mostly nobles, kings, princesses, lords…": "En su mayoría nobles, reyes, princesas, señores…",
	"Great, I’m caught between two groups of rich people fighting for more power.": "Genial, estoy atrapado entre dos grupos de ricos peleando por más poder.",
	"I’m afraid that’s how human history goes. I presume it’s still the case in your time.": "Me temo que así marcha la historia humana. Presumo que sigue siendo el caso en su época.",
	"…pretty much.": "…básicamente, sí.",
	"A lot of them also fell from high, found hardship, exile, captivity, and in duress, almost touched the Sacred Shuffle.": "Muchos de ellos también cayeron desde lo alto, conocieron la penuria, el exilio, el cautiverio y, bajo coacción, casi tocaron la Mezcla Sagrada.",
	"What do you mean « almost »?": "¿Qué quiere decir con « casi »?",
	"They got close to the Sacred Shuffle by helping you find it.": "Se acercaron a la Mezcla Sagrada al ayudarle a encontrarla.",
	"I’m confused.": "Estoy confundido.",
	"Time paradoxes tend to do that.": "Las paradojas temporales suelen causar eso.",
	"You are.": "Usted.",
	"Through Solitaire, they will talk to you from their time period, as I am doing. Through you, they are connected to the Sacred Shuffle.": "A través del Solitario le hablarán desde su época, como lo hago yo. A través de usted, están conectados con la Mezcla Sagrada.",
	"Which I haven’t found yet.": "Que todavía no he encontrado.",
	"Our crude human senses can only perceive time as linear, but it is not. All of this has happened before…": "Nuestros toscos sentidos humanos solo perciben el tiempo como lineal, pero no lo es. Todo esto ya ha ocurrido antes…",
	"…all of this will happen again. How did I know that?": "…y todo esto volverá a ocurrir. ¿Cómo sabía yo eso?",
	"Your memory is starting to leak through time. Even if you think this is the first time we’re having this conversation, it could be the millionth time.": "Su memoria empieza a filtrarse a través del tiempo. Aunque crea que esta es la primera vez que tenemos esta conversación, podría ser la millonésima.",
	"That’s encouraging.": "Qué alentador.",
	"You have to contact them.": "Tiene que contactarlos.",
	"How?": "¿Cómo?",
	"You need to generate Time Energy, but also you need to weave the threads of time, find the connections between the Time Patrons. Even I do not know their all their identities. There is one from my time...": "Necesita generar Energía Temporal, pero también tejer los hilos del tiempo, hallar las conexiones entre los Mecenas del Tiempo. Ni yo conozco todas sus identidades. Hay una de mi época…",
	"Who?": "¿Quién?",
	"Mary Stuart, Queen of the Scots.": "María Estuardo, Reina de los Escoceses.",
	"Don’t they teach history in your time? Never mind. Just remember her name.": "¿No enseñan historia en su época? No importa. Solo recuerde su nombre.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — Dee final (before floor 10)
	# ══════════════════════════════════════════════════════════════════════════
	"You’re almost at the end of the loop. You’re about to face your greatest challenge yet.": "Está casi al final del bucle. Está a punto de enfrentar su mayor desafío hasta ahora.",
	"Any advice?": "¿Algún consejo?",
	"Yes. Patience.": "Sí. Paciencia.",
	"Another pun?": "¿Otro juego de palabras?",
	"No. All you need to win is patience.": "No. Todo lo que necesita para ganar es paciencia.",
	"What if I win?": "¿Y si gano?",
	"Go through the challenges of the Cult of Doom again, keep weaving the threads of the secret history of Solitaire and find the Sacred Shuffle!": "¡Atraviese de nuevo las pruebas del Culto de la Perdición, siga tejiendo los hilos de la historia secreta del Solitario y encuentre la Mezcla Sagrada!",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — the intro (before Dee's face appears, then the first call)
	# ══════════════════════════════════════════════════════════════════════════
	"Click. Click. Click.": "Clic. Clic. Clic.",
	"Click!": "¡Clic!",
	"Click! Click! Click!": "¡Clic! ¡Clic! ¡Clic!",
	"Click! Click!": "¡Clic! ¡Clic!",
	"You’ve done it again.": "Lo lograste otra vez.",
	"As you rub the armrests of your cheap office chair, you watch the cards bounce, bounce and bounce with profound satisfaction.": "Mientras frotas los apoyabrazos de tu silla de oficina barata, miras las cartas rebotar, rebotar y rebotar con profunda satisfacción.",
	"Another Solitaire game completed, and you’ve beaten your personal record at that!": "¡Otra partida de Solitario terminada, y encima batiste tu récord personal!",
	"As the screen suddenly flickers…": "Cuando la pantalla parpadea de repente…",
	"You catch a glimpse of a face.": "Alcanzas a ver un rostro.",
	"It takes a moment to realize it's yours.": "Tardas un instante en darte cuenta de que es el tuyo.",
	"You feel strangely compelled to keep looking at your screen, but by the corner of your eye, you notice everyone on the office floor is also mindlessly playing Solitaire.": "Te sientes extrañamente obligado a seguir mirando la pantalla, pero por el rabillo del ojo notas que todos en el piso de oficinas también juegan al Solitario de forma automática.",
	"Eyes so dead, skin so pale, lips so dry.": "Ojos tan muertos, pieles tan pálidas, labios tan secos.",
	"And then you see them.\nWho, or what, are they?\nHow long have they been here?": "Y entonces los ves.\n¿Quiénes, o qué, son?\n¿Cuánto tiempo llevan aquí?",
	"You feel like you're waking up from a long nightmare... into something worse.\n\nStartled, you ask yourself…": "Sientes que despiertas de una larga pesadilla… para caer en algo peor.\n\nSobresaltado, te preguntas…",
	"How long have I been playing Solitaire?": "¿Cuánto tiempo llevo jugando al Solitario?",
	"Before you can even think of an answer, your screen flickers again.": "Antes de que puedas siquiera pensar una respuesta, tu pantalla vuelve a parpadear.",
	"This time, you’re not looking at your face.": "Esta vez no estás viendo tu rostro.",
	"It's a bearded man with a look straight out of an 17th century painting.": "Es un hombre barbado, con un aspecto salido directamente de una pintura del siglo XVII.",
	"I have definitely been playing too long…": "Definitivamente llevo demasiado tiempo jugando…",
	"Is this a feature or a bug?": "¿Esto es una función o un error?",
	"The face starts talking. It’s talking to you.": "El rostro empieza a hablar. Te habla a ti.",
	"You wonder if you’re more confused by the fact that it’s talking to you or by the fact that it somehow knows what you were thinking.": "Te preguntas qué te desconcierta más: que te hable, o que de algún modo sepa lo que estabas pensando.",
	"You have been playing a long time. But that is not important for now.": "Lleva mucho tiempo jugando. Pero eso no importa por ahora.",
	"Who are you?": "¿Quién es usted?",
	"My name is John Dee. Advisor and astrologer of Queen Elizabeth the First. I will die in 1608. From your point of view, I have been dead since 1608.": "Mi nombre es John Dee. Consejero y astrólogo de la reina Isabel I. Moriré en 1608. Desde su punto de vista, llevo muerto desde 1608.",
	"What the hell?": "¿Qué diablos?",
	"A peculiar phrasing, but hell indeed! Hear me now, and hear me well. I wish I had a calmer way to say this, but I do not: the fate of human civilization hangs in the balance.": "Una expresión peculiar, ¡pero diablos, en efecto! Escúcheme ahora, y escúcheme bien. Ojalá tuviera un modo más sereno de decir esto, pero no lo tengo: el destino de la civilización humana pende de un hilo.",
	"The Cult of Patience has seized the counting-house where you work, through means I won’t dignify to qualify as magic. They have been making you play Solitaire repeatedly, endlessly. Has it been days? Weeks? Months? I am not sure myself.": "El Culto de la Paciencia se ha apoderado de la casa de cuentas donde usted trabaja, por medios que no me rebajaré a calificar de magia. Le han hecho jugar al Solitario una y otra vez, sin fin. ¿Han pasado días? ¿Semanas? ¿Meses? Ni yo mismo estoy seguro.",
	"Let’s say I believe you. Why Solitaire?": "Digamos que le creo. ¿Por qué el Solitario?",
	"There are 52 cards in a standard deck in Solitaire. There are 80,658,175,170,943,878,571,660,636,856,403,\n766,975,289,505,440,883,277,824,000,000,000,000 possible arrangements.": "Hay 52 cartas en una baraja estándar de Solitario. Existen 80.658.175.170.943.878.571.660.636.856.403,\n766.975.289.505.440.883.277.824.000.000.000.000 disposiciones posibles.",
	"To better understand the magnitude of this number : It is more than the quantity of atoms that form the Earth.": "Para comprender mejor la magnitud de este número: supera la cantidad de átomos que forman la Tierra.",
	"Whoa.": "Guau.",
	"There is one particular arrangement. The Sacred Shuffle. It does something extraordinary.": "Existe una disposición en particular. La Mezcla Sagrada. Hace algo extraordinario.",
	"It gives dominion over time, way beyond the childish dark arts the Cult currently dabbles in, and way beyond the simple time projection I am using to contact you.": "Otorga dominio sobre el tiempo, mucho más allá de las infantiles artes oscuras con las que el Culto juguetea por ahora, y mucho más allá de la simple proyección temporal que uso para contactarlo.",
	"But what does all this have to do with me?": "¿Pero qué tiene que ver todo esto conmigo?",
	"Only you can stop them.": "Solo usted puede detenerlos.",
	"Huh, OK? How?": "Eh, ¿bueno? ¿Cómo?",
	"By playing Solitaire. Repeatedly. Endlessly.": "Jugando al Solitario. Una y otra vez. Sin fin.",
	"Great.": "Genial.",
	"We will talk more later. Now, you must play or the Cult will notice you and kill you!": "Hablaremos más adelante. ¡Ahora debe jugar o el Culto lo notará y lo matará!",
	"Play Solitaire or die!": "¡Juegue al Solitario o muera!",

	# ══════════════════════════════════════════════════════════════════════════
	#  End / game-over screen
	# ══════════════════════════════════════════════════════════════════════════
	"You Escaped the Tower": "Escapaste de la Torre",
	"The Tower Keeps You": "La Torre te retiene",
	"Local High Scores": "Mejores puntajes locales",
	"No runs recorded yet.": "Aún no hay partidas registradas.",
	"Your name": "Tu nombre",
	"RECORD SCORE": "REGISTRAR PUNTAJE",
	"NEW RUN": "NUEVA PARTIDA",
	"TITLE": "MENÚ PRINCIPAL",
	"★ %d pts    ⏳ %d credits    %d/%d floors    %s": "★ %d pts    ⏳ %d créditos    %d/%d pisos    %s",
	"%d pts": "%d pts",

	# ══════════════════════════════════════════════════════════════════════════
	#  Misc / toasts
	# ══════════════════════════════════════════════════════════════════════════
	"Save reset: %s": "Partida guardada reiniciada: %s",

	# ══════════════════════════════════════════════════════════════════════════
	#  Patron coach — the rule named aloud when the table refuses a move
	# ══════════════════════════════════════════════════════════════════════════
	"No dealing while a column stands empty. Fill every gap first, then the stock will give.": "No se reparte mientras una columna esté vacía. Rellena primero cada hueco y el mazo cederá.",
	"The stock is spent — what lies on the table is all that remains.": "El mazo está agotado: lo que hay en la mesa es todo lo que queda.",
	"A foundation takes one card at a time, never a run.": "Una fundación recibe una carta cada vez, nunca una secuencia.",
	"Each foundation keeps to a single suit — that pile is not yours to fill.": "Cada fundación se ciñe a un solo palo: esa pila no te corresponde.",
	"Foundations climb from the Ace upward, one rank at a time.": "Las fundaciones ascienden desde el As, un rango cada vez.",
	"A free cell holds a single card, and that one is taken.": "Una celda libre aloja una sola carta, y esa ya está ocupada.",
	"A card only lands on the rank just above it. Suit matters when you lift a run, not when you place one.": "Una carta solo se posa sobre el rango inmediatamente superior. El palo importa al levantar una secuencia, no al colocarla.",
	"Columns run down in alternating colours — red on black, black on red.": "Las columnas descienden alternando colores: rojo sobre negro, negro sobre rojo.",
	"Only a King may open an empty column.": "Solo un Rey puede abrir una columna vacía.",
	"The tableau runs down in alternating colours — red on black, black on red.": "El tableau desciende alternando colores: rojo sobre negro, negro sobre rojo.",
	"That card lies face down. Clear the cards above it and it will turn.": "Esa carta está boca abajo. Despeja las que tiene encima y se dará la vuelta.",
	"Only a run descending in one suit travels as a block. A mixed run moves one card at a time.": "Solo una secuencia descendente de un mismo palo viaja en bloque. Una mezclada avanza carta a carta.",
	"A run travels whole only while it descends in alternating colours.": "Una secuencia viaja entera solo mientras desciende alternando colores.",
	"You can carry %d cards at once, not %d — each free cell and each empty column raises the count.": "Puedes llevar %d cartas a la vez, no %d: cada celda libre y cada columna vacía aumentan esa cifra.",
	"That card is still covered. Clear the two below it first.": "Esa carta sigue cubierta. Despeja primero las dos que la bloquean.",
	"Take only a card one rank above or below the waste. The Ace bridges King and Two.": "Toma solo una carta un rango por encima o por debajo del descarte. El As une al Rey con el Dos.",
	"Pair cards that add to thirteen. A King is worth thirteen alone.": "Empareja cartas que sumen trece. Un Rey vale trece por sí solo.",
	"Nowhere for that card to go. Deal a new row once every column holds a card.": "Esa carta no tiene adónde ir. Reparte una fila nueva en cuanto cada columna tenga una carta.",
	"Nowhere for that card to go — park it in a free cell and dig deeper.": "Esa carta no tiene adónde ir: apárcala en una celda libre y sigue cavando.",
	"Nowhere for that card to go. Draw from the stock and come back to it.": "Esa carta no tiene adónde ir. Roba del mazo y vuelve a ella.",
	"Nowhere for that card to go just now.": "Esa carta no tiene adónde ir por ahora.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Patron coach — the corner controls and the How to play briefings
	# ══════════════════════════════════════════════════════════════════════════
	"HOW TO PLAY": "CÓMO JUGAR",
	"MUTE": "SILENCIAR",
	"MUTED": "SILENCIADO",
	"Klondike. Four foundations, one suit each, climbing Ace to King — fill all four and the floor is yours.\n• The tableau runs down in alternating colours: red on black, black on red.\n• Only a King may open an empty column.\n• Draw from the stock to the waste and play the waste's top card.\n• Clearing the cards above a face-down one turns it over.": "Klondike. Cuatro fundaciones, una por palo, ascendiendo del As al Rey: complétalas las cuatro y el piso será tuyo.\n• El tableau desciende alternando colores: rojo sobre negro, negro sobre rojo.\n• Solo un Rey puede abrir una columna vacía.\n• Roba del mazo al descarte y juega la carta superior del descarte.\n• Despejar las cartas que cubren una carta boca abajo la voltea.",
	"Spider. Eight runs, King down to Ace in a single suit; each run you finish leaves the table.\n• A card lands on the rank just above it, whatever the suit.\n• Only a run already in one suit travels as a block — a mixed one moves card by card.\n• Deal ten more cards when you are stuck, but never while a column stands empty.\n• Clear all eight runs to win.": "Spider. Ocho secuencias, del Rey al As en un mismo palo; cada secuencia que termines abandona la mesa.\n• Una carta se posa sobre el rango inmediatamente superior, sea cual sea su palo.\n• Solo una secuencia ya de un mismo palo viaja en bloque: una mezclada avanza carta a carta.\n• Reparte diez cartas más cuando te atasques, pero nunca mientras una columna esté vacía.\n• Completa las ocho secuencias para ganar.",
	"FreeCell. Every card is face up from the first move, and every deal can be won. Build four foundations, Ace to King, one suit each.\n• Columns run down in alternating colours: red on black, black on red.\n• Each free cell parks a single card.\n• One move carries (free cells + 1) cards, doubled for every empty column.\n• Nothing is hidden. The whole puzzle is in front of you from the start.": "FreeCell. Todas las cartas están boca arriba desde la primera jugada, y todo reparto tiene solución. Construye cuatro fundaciones, del As al Rey, una por palo.\n• Las columnas descienden alternando colores: rojo sobre negro, negro sobre rojo.\n• Cada celda libre aloja una sola carta.\n• Una jugada transporta (celdas libres + 1) cartas, y esa cifra se duplica por cada columna vacía.\n• Nada está oculto. Todo el rompecabezas está ante ti desde el principio.",
	"TriPeaks. Clear all twenty-eight cards from the three peaks.\n• Take any uncovered card one rank above or below the top of the waste.\n• The Ace bridges King and Two, so a chain never has to stop there.\n• A card is uncovered once the two below it are gone.\n• Draw from the stock when nothing fits — it breaks your chain, and a long chain scores far more.": "TriPeaks. Despeja las veintiocho cartas de los tres picos.\n• Toma cualquier carta descubierta un rango por encima o por debajo de la cima del descarte.\n• El As une al Rey con el Dos, así que una cadena nunca tiene que detenerse ahí.\n• Una carta queda descubierta en cuanto desaparecen las dos que tiene debajo.\n• Roba del mazo cuando nada encaje: rompe tu cadena, y una cadena larga puntúa mucho más.",
	"Pyramid. Clear every card of the pyramid by pairing them to thirteen.\n• The Ace counts one, the Jack eleven, the Queen twelve, the King thirteen.\n• A King is thirteen on its own and clears alone.\n• Only an uncovered card can be paired: the two below it must go first.\n• Pair with the top of the waste, or turn the stock for a new one.": "Pyramid. Despeja todas las cartas de la pirámide emparejándolas para sumar trece.\n• El As vale uno, la Jota once, la Reina doce, el Rey trece.\n• Un Rey vale trece por sí solo y se retira solo.\n• Solo una carta descubierta puede emparejarse: las dos que tiene debajo deben salir antes.\n• Empareja con la cima del descarte, o roba del mazo para descubrir otra.",
}
