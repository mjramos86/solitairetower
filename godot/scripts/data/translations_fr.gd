extends RefCounted

## English → French translations, keyed by the exact English source string used at
## the call site. Locale.t() looks strings up here when the language is French; a
## missing key falls back to the English source, so partial coverage is safe.
##
## Keep keys byte-for-byte identical to the source (including the curly
## apostrophe ’, guillemets « », em dash —, ellipsis …, and \n line breaks).

const MAP := {
	# ══════════════════════════════════════════════════════════════════════════
	#  UI — title, menus, common buttons
	# ══════════════════════════════════════════════════════════════════════════
	"LOAD GAME": "CHARGER",
	"NEW GAME": "NOUVELLE PARTIE",
	"HIGH SCORES": "MEILLEURS SCORES",
	"EXIT GAME": "QUITTER",
	"OPTIONS": "OPTIONS",
	"Options": "Options",
	"Back": "Retour",
	"Back ▸": "Retour ▸",
	"◂ Back": "◂ Retour",
	"Done": "Terminé",
	"Cancel": "Annuler",
	"Continue ▸": "Continuer ▸",
	"Begin": "Commencer",
	"Skip ▸▸": "Passer ▸▸",
	"Language": "Langue",
	"Audio": "Audio",
	"♪  Music": "♪  Musique",
	"🔊  Sound Effects": "🔊  Effets sonores",
	"🔊  Sound": "🔊  Son",
	"🔊 Sound": "🔊 Son",

	# ══════════════════════════════════════════════════════════════════════════
	#  Map / tower hub
	# ══════════════════════════════════════════════════════════════════════════
	"A narrative horror roguelike Solitaire by Emjayhar": "Un solitaire roguelike d’horreur narrative par Emjayhar",
	"Face the Cult of Patience and uncover the occult secret history of Solitaire": "Affrontez la Secte de la Patience et découvrez l’histoire secrète et occulte du Solitaire",
	"PLAYER": "JOUEUR",
	"LIVES": "VIES",
	"Player": "Joueur",
	"Lives": "Vies",
	"🏆 HIGH SCORES": "🏆 MEILLEURS SCORES",
	"Time Patron": "Mécène du Temps",
	"Time Credits": "Crédits du Temps",
	"Time Energy": "Énergie du Temps",
	"🎒 Inventory": "🎒 Inventaire",
	"[ EMPTY ]": "[ VIDE ]",
	"Lore": "Savoir",
	"📖 Compendium": "📖 Compendium",
	"Customize": "Personnaliser",
	"🂠 Cardback": "🂠 Dos de carte",
	"▶ Watch Intro": "▶ Revoir l’intro",
	"🏠 Main Menu": "🏠 Menu principal",
	"⚑ New Run": "⚑ Nouvelle partie",
	"HIGH SCORES ": "MEILLEURS SCORES ",
	"🏆 High Scores": "🏆 Meilleurs scores",
	"New Run": "Nouvelle partie",
	"Start a New Run?\n\nThis ends your current descent — the rest of your lives are forfeit and your run is scored now.": "Commencer une nouvelle partie ?\n\nCeci met fin à votre descente en cours — vos vies restantes sont perdues et votre partie est comptabilisée maintenant.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Game screen — HUD, toolbar, status, overlays
	# ══════════════════════════════════════════════════════════════════════════
	"↩ Undo (%d)": "↩ Annuler (%d)",
	"⟳ Shuffle": "⟳ Redistribuer",
	"⏸ Pause": "⏸ Pause",
	"✕ Abandon": "✕ Abandonner",
	"Floor %d of %d": "Étage %d sur %d",
	"%d/%d floors": "%d/%d étages",
	"★ %d pts": "★ %d pts",
	"Paused": "En pause",
	"Resume": "Reprendre",
	"Restart Floor": "Recommencer l’étage",
	"Abandon Run": "Abandonner la partie",
	"Re-deal this floor with a fresh shuffle?\n\nYou will lose a life.": "Redistribuer cet étage avec un nouveau brassage ?\n\nVous perdrez une vie.",
	"Abandon this floor?\n\nYou will lose a life and return to the map.": "Abandonner cet étage ?\n\nVous perdrez une vie et retournerez à la carte.",
	"Floor Cleared!": "Étage réussi !",
	"You Win!": "Victoire !",
	"No moves left": "Aucun coup possible",
	"No legal move": "Coup interdit",
	"Descend ▸": "Descendre ▸",
	"CHEAT: floor cleared": "TRICHE : étage réussi",
	"CHEAT: inventory rerolled": "TRICHE : inventaire réattribué",
	"Recorded at #%d": "Enregistré au rang #%d",

	# ══════════════════════════════════════════════════════════════════════════
	#  Variant names & rules
	# ══════════════════════════════════════════════════════════════════════════
	"Spider": "Araignée",
	"Pyramid": "Pyramide",
	# (Klondike, FreeCell, TriPeaks keep their names in French.)
	"Build 4 foundation piles A→K by suit": "Bâtir 4 fondations de l’As au Roi par couleur",
	"Tableau: descending rank, alternating colour": "Tableau : rang décroissant, couleurs alternées",
	"Draw from stock to waste; move waste top card to play": "Piochez de la pioche vers la défausse ; jouez la carte du dessus de la défausse",
	"Flip hidden cards by clearing cards above them": "Retournez les cartes cachées en dégageant celles du dessus",
	"All cards dealt face-up — every deal is solvable": "Toutes les cartes face visible — chaque donne est solvable",
	"Build foundations A→K by suit": "Bâtir les fondations de l’As au Roi par couleur",
	"Use free cells as temporary card parking": "Utilisez les cellules libres pour garer des cartes temporairement",
	"Pair cards that sum to 13 (A=1, J=11, Q=12, K=13)": "Associez les cartes dont la somme fait 13 (A=1, V=11, D=12, R=13)",
	"Kings are removed alone": "Les Rois se retirent seuls",
	"Use the waste top to pair with pyramid cards": "Servez-vous du dessus de la défausse pour associer les cartes de la pyramide",
	"Clear all pyramid cards to win": "Retirez toutes les cartes de la pyramide pour gagner",
	"Build complete K→A sequences of the same suit": "Bâtir des séquences complètes du Roi à l’As d’une même couleur",
	"Completed sequences removed to foundations": "Les séquences complètes partent aux fondations",
	"Deal 10 new cards from stock when stuck": "Distribuez 10 nouvelles cartes de la pioche quand vous êtes bloqué",
	"Clear all 8 sequences to win": "Complétez les 8 séquences pour gagner",
	"Play cards +1 or -1 rank from waste top (A↔K wrap)": "Jouez des cartes de rang +1 ou -1 par rapport au dessus de la défausse (l’As et le Roi se suivent)",
	"Click pyramid cards to chain onto the waste": "Cliquez les cartes de la pyramide pour enchaîner sur la défausse",
	"Draw from stock when no move available": "Piochez quand aucun coup n’est possible",
	"Clear all 28 pyramid cards to win": "Retirez les 28 cartes de la pyramide pour gagner",

	# ══════════════════════════════════════════════════════════════════════════
	#  Shop
	# ══════════════════════════════════════════════════════════════════════════
	"The Merchant": "Le Marchand",
	"Shop": "Boutique",
	"Buy": "Acheter",
	"Owned": "Possédé",
	"Sold Out": "Épuisé",
	"Can't afford": "Fonds insuffisants",
	"Descend to the next floor ▸": "Descendre à l’étage suivant ▸",
	"⏳ %d": "⏳ %d",
	"Floor Rewards": "Récompenses de l’étage",
	"⏳  Floor %d Cleared — Time Credits Awarded": "⏳  Étage %d réussi — Crédits du Temps accordés",
	"🏪  John Dee's Cabinet of Curiosities — %d Items Available": "🏪  Cabinet de curiosités de John Dee — %d objets disponibles",
	"🎒  Your Inventory (%d/%d slots)": "🎒  Votre inventaire (%d/%d emplacements)",
	"Floor Cleared": "Étage réussi",
	"No Undos": "Aucune annulation",
	"Under 3 min": "Moins de 3 min",
	"Full Lives": "Vies intactes",
	"Score Bonus": "Bonus de points",
	"TOTAL EARNED": "TOTAL GAGNÉ",
	"YOUR BALANCE": "VOTRE SOLDE",
	"CHEAP": "BON MARCHÉ",
	"MEDIUM": "MOYEN",
	"PRICEY": "COÛTEUX",
	"RARE": "RARE",

	# ── item names ──
	"Scrying Glass": "Miroir de divination",
	"Knotted Cord": "Corde à nœuds",
	"Mortlake Brew": "Breuvage de Mortlake",
	"Quill of Ravens": "Plume de corbeaux",
	"Sealing Wax": "Cire à cacheter",
	"Athame": "Athamé",
	"Obsidian Mirror": "Miroir d’obsidienne",
	"Wax Seal Press": "Sceau de cire",
	"Philosopher's Sponge": "Éponge du philosophe",
	"Sealed Letter": "Lettre scellée",
	"Brass Compass": "Boussole de laiton",
	"Astrolabe": "Astrolabe",
	"Hermetic Casket": "Coffret hermétique",
	"Skeleton Key": "Passe-partout",
	"Alchemist's Cabinet": "Cabinet de l’alchimiste",
	"Angelic Besom": "Balai angélique",
	"Enochian Key": "Clé énochienne",
	"Vial of Quicksilver": "Fiole de vif-argent",
	"Queen's Patronage": "Faveur de la Reine",

	# ── item descriptions ──
	"Highlights one valid move on the board.": "Met en évidence un coup valide sur le plateau.",
	"You only get 3 undos per floor. This adds 5 more.": "Vous n’avez que 3 annulations par étage. Ceci en ajoute 5.",
	"Draw 1 extra card from stock for free.": "Piochez 1 carte supplémentaire gratuitement.",
	"Peek at the top 3 cards in the stock pile.": "Jetez un œil aux 3 premières cartes de la pioche.",
	"Get one free waste→stock recycle.": "Obtenez un recyclage défausse→pioche gratuit.",
	"Remove any one face-up card from the board entirely.": "Retirez complètement du plateau n’importe quelle carte face visible.",
	"Reveal all face-down cards for 8 seconds.": "Révèle toutes les cartes face cachée pendant 8 secondes.",
	"Digs an Ace out from anywhere — even buried or face-down — and sends it to its foundation.": "Extrait un As de n’importe où — même enfoui ou face cachée — et l’envoie à sa fondation.",
	"Mega-undo: rewind up to 10 moves at once.": "Méga-annulation : revenez jusqu’à 10 coups en arrière d’un coup.",
	"Shuffle waste back into stock for free.": "Rebrasse la défausse dans la pioche gratuitement.",
	"Flip any face-down tableau card face-up.": "Retournez face visible n’importe quelle carte cachée du tableau.",
	"Flash ALL valid moves for 8 seconds.": "Affiche TOUS les coups valides pendant 8 secondes.",
	"Bring any buried waste card to the top to play next.": "Ramène au sommet n’importe quelle carte enfouie de la défausse pour la jouer.",
	"Unlock a 5th free cell for this entire floor.": "Débloque une 5e cellule libre pour tout l’étage.",
	"Creates a temporary off-board card stash (1 card, 8 uses).": "Crée une réserve temporaire hors plateau (1 carte, 8 usages).",
	"Sweep the top card of any pile to the first empty column.": "Balaie la carte du dessus d’une pile vers la première colonne vide.",
	"Pull any card from stock to the top of the waste pile.": "Tirez n’importe quelle carte de la pioche vers le sommet de la défausse.",
	"Abandon this floor without losing a life.": "Abandonnez cet étage sans perdre de vie.",
	"Skip this floor entirely -- counts as cleared!": "Sautez complètement cet étage — il compte comme réussi !",

	# ── item use hints ──
	"Instant: glows on valid source & target.": "Instantané : illumine source et cible valides.",
	"Instant: adds 5 undos to your budget.": "Instantané : ajoute 5 annulations à votre réserve.",
	"Instant: free stock draw.": "Instantané : pioche gratuite.",
	"Shows a 6-second preview window.": "Affiche un aperçu de 6 secondes.",
	"Instant: recycles without counting.": "Instantané : recycle sans être décompté.",
	"Click mode: pick a card to vanish it.": "Mode clic : choisissez une carte à faire disparaître.",
	"Instant: temporary x-ray vision.": "Instantané : vision à rayons X temporaire.",
	"Instant: finds an Ace anywhere.": "Instantané : trouve un As n’importe où.",
	"Instant: pops 10 undo states.": "Instantané : annule 10 états de coup.",
	"Instant: free recycle.": "Instantané : recyclage gratuit.",
	"Click mode: pick a face-down card.": "Mode clic : choisissez une carte face cachée.",
	"Instant: full board hint glow.": "Instantané : illumine tout le plateau.",
	"Opens waste picker -- select a card.": "Ouvre le sélecteur de défausse — choisissez une carte.",
	"Instant: adds a free cell slot.": "Instantané : ajoute une cellule libre.",
	"Drag any card in/out of the stash.": "Glissez une carte dans/hors de la réserve.",
	"Click mode: pick a source pile top.": "Mode clic : choisissez le dessus d’une pile source.",
	"Opens stock browser -- pick your card.": "Ouvre l’explorateur de pioche — choisissez votre carte.",
	"Instant: safe retreat to the map.": "Instantané : repli en sûreté vers la carte.",
	"Instant: auto-win current floor.": "Instantané : réussite automatique de l’étage.",

	# ── item best_for ──
	"All games": "Tous les jeux",
	"Klondike · TriPeaks": "Klondike · TriPeaks",
	"Klondike · Pyramid": "Klondike · Pyramide",
	"Pyramid · TriPeaks": "Pyramide · TriPeaks",
	"Spider · Klondike": "Araignée · Klondike",
	"Klondike · FreeCell": "Klondike · FreeCell",
	"FreeCell": "FreeCell",
	"Spider · FreeCell · Klondike": "Araignée · FreeCell · Klondike",
	"Spider · FreeCell": "Araignée · FreeCell",
	"All games (emergency!)": "Tous les jeux (urgence !)",
	"All games (boss skip!)": "Tous les jeux (saut de boss !)",

	# ══════════════════════════════════════════════════════════════════════════
	#  Cardbacks
	# ══════════════════════════════════════════════════════════════════════════
	"The Solitaire Tower": "La Tour du Solitaire",
	"The Cult": "La Secte",
	"John Dee's Sigil": "Le sceau de John Dee",
	"Mary's Cipher": "Le chiffre de Marie",

	# ══════════════════════════════════════════════════════════════════════════
	#  Patron select
	# ══════════════════════════════════════════════════════════════════════════
	"Choose Your Time Patron": "Choisissez votre Mécène du Temps",
	"An ally for this descent, lending their nature to the wares you can purchase along the way.": "Un allié pour cette descente, prêtant sa nature aux objets que vous pourrez acheter en chemin.",
	"Select John Dee to begin your descent.": "Choisissez John Dee pour commencer votre descente.",
	"🔒": "🔒",

	# ══════════════════════════════════════════════════════════════════════════
	#  Cardback select
	# ══════════════════════════════════════════════════════════════════════════
	"Choose Your Cardback": "Choisissez votre dos de carte",
	"Locked designs are revealed by uncovering a Time Patron's connection to Solitaire in the Compendium.": "Les modèles verrouillés se révèlent en découvrant, dans le Compendium, le lien d’un Mécène du Temps avec le Solitaire.",
	"← Back to Tower": "← Retour à la Tour",

	# ══════════════════════════════════════════════════════════════════════════
	#  Slots
	# ══════════════════════════════════════════════════════════════════════════
	"SLOT %d": "EMPLACEMENT %d",
	"No run in progress": "Aucune partie en cours",
	"— Empty —": "— Vide —",
	"⚡ %d   ✓ %d": "⚡ %d   ✓ %d",

	# ══════════════════════════════════════════════════════════════════════════
	#  High scores
	# ══════════════════════════════════════════════════════════════════════════
	"⟳ Sync now": "⟳ Synchroniser",
	"No scores to show yet.": "Aucun score à afficher pour l’instant.",
	"Local": "Local",
	"Online": "En ligne",

	# ══════════════════════════════════════════════════════════════════════════
	#  Compendium — dynamic bits
	# ══════════════════════════════════════════════════════════════════════════
	"⚡ Time Energy: %d": "⚡ Énergie du Temps : %d",
	"🔒  Unknown Patron": "🔒  Mécène inconnu",
	"TIMELINE OF CIVILIZATION": "CHRONOLOGIE DE LA CIVILISATION",
	"No connections to the historical record have been uncovered yet.": "Aucun lien avec les archives historiques n’a encore été découvert.",
	"UNCOVER (%d ⚡)": "RÉVÉLER (%d ⚡)",
	"You: ": "Vous : ",
	"⚙ This Time Patron is still in development and cannot yet be selected.": "⚙ Ce Mécène du Temps est encore en développement et ne peut pas encore être choisi.",
	"Unknown Patron": "Mécène inconnu",
	"You": "Vous",
	"Strategy": "Stratégie",
	"Connection to Solitaire": "Lien avec le Solitaire",
	"This Time Patron has not yet revealed themselves to you.": "Ce Mécène du Temps ne s’est pas encore révélé à vous.",
	"The First Contact": "Le premier contact",
	"A Moment's Respite": "Un moment de répit",
	"More Than Halfway": "Plus de la moitié",
	"The Final Threshold": "Le seuil final",
	"The Compendium": "Le Compendium",
	"← Prev": "← Préc.",
	"Next →": "Suiv. →",
	"NEED %d MORE ⚡": "IL MANQUE %d ⚡",
	"Online ✓": "En ligne ✓",

	# ══════════════════════════════════════════════════════════════════════════
	#  Game screen — HUD, overlays, item card, score ledger
	# ══════════════════════════════════════════════════════════════════════════
	"Solitaire Tower of Doom · Early Access v%s": "Solitaire Tower of Doom · Accès anticipé v%s",
	"Solitaire Tower of Doom — %s (Floor %d)": "Solitaire Tower of Doom — %s (Étage %d)",
	"Floor %d of 10": "Étage %d sur 10",
	"🚪 ESCAPED!": "🚪 ÉVADÉ !",
	"✅ FLOOR CLEARED": "✅ ÉTAGE RÉUSSI",
	"[ ESCAPE ]": "[ S’ÉVADER ]",
	"[ DESCEND ]": "[ DESCENDRE ]",
	"⏸ PAUSED": "⏸ EN PAUSE",
	"▶ Continue": "▶ Reprendre",
	"★ Score History — Floor %d": "★ Historique des points — Étage %d",
	"No scoring events this floor yet.": "Aucun point marqué à cet étage pour l’instant.",
	"Close": "Fermer",
	"🗄️ stash empty (%d)": "🗄️ réserve vide (%d)",

	# ══════════════════════════════════════════════════════════════════════════
	#  Shop — buttons & states
	# ══════════════════════════════════════════════════════════════════════════
	"Best for: %s": "Idéal pour : %s",
	"[ ALREADY OWNED ]": "[ DÉJÀ POSSÉDÉ ]",
	"[ INVENTORY FULL ]": "[ INVENTAIRE PLEIN ]",
	"[ NEED %d MORE ⏳ ]": "[ IL MANQUE %d ⏳ ]",
	"[ BUY ]": "[ ACHETER ]",
	"⚠ Inventory full! Use or drop items in-game.": "⚠ Inventaire plein ! Utilisez ou jetez des objets en jeu.",
	"[ empty ]": "[ vide ]",
	"⚔  Continue to the Tower": "⚔  Continuer vers la Tour",
	"Acquired %s": "%s acquis",

	# ══════════════════════════════════════════════════════════════════════════
	#  Compendium — headings
	# ══════════════════════════════════════════════════════════════════════════
	"Compendium": "Compendium",
	"Time Patrons": "Mécènes du Temps",
	"Adversaries": "Adversaires",
	"Connections": "Connexions",
	"Recorded Transmissions": "Transmissions enregistrées",
	"Locked": "Verrouillé",
	"Unlock": "Débloquer",
	"Reveal": "Révéler",
	"In development": "En développement",
	"Under development": "En développement",

	# ══════════════════════════════════════════════════════════════════════════
	#  Patrons & lore (compendium prose)
	# ══════════════════════════════════════════════════════════════════════════
	"The Other Queen": "L’Autre Reine",
	"The Sun King": "Le Roi-Soleil",
	"The Old Lion": "Le Vieux Lion",
	"The Emperor": "L’Empereur",
	"The Prisoner": "Le Prisonnier",
	"Mary, Queen of Scots": "Marie, reine d’Écosse",
	"Elizabeth I's astrologer and master spy": "Astrologue et maître-espion d’Élisabeth Ire",
	"Queen of Scots, England's royal prisoner": "Reine d’Écosse, prisonnière royale d’Angleterre",
	"The astrologer trades in sight — see what is hidden, know what approaches.": "L’astrologue fait commerce de la vue — voyez ce qui est caché, sachez ce qui approche.",
	"The Cult of Patience": "La Secte de la Patience",
	"The Digitization Strategy": "La stratégie de numérisation",

	"John Dee was the most accomplished intellectual of Elizabethan England — a mathematician, cartographer, astronomer, and the personal astrologer of Queen Elizabeth I. It was Dee who calculated the most auspicious date for her coronation. His library at Mortlake was the largest private collection in England, until a mob ransacked it.": "John Dee fut l’intellectuel le plus accompli de l’Angleterre élisabéthaine — mathématicien, cartographe, astronome et astrologue personnel de la reine Élisabeth Ire. C’est Dee qui calcula la date la plus propice à son couronnement. Sa bibliothèque de Mortlake était la plus grande collection privée d’Angleterre, jusqu’à ce qu’une foule la mette à sac.",
	"He spent years trying to communicate with angels through a crystal ball and a medium named Edward Kelley, recording these conversations in an elaborate cipher. His notation system; Enochian, the supposed language of angels, became a cornerstone of Western occultism.": "Il passa des années à tenter de communiquer avec les anges au moyen d’une boule de cristal et d’un médium nommé Edward Kelley, consignant ces conversations dans un chiffre élaboré. Son système de notation, l’énochien, prétendue langue des anges, devint une pierre angulaire de l’occultisme occidental.",
	"Dee also traveled undercover as an intelligence agent for Elizabeth's court. He signed his correspondence to the queen \"007\". The two zeros representing a spy's watching eyes, the seven a lucky number.": "Dee voyagea aussi sous couverture comme agent de renseignement de la cour d’Élisabeth. Il signait sa correspondance à la reine « 007 ». Les deux zéros représentaient les yeux vigilants d’un espion, le sept étant un chiffre porte-bonheur.",
	"Legend has it that Dee visited Mary, Queen of Scots during her captivity, perhaps at Chartley or Fotheringhay, and taught her a card layout he presented as a method of divination. The game was supposedly meant to occupy her mind through the long nights before her execution.": "La légende veut que Dee ait rendu visite à Marie, reine d’Écosse, durant sa captivité, peut-être à Chartley ou à Fotheringhay, et lui ait enseigné une disposition de cartes qu’il présentait comme une méthode de divination. Le jeu aurait servi à occuper son esprit durant les longues nuits précédant son exécution.",
	"More deeply, Dee believed the universe itself was encoded, that behind the apparent randomness of the cards lay a divine mathematical order. He was one of the first to suspect that the Sacred Shuffle is a source of immense power.": "Plus profondément, Dee croyait que l’univers lui-même était codé, que derrière le hasard apparent des cartes se cachait un ordre mathématique divin. Il fut l’un des premiers à soupçonner que le Brassage Sacré est une source d’une puissance immense.",

	"Mary became Queen of Scotland when she was just six days old, after her father, James V, died in 1542. Because she was an infant, Scotland was ruled by regents while Mary spent much of her childhood in France, where she was raised at the French court and eventually married the Dauphin, François. When he became King of France in 1559, Mary was briefly Queen of both Scotland and France, but François died only a year later, in 1560, leaving her a widow at eighteen.": "Marie devint reine d’Écosse à seulement six jours, à la mort de son père Jacques V en 1542. N’étant qu’un nourrisson, l’Écosse fut gouvernée par des régents tandis que Marie passait une grande partie de son enfance en France, élevée à la cour française et mariée en temps voulu au dauphin François. Lorsqu’il devint roi de France en 1559, Marie fut brièvement reine de France et d’Écosse, mais François mourut à peine un an plus tard, en 1560, la laissant veuve à dix-huit ans.",
	"Mary returned to Scotland in 1561 to rule in person, landing in a country deeply divided by the Protestant Reformation, while she herself remained Catholic. Her reign was turbulent: she married her cousin Henry Stuart, Lord Darnley, in 1565, and the marriage quickly soured amid political plotting and violence, including Darnley's involvement in the murder of Mary's secretary, David Rizzio. Darnley himself was murdered in 1567, and Mary's swift marriage afterward to James Hepburn, Earl of Bothwell, widely suspected in Darnley's death, scandalized the nobility and triggered a rebellion.": "Marie revint en Écosse en 1561 pour régner en personne, abordant un pays profondément divisé par la Réforme protestante, alors qu’elle demeurait catholique. Son règne fut agité : elle épousa son cousin Henry Stuart, lord Darnley, en 1565, et le mariage tourna vite à l’aigre au milieu des intrigues et des violences, dont l’implication de Darnley dans le meurtre du secrétaire de Marie, David Rizzio. Darnley fut lui-même assassiné en 1567, et le remariage précipité de Marie avec James Hepburn, comte de Bothwell, largement soupçonné de la mort de Darnley, scandalisa la noblesse et déclencha une rébellion.",
	"Forced to abdicate in favor of her infant son (who became James VI of Scotland, and later James I of England), Mary fled to England in 1568, seeking the protection of her cousin, Queen Elizabeth I. Instead, Elizabeth had her held in a long series of confinements lasting nearly two decades. Mary became a magnet for Catholic plots aiming to depose Elizabeth and place Mary on the English throne; most damningly the Babington Plot of 1586, in which intercepted letters appeared to show Mary endorsing Elizabeth's assassination. Tried and convicted of treason, Mary was executed at Fotheringhay Castle in February 1587.": "Contrainte d’abdiquer en faveur de son fils en bas âge (qui devint Jacques VI d’Écosse, puis Jacques Ier d’Angleterre), Marie s’enfuit en Angleterre en 1568, cherchant la protection de sa cousine, la reine Élisabeth Ire. Au lieu de quoi Élisabeth la fit retenir dans une longue série de captivités durant près de deux décennies. Marie devint un aimant à complots catholiques visant à déposer Élisabeth pour la mettre sur le trône d’Angleterre ; le plus accablant fut le complot de Babington de 1586, où des lettres interceptées semblaient montrer Marie approuvant l’assassinat d’Élisabeth. Jugée et condamnée pour trahison, Marie fut exécutée au château de Fotheringhay en février 1587.",
	"Her son James VI later united the crowns of Scotland and England as James I, making Mary, in a sense, the ancestress of the joint British monarchy; a final ironic twist to a reign defined by intrigue, religious conflict, and tragedy.": "Son fils Jacques VI réunit plus tard les couronnes d’Écosse et d’Angleterre sous le nom de Jacques Ier, faisant de Marie, en un sens, l’ancêtre de la monarchie britannique unifiée ; une dernière ironie pour un règne marqué par l’intrigue, le conflit religieux et la tragédie.",

	"The Cult of Patience is an organization whose origins date back at least to the 17th century, perhaps further. Its members share one core conviction: the Sacred Shuffle exists, it is attainable, and whoever possesses it possesses time itself.": "La Secte de la Patience est une organisation dont les origines remontent au moins au XVIIe siècle, peut-être plus loin. Ses membres partagent une conviction centrale : le Brassage Sacré existe, il est atteignable, et quiconque le possède possède le temps lui-même.",
	"Unlike the Time Patrons, who guard the secret out of caution and respect, the Cult wants it for domination. They do not seek to understand Solitaire, they seek to exploit it.": "Contrairement aux Mécènes du Temps, qui gardent le secret par prudence et par respect, la Secte le convoite pour dominer. Ils ne cherchent pas à comprendre le Solitaire, ils cherchent à l’exploiter.",
	"The digitization of Solitaire in the 1990s was seen by the Cult as a historic windfall. For the first time, millions of games could be played simultaneously, by ordinary people, unaware of what they were searching for.": "La numérisation du Solitaire dans les années 1990 fut perçue par la Secte comme une aubaine historique. Pour la première fois, des millions de parties pouvaient être jouées simultanément, par des gens ordinaires, ignorant ce qu’ils cherchaient.",
	"Their current plan is brutally simple: seize a building, an office tower, a building full of office workers, and force its occupants to play Solitaire continuously, around the clock. By the sheer law of large numbers, the Sacred Shuffle will eventually appear on one of the screens.": "Leur plan actuel est d’une simplicité brutale : s’emparer d’un immeuble, une tour de bureaux, un bâtiment plein d’employés, et forcer ses occupants à jouer au Solitaire sans relâche, jour et nuit. Par la seule loi des grands nombres, le Brassage Sacré finira par apparaître sur l’un des écrans.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — shared chrome
	# ══════════════════════════════════════════════════════════════════════════
	"📞  Incoming Transmission -- John Dee": "📞  Transmission entrante -- John Dee",
	"What would you like to ask?": "Que souhaitez-vous demander ?",
	"That's all for now.": "C’est tout pour l’instant.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — victory
	# ══════════════════════════════════════════════════════════════════════════
	"You have shown why you were chosen by the Sacred Shuffle. I am afraid, though, this journey is only beginning.": "Vous avez montré pourquoi le Brassage Sacré vous a choisi. Je crains toutefois que ce voyage ne fasse que commencer.",
	"Our victory over the Cult of Doom will only be complete when all Time Patrons are revealed.": "Notre victoire sur la Secte du Malheur ne sera complète que lorsque tous les Mécènes du Temps seront révélés.",
	"Alright, reset time!": "D’accord, réinitialisons le temps !",
	"I just want to go home.": "Je veux juste rentrer chez moi.",
	"That is the spirit!": "Voilà l’état d’esprit !",
	"Not until our work is done.": "Pas avant que notre œuvre soit achevée.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — Dee check-in (after floor 3)
	# ══════════════════════════════════════════════════════════════════════════
	"You are doing well. You have a moment’s respite. If you have any questions, I will answer them to the extent of my knowledge.": "Vous vous en sortez bien. Vous avez un moment de répit. Si vous avez des questions, j’y répondrai dans la mesure de mon savoir.",
	"Who are these guys, anyway?": "Qui sont ces gens, au juste ?",
	"Why do they want the Sacred Shuffle?": "Pourquoi veulent-ils le Brassage Sacré ?",
	"Why are you involved in all this?": "Pourquoi êtes-vous mêlé à tout ça ?",
	"What is my role in all this?": "Quel est mon rôle dans tout ça ?",
	"They call themselves the Cult of Patience. I call them the Cult of Doom.": "Ils se nomment la Secte de la Patience. Moi, je les appelle la Secte du Malheur.",
	"The earlier traces of their existence date back to the 17th century, but they may have existed even before then.": "Les premières traces de leur existence remontent au XVIIe siècle, mais ils existaient peut-être déjà avant.",
	"They have been trying to play the Sacred Shuffle for centuries. In the shadows.": "Ils tentent de jouer le Brassage Sacré depuis des siècles. Dans l’ombre.",
	"What’s different now?": "Qu’est-ce qui a changé, aujourd’hui ?",
	"The Digital Age.": "L’ère numérique.",
	"A single game of cards, dealt and shuffled by hand, takes no small measure of time to set in order and play to its end. With these machines of your time, hundreds, thousands shuffles can be generated and played in mere seconds.": "Une seule partie de cartes, distribuée et brassée à la main, exige un temps non négligeable pour être mise en ordre et menée à terme. Avec les machines de votre époque, des centaines, des milliers de brassages peuvent être générés et joués en quelques secondes.",
	"Who’s behind the masks?": "Qui se cache derrière les masques ?",
	"Nobility rejects, revolution survivors, ex-political prisoners. People who fell from high, in terms of their position in society. Their obsessive need for wealth, power and stature has twisted their minds beyond recognition.": "Des rebuts de la noblesse, des survivants de révolutions, d’anciens prisonniers politiques. Des gens tombés de haut, quant à leur rang dans la société. Leur besoin obsessionnel de richesse, de pouvoir et de prestige a tordu leur esprit au point de le rendre méconnaissable.",
	"They have extended their lives with dangerous dark arts. The longer they live, the less human they become. Only the obsession remains.": "Ils ont prolongé leur vie par de dangereux arts sombres. Plus ils vivent, moins ils sont humains. Seule demeure l’obsession.",
	"Their masks are not meant to hide their identity, they’re meant to hide from themselves their own hideous faces.": "Leurs masques ne servent pas à cacher leur identité, mais à se dissimuler à eux-mêmes leur propre visage hideux.",
	"Time and change are their enemies. They believe the Sacred Shuffle can take them back to a time where they were at the height of their power, and keep them there, forever.": "Le temps et le changement sont leurs ennemis. Ils croient que le Brassage Sacré peut les ramener à une époque où ils étaient au sommet de leur puissance, et les y maintenir, à jamais.",
	"They want to make everything great again, huh.": "Ils veulent que tout redevienne grandiose, hein.",
	"Hardly. Time would be broken. It would no longer pass. They would be princes, kings, emperors, in their own individual timeloops. At least, that’s my theory. It’s better to not find out.": "Guère. Le temps serait brisé. Il ne s’écoulerait plus. Ils seraient princes, rois, empereurs, chacun dans sa propre boucle temporelle. Du moins, c’est ma théorie. Mieux vaut ne pas le vérifier.",
	"I get the picture; everyone else would be their NPCs.": "Je vois le tableau ; tous les autres seraient leurs PNJ.",
	"NPC?": "PNJ ?",
	"Never mind.": "Laissez tomber.",
	"I have been studying the history and variants of the game you call Solitaire since my years spent in Rudolf II’s court in Prague, the center of Kabbalistic scholarship.": "J’étudie l’histoire et les variantes du jeu que vous appelez Solitaire depuis mes années passées à la cour de Rodolphe II à Prague, le centre de l’érudition kabbalistique.",
	"Another name Solitaire goes by is Patience. The Scandinavian word for patience is kabale.": "Le Solitaire porte aussi le nom de Patience. En scandinave, le mot pour patience est « kabale ».",
	"While it did become a game of patience for the impatient, it’s roots lie in divination. You could say I have a passion for ciphers, secret languages, the mathematical codes that rule the cosmos.": "S’il est bien devenu un jeu de patience pour les impatients, ses racines plongent dans la divination. On pourrait dire que j’ai une passion pour les chiffres, les langues secrètes, les codes mathématiques qui régissent le cosmos.",
	"As I came to understand the power of a deck of cards, I managed to establish connections through time with other souls who became aware of the existence of the Sacred Shuffle, and shared my concern about the Cult of Doom.": "À mesure que je comprenais le pouvoir d’un jeu de cartes, je parvins à établir des liens à travers le temps avec d’autres âmes conscientes de l’existence du Brassage Sacré, et qui partageaient mon inquiétude quant à la Secte du Malheur.",
	"Like a group of super good guys.": "Comme une bande de super gentils.",
	"Good? Don’t fool yourself into thinking I operate in the name of good, or that any other of the Time Patrons have good intentions. We each have our own incentives.": "Gentils ? Ne vous méprenez pas en croyant que j’agis au nom du bien, ni qu’aucun autre Mécène du Temps ait de bonnes intentions. Chacun a ses propres motivations.",
	"Like what?": "Comme quoi ?",
	"Wealth, power and stature.": "Richesse, pouvoir et prestige.",
	"…": "…",
	"The only difference between the Time Patrons and the Cult of Doom is that we accept time and change, and rather achieve wealth, power and stature by the natural order of things.": "La seule différence entre les Mécènes du Temps et la Secte du Malheur, c’est que nous acceptons le temps et le changement, et que nous préférons obtenir richesse, pouvoir et prestige selon l’ordre naturel des choses.",
	"And by NOT destroying human civilization as we know it.": "Et en NE détruisant PAS la civilisation humaine telle que nous la connaissons.",
	"You can trust that, but don’t trust anybody.": "Ça, vous pouvez le croire, mais ne faites confiance à personne.",
	"You are destined to play the Sacred Shuffle.": "Vous êtes destiné à jouer le Brassage Sacré.",
	"Great, so we’ve already won in the future?": "Super, alors on a déjà gagné dans le futur ?",
	"No. Some things are written. Others remain in ceaseless... shuffle.": "Non. Certaines choses sont écrites. D’autres demeurent en un incessant… brassage.",
	"Ha.": "Ha.",
	"You WILL play the Sacred Shuffle. But, who will profit from it? The Cult? You? Humanity?": "Vous JOUEREZ le Brassage Sacré. Mais qui en profitera ? La Secte ? Vous ? L’humanité ?",
	"You?": "Vous ?",
	"I’m afraid you have no choice but to trust me.": "Je crains que vous n’ayez d’autre choix que de me faire confiance.",
	"I guess.": "J’imagine.",
	"OK, I will trust you for now.": "D’accord, je vais vous faire confiance pour l’instant.",
	"We hold one great advantage over the Cult. A card up our sleeve, in a manner of speaking!": "Nous détenons un grand avantage sur la Secte. Une carte dans notre manche, pour ainsi dire !",
	"Were you the Queen's official punster?": "Étiez-vous le faiseur de calembours officiel de la Reine ?",
	"The Cult does not know that the Sacred Shuffle does not choose a screen. It chooses a player. They do not know you have been chosen. They cannot know. You have to keep playing and beat a shuffle on every floor.": "La Secte ignore que le Brassage Sacré ne choisit pas un écran. Il choisit un joueur. Ils ignorent que vous avez été choisi. Ils ne peuvent pas le savoir. Vous devez continuer à jouer et vaincre un brassage à chaque étage.",
	"Ten floors. So ten games and that’s it?": "Dix étages. Donc dix parties et c’est tout ?",
	"Not quite. When you leave the building, time will reset. You will have to do it again. To put it in simple terms: we cannot do it alone. You are performing a summoning ritual.": "Pas tout à fait. Quand vous quitterez l’immeuble, le temps se réinitialisera. Vous devrez recommencer. En termes simples : nous ne pouvons y arriver seuls. Vous accomplissez un rituel d’invocation.",
	"Who I am summoning?": "Qui suis-je en train d’invoquer ?",
	"Your other patrons through the ages. People who by fate or by chance got close to the Sacred Shuffle and whose destinies were forever intertwined with the cosmic mathematics of Solitaire.": "Vos autres mécènes à travers les âges. Des gens que le destin ou le hasard a rapprochés du Brassage Sacré et dont les destinées se sont à jamais entrelacées avec les mathématiques cosmiques du Solitaire.",
	"Kings, Queens, Emperors, Prisoners, Poets and Adventures, among others.": "Des rois, des reines, des empereurs, des prisonniers, des poètes et des aventuriers, entre autres.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — Dee (third transmission, after floor 6)
	# ══════════════════════════════════════════════════════════════════════════
	"You are now more than halfway through. Take a break. Go drink some water.": "Vous avez maintenant dépassé la moitié. Faites une pause. Allez boire de l’eau.",
	"I don’t think The Cult of Doom brought any water bottles.": "Je ne crois pas que la Secte du Malheur ait apporté des bouteilles d’eau.",
	"Oh, I wasn’t talking to you.": "Oh, je ne vous parlais pas à vous.",
	"Huh?": "Hein ?",
	"Never mind. Do you have any other questions? The other Time Patrons might not be as helpful as I.": "Peu importe. Avez-vous d’autres questions ? Les autres Mécènes du Temps ne seront peut-être pas aussi obligeants que moi.",
	"You keep mentioning other Time Patrons…": "Vous ne cessez de mentionner d’autres Mécènes du Temps…",
	"Who are they?": "Qui sont-ils ?",
	"What is their connection to Solitaire?": "Quel est leur lien avec le Solitaire ?",
	"When will I meet them?": "Quand les rencontrerai-je ?",
	"Mostly nobles, kings, princesses, lords…": "Surtout des nobles, des rois, des princesses, des seigneurs…",
	"Great, I’m caught between two groups of rich people fighting for more power.": "Génial, je suis coincé entre deux bandes de riches qui se battent pour plus de pouvoir.",
	"I’m afraid that’s how human history goes. I presume it’s still the case in your time.": "Je crains que ce ne soit là le cours de l’histoire humaine. Je présume qu’il en va encore de même à votre époque.",
	"…pretty much.": "…en gros, oui.",
	"A lot of them also fell from high, found hardship, exile, captivity, and in duress, almost touched the Sacred Shuffle.": "Beaucoup d’entre eux sont aussi tombés de haut, ont connu l’épreuve, l’exil, la captivité, et, sous la contrainte, ont presque touché le Brassage Sacré.",
	"What do you mean « almost »?": "Que voulez-vous dire par « presque » ?",
	"They got close to the Sacred Shuffle by helping you find it.": "Ils se sont approchés du Brassage Sacré en vous aidant à le trouver.",
	"I’m confused.": "Je suis perdu.",
	"Time paradoxes tend to do that.": "Les paradoxes temporels ont tendance à faire cet effet.",
	"You are.": "Vous.",
	"Through Solitaire, they will talk to you from their time period, as I am doing. Through you, they are connected to the Sacred Shuffle.": "À travers le Solitaire, ils vous parleront depuis leur époque, comme je le fais. À travers vous, ils sont reliés au Brassage Sacré.",
	"Which I haven’t found yet.": "Que je n’ai pas encore trouvé.",
	"Our crude human senses can only perceive time as linear, but it is not. All of this has happened before…": "Nos sens humains grossiers ne perçoivent le temps que comme linéaire, mais il ne l’est pas. Tout ceci s’est déjà produit…",
	"…all of this will happen again. How did I know that?": "…tout ceci se reproduira. Comment ai-je su cela ?",
	"Your memory is starting to leak through time. Even if you think this is the first time we’re having this conversation, it could be the millionth time.": "Votre mémoire commence à fuir à travers le temps. Même si vous croyez que c’est la première fois que nous avons cette conversation, ce pourrait être la millionième.",
	"That’s encouraging.": "C’est encourageant.",
	"You have to contact them.": "Vous devez les contacter.",
	"How?": "Comment ?",
	"You need to generate Time Energy, but also you need to weave the threads of time, find the connections between the Time Patrons. Even I do not know their all their identities. There is one from my time...": "Vous devez générer de l’Énergie du Temps, mais aussi tisser les fils du temps, trouver les connexions entre les Mécènes du Temps. Même moi, je ne connais pas toutes leurs identités. Il y en a un de mon époque…",
	"Who?": "Qui ?",
	"Mary Stuart, Queen of the Scots.": "Marie Stuart, reine des Écossais.",
	"Don’t they teach history in your time? Never mind. Just remember her name.": "N’enseigne-t-on pas l’histoire à votre époque ? Peu importe. Retenez seulement son nom.",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — Dee final (before floor 10)
	# ══════════════════════════════════════════════════════════════════════════
	"You’re almost at the end of the loop. You’re about to face your greatest challenge yet.": "Vous touchez presque à la fin de la boucle. Vous êtes sur le point d’affronter votre plus grand défi à ce jour.",
	"Any advice?": "Un conseil ?",
	"Yes. Patience.": "Oui. De la patience.",
	"Another pun?": "Encore un jeu de mots ?",
	"No. All you need to win is patience.": "Non. Tout ce qu’il vous faut pour gagner, c’est de la patience.",
	"What if I win?": "Et si je gagne ?",
	"Go through the challenges of the Cult of Doom again, keep weaving the threads of the secret history of Solitaire and find the Sacred Shuffle!": "Traversez de nouveau les épreuves de la Secte du Malheur, continuez à tisser les fils de l’histoire secrète du Solitaire et trouvez le Brassage Sacré !",

	# ══════════════════════════════════════════════════════════════════════════
	#  Dialogue — the intro (before Dee's face appears, then the first call)
	# ══════════════════════════════════════════════════════════════════════════
	"Click. Click. Click.": "Clic. Clic. Clic.",
	"Click!": "Clic !",
	"Click! Click! Click!": "Clic ! Clic ! Clic !",
	"Click! Click!": "Clic ! Clic !",
	"You’ve done it again.": "Vous avez encore réussi.",
	"As you rub the armrests of your cheap office chair, you watch the cards bounce, bounce and bounce with profound satisfaction.": "En frottant les accoudoirs de votre chaise de bureau bon marché, vous regardez les cartes rebondir, rebondir et rebondir encore avec une profonde satisfaction.",
	"Another Solitaire game completed, and you’ve beaten your personal record at that!": "Encore une partie de Solitaire terminée, et vous avez battu votre record personnel par-dessus le marché !",
	"As the screen suddenly flickers…": "Alors que l’écran vacille soudain…",
	"You catch a glimpse of a face.": "Vous apercevez brièvement un visage.",
	"It takes a moment to realize it's yours.": "Il vous faut un instant pour comprendre que c’est le vôtre.",
	"You feel strangely compelled to keep looking at your screen, but by the corner of your eye, you notice everyone on the office floor is also mindlessly playing Solitaire.": "Vous vous sentez étrangement poussé à fixer votre écran, mais du coin de l’œil, vous remarquez que tout le monde à l’étage joue aussi machinalement au Solitaire.",
	"Eyes so dead, skin so pale, lips so dry.": "Des yeux si morts, une peau si pâle, des lèvres si sèches.",
	"And then you see them.\nWho, or what, are they?\nHow long have they been here?": "Et puis vous les voyez.\nQui, ou quoi, sont-ils ?\nDepuis combien de temps sont-ils là ?",
	"You feel like you're waking up from a long nightmare... into something worse.\n\nStartled, you ask yourself…": "Vous avez l’impression de vous réveiller d’un long cauchemar… pour tomber dans pire encore.\n\nSaisi, vous vous demandez…",
	"How long have I been playing Solitaire?": "Depuis combien de temps je joue au Solitaire ?",
	"Before you can even think of an answer, your screen flickers again.": "Avant même de songer à une réponse, votre écran vacille de nouveau.",
	"This time, you’re not looking at your face.": "Cette fois, ce n’est pas votre visage que vous regardez.",
	"It's a bearded man with a look straight out of an 17th century painting.": "C’est un homme barbu, à l’allure tout droit sortie d’un tableau du XVIIe siècle.",
	"I have definitely been playing too long…": "J’ai vraiment joué trop longtemps…",
	"Is this a feature or a bug?": "C’est une fonctionnalité ou un bogue ?",
	"The face starts talking. It’s talking to you.": "Le visage se met à parler. Il vous parle, à vous.",
	"You wonder if you’re more confused by the fact that it’s talking to you or by the fact that it somehow knows what you were thinking.": "Vous vous demandez ce qui vous trouble le plus : qu’il vous parle, ou qu’il sache d’une façon ou d’une autre ce que vous pensiez.",
	"You have been playing a long time. But that is not important for now.": "Vous jouez depuis longtemps. Mais cela n’a pas d’importance pour l’instant.",
	"Who are you?": "Qui êtes-vous ?",
	"My name is John Dee. Advisor and astrologer of Queen Elizabeth the First. I will die in 1608. From your point of view, I have been dead since 1608.": "Je m’appelle John Dee. Conseiller et astrologue de la reine Élisabeth Ire. Je mourrai en 1608. De votre point de vue, je suis mort depuis 1608.",
	"What the hell?": "Mais qu’est-ce que c’est que ça ?",
	"A peculiar phrasing, but hell indeed! Hear me now, and hear me well. I wish I had a calmer way to say this, but I do not: the fate of human civilization hangs in the balance.": "Formulation singulière, mais l’enfer, en effet ! Écoutez-moi maintenant, et écoutez-moi bien. J’aimerais pouvoir le dire plus posément, mais je ne le puis : le sort de la civilisation humaine est en jeu.",
	"The Cult of Patience has seized the counting-house where you work, through means I won’t dignify to qualify as magic. They have been making you play Solitaire repeatedly, endlessly. Has it been days? Weeks? Months? I am not sure myself.": "La Secte de la Patience s’est emparée du comptoir où vous travaillez, par des moyens que je ne m’abaisserai pas à qualifier de magie. Elle vous fait jouer au Solitaire encore et encore, sans fin. Cela fait-il des jours ? Des semaines ? Des mois ? Je n’en suis pas certain moi-même.",
	"Let’s say I believe you. Why Solitaire?": "Admettons que je vous croie. Pourquoi le Solitaire ?",
	"There are 52 cards in a standard deck in Solitaire. There are 80,658,175,170,943,878,571,660,636,856,403,\n766,975,289,505,440,883,277,824,000,000,000,000 possible arrangements.": "Il y a 52 cartes dans un jeu standard de Solitaire. Il existe 80 658 175 170 943 878 571 660 636 856 403,\n766 975 289 505 440 883 277 824 000 000 000 000 arrangements possibles.",
	"To better understand the magnitude of this number : It is more than the quantity of atoms that form the Earth.": "Pour mieux saisir l’ampleur de ce nombre : il dépasse la quantité d’atomes qui composent la Terre.",
	"Whoa.": "Ouah.",
	"There is one particular arrangement. The Sacred Shuffle. It does something extraordinary.": "Il existe un arrangement particulier. Le Brassage Sacré. Il accomplit une chose extraordinaire.",
	"It gives dominion over time, way beyond the childish dark arts the Cult currently dabbles in, and way beyond the simple time projection I am using to contact you.": "Il donne l’empire sur le temps, bien au-delà des arts sombres puérils auxquels la Secte s’adonne pour l’instant, et bien au-delà de la simple projection temporelle que j’utilise pour vous contacter.",
	"But what does all this have to do with me?": "Mais qu’est-ce que tout cela a à voir avec moi ?",
	"Only you can stop them.": "Vous seul pouvez les arrêter.",
	"Huh, OK? How?": "Euh, d’accord ? Comment ?",
	"By playing Solitaire. Repeatedly. Endlessly.": "En jouant au Solitaire. Encore et encore. Sans fin.",
	"Great.": "Génial.",
	"We will talk more later. Now, you must play or the Cult will notice you and kill you!": "Nous reparlerons plus tard. Maintenant, vous devez jouer, sinon la Secte vous remarquera et vous tuera !",
	"Play Solitaire or die!": "Jouez au Solitaire ou mourez !",

	# ══════════════════════════════════════════════════════════════════════════
	#  End / game-over screen
	# ══════════════════════════════════════════════════════════════════════════
	"You Escaped the Tower": "Vous vous êtes échappé de la Tour",
	"The Tower Keeps You": "La Tour vous garde",
	"Local High Scores": "Meilleurs scores locaux",
	"No runs recorded yet.": "Aucune partie enregistrée pour l’instant.",
	"Your name": "Votre nom",
	"RECORD SCORE": "ENREGISTRER LE SCORE",
	"NEW RUN": "NOUVELLE PARTIE",
	"TITLE": "MENU TITRE",
	"★ %d pts    ⏳ %d credits    %d/%d floors    %s": "★ %d pts    ⏳ %d crédits    %d/%d étages    %s",
	"%d pts": "%d pts",

	# ══════════════════════════════════════════════════════════════════════════
	#  Misc / toasts
	# ══════════════════════════════════════════════════════════════════════════
	"Save reset: %s": "Sauvegarde réinitialisée : %s",
}
