class_name Narrative
extends RefCounted

## Story content, extracted from index.html rather than retyped.
##
## The source arrays were evaluated with Node and converted mechanically, so
## every line of dialogue and every bio paragraph matches the web build exactly.
## Only two transformations were applied: image filenames became res:// paths,
## and <br> became a real newline, since Godot Labels take plain text not HTML.
##
## PATRONS + LORE make the compendium. Each John Dee interlude is a run of intro
## beats followed by player-chosen topics.

const PATRONS := [
		{
			"id": "johndee",
			"name": "John Dee",
			"img": "res://assets/patrons/john_dee.jpg",
			"unlocked": true,
			"revealed": true,
			"year": 1564,
			"links": [
				"marie"
			],
			"bio": [
				"John Dee was the most accomplished intellectual of Elizabethan England — a mathematician, cartographer, astronomer, and the personal astrologer of Queen Elizabeth I. It was Dee who calculated the most auspicious date for her coronation. His library at Mortlake was the largest private collection in England, until a mob ransacked it.",
				"He spent years trying to communicate with angels through a crystal ball and a medium named Edward Kelley, recording these conversations in an elaborate cipher. His notation system — Enochian, the supposed language of angels — became a cornerstone of Western occultism.",
				"Dee also traveled undercover as an intelligence agent for Elizabeth's court. He signed his correspondence to the queen \"007\" — the two zeros representing a spy's watching eyes, the seven a lucky number."
			],
			"lore_unlocked": false,
			"connection_cost": 500,
			"lore": [
				"Legend has it that Dee visited Mary, Queen of Scots during her captivity — perhaps at Chartley or Fotheringhay — and taught her a card layout he presented as a method of divination. The game was supposedly meant to occupy her mind through the long nights before her execution.",
				"More deeply, Dee believed the universe itself was encoded — that behind the apparent randomness of the cards lay a divine mathematical order. He was the first to suspect that the Sacred Shuffle was no accident, but a door."
			]
		},
		{
			"id": "marie",
			"name": "The Other Queen",
			"true_name": "Mary, Queen of Scots",
			"img": "res://assets/patrons/mary_stuart_portrait.png",
			"unlocked": false,
			"revealed": false,
			"in_development": true,
			"patron_unlock_cost": 1000,
			"year": 1567,
			"links": [
				"johndee"
			],
			"bio": [
				"Mary became Queen of Scotland when she was just six days old, after her father, James V, died in 1542. Because she was an infant, Scotland was ruled by regents while Mary spent much of her childhood in France, where she was raised at the French court and eventually married the Dauphin, François. When he became King of France in 1559, Mary was briefly Queen of both Scotland and France — but François died only a year later, in 1560, leaving her a widow at eighteen.",
				"Mary returned to Scotland in 1561 to rule in person, landing in a country deeply divided by the Protestant Reformation, while she herself remained Catholic. Her reign was turbulent: she married her cousin Henry Stuart, Lord Darnley, in 1565, and the marriage quickly soured amid political plotting and violence, including Darnley's involvement in the murder of Mary's secretary, David Rizzio. Darnley himself was murdered in 1567, and Mary's swift marriage afterward to James Hepburn, Earl of Bothwell — widely suspected in Darnley's death — scandalized the nobility and triggered a rebellion.",
				"Forced to abdicate in favor of her infant son (who became James VI of Scotland, and later James I of England), Mary fled to England in 1568, seeking the protection of her cousin, Queen Elizabeth I. Instead, Elizabeth had her held in a long series of confinements lasting nearly two decades. Mary became a magnet for Catholic plots aiming to depose Elizabeth and place Mary on the English throne — most damningly the Babington Plot of 1586, in which intercepted letters appeared to show Mary endorsing Elizabeth's assassination. Tried and convicted of treason, Mary was executed at Fotheringhay Castle in February 1587.",
				"Her son James VI later united the crowns of Scotland and England as James I, making Mary, in a sense, the ancestress of the joint British monarchy — a final ironic twist to a reign defined by intrigue, religious conflict, and tragedy."
			]
		},
		{
			"id": "king",
			"name": "The Sun King",
			"unlocked": false,
			"revealed": false,
			"year": 1660
		},
		{
			"id": "lion",
			"name": "The Old Lion",
			"unlocked": false,
			"revealed": false,
			"year": 1190
		},
		{
			"id": "unknown1",
			"name": "The Emperor",
			"unlocked": false,
			"revealed": false,
			"year": 1804
		},
		{
			"id": "unknown2",
			"name": "The Prisoner",
			"unlocked": false,
			"revealed": false,
			"year": 1789
		}
	]

const LORE := [
		{
			"id": "cult",
			"name": "The Cult of Patience",
			"img": "res://assets/patrons/cult_of_patience.jpg",
			"unlocked": true,
			"revealed": true,
			"year": 1650,
			"bio": [
				"The Cult of Patience is an organization whose origins date back at least to the 17th century — perhaps further. Its members share one core conviction: the Sacred Shuffle exists, it is attainable, and whoever possesses it possesses time itself.",
				"Unlike the Historical Figures, who guard the secret out of caution and respect, the Cult wants it for domination. They do not seek to understand Solitaire — they seek to exploit it."
			],
			"strategy_title": "The Digitization Strategy",
			"strategy": [
				"The digitization of Solitaire in the 1990s was seen by the Cult as a historic windfall. For the first time, millions of games could be played simultaneously, by ordinary people, unaware of what they were searching for.",
				"Their current plan is brutally simple: seize a building — an office tower, a building full of digital workers — and force its occupants to play Solitaire continuously, around the clock. By the sheer law of large numbers, the Sacred Shuffle will eventually appear on one of the screens."
			]
		}
	]

const DEE_DIALOGUE := [
		{
			"speaker": "scene",
			"img": "res://assets/intro/intro_click_1.png",
			"text": "Click. Click. Click.",
			"next_label": "Click!"
		},
		{
			"speaker": "scene",
			"img": "res://assets/intro/intro_click_2.png",
			"text": "Click! Click! Click!",
			"next_label": "Click! Click!"
		},
		{
			"speaker": "scene",
			"img": "res://assets/intro/intro_click_3.png",
			"text": "You’ve done it again."
		},
		{
			"speaker": "scene",
			"img": "res://assets/intro/intro_bounce.png",
			"text": "As you rub the armrests of your cheap office chair, you watch the cards bounce, bounce and bounce with profound satisfaction."
		},
		{
			"speaker": "scene",
			"img": "res://assets/intro/intro_bounce.png",
			"text": "Another Solitaire game completed, and you’ve beaten your personal record at that!"
		},
		{
			"speaker": "scene",
			"img": "res://assets/intro/intro_bounce.png",
			"flicker_img": "res://assets/intro/intro_face_glimpse.jpg",
			"text": "As the screen suddenly flickers…"
		},
		{
			"speaker": "scene",
			"img": "res://assets/intro/intro_face_glimpse.jpg",
			"text": "You catch a glimpse of your face."
		},
		{
			"speaker": "scene",
			"img": "res://assets/intro/intro_eyes_zoom.jpg",
			"no_crop": true,
			"text": "You’ve never seen eyes so dead."
		},
		{
			"speaker": "scene",
			"text": "You feel strangely compelled to keep looking at your screen, but by the corner of your eye, you notice everyone on the office floor is also mindlessly playing Solitaire."
		},
		{
			"speaker": "scene",
			"imgs": [
				"res://assets/intro/intro_mouth_pixel.png",
				"res://assets/intro/intro_eyes_pixel.png",
				"res://assets/intro/intro_office_worker_1.png",
				"res://assets/intro/intro_office_worker_2.png"
			],
			"arranged": true,
			"text": "Eyes so dead, skin so pale, lips so dry."
		},
		{
			"speaker": "scene",
			"img": "res://assets/intro/intro_cult.jpg",
			"text": "And then you see them.\nWho, or what, are they?\nHow long have they been here?"
		},
		{
			"speaker": "scene",
			"text": "Startled, you ask yourself…"
		},
		{
			"speaker": "you",
			"choices": [
				"How long have I been playing Solitaire?"
			]
		},
		{
			"speaker": "scene",
			"text": "Before you can even think of an answer, your screen flickers again."
		},
		{
			"speaker": "scene",
			"text": "This time, you’re not looking at your face."
		},
		{
			"speaker": "dee",
			"scene": true,
			"text": "It’s definitely a face, though. A bearded man with a look straight out of an 17th century painting."
		},
		{
			"speaker": "you",
			"choices": [
				"I have definitely been playing too long…",
				"Is this a feature or a bug?"
			]
		},
		{
			"speaker": "dee",
			"scene": true,
			"text": "The face starts talking. It’s talking to you."
		},
		{
			"speaker": "dee",
			"scene": true,
			"text": "You wonder if you’re more confused by the fact that it’s talking to you or by the fact that it somehow knows what you were thinking."
		},
		{
			"speaker": "dee",
			"text": "You have been playing a long time. But that is not important for now."
		},
		{
			"speaker": "you",
			"text": "Who?"
		},
		{
			"speaker": "dee",
			"text": "My name is John Dee. Advisor and astrologer of Queen Elizabeth the First. I will die in 1608. From your point of view, I have been dead since 1608."
		},
		{
			"speaker": "you",
			"text": "What?"
		},
		{
			"speaker": "dee",
			"text": "Hear me now, and hear me well. I wish I had a calmer way to say this, but I do not: the fate of human civilization hangs in the balance."
		},
		{
			"speaker": "dee",
			"text": "A cult has seized the counting-house where you work, through means I won’t dignify to qualify as magic. They have been making you play Solitaire repeatedly, endlessly. Has it been days? Weeks? Months? I am not sure myself."
		},
		{
			"speaker": "you",
			"choices": [
				"Let’s say I believe you. Why Solitaire?"
			]
		},
		{
			"speaker": "dee",
			"text": "There are 52 cards in a standard deck in Solitaire. There are 80,658,175,170,943,878,571,660,636,856,403,\n766,975,289,505,440,883,277,824,000,000,000,000 possible arrangements."
		},
		{
			"speaker": "dee",
			"text": "To better understand the magnitude of this number : It is more than the quantity of atoms that form the Earth."
		},
		{
			"speaker": "you",
			"text": "Whoa."
		},
		{
			"speaker": "dee",
			"text": "There is one particular arrangement. The Sacred Shuffle. It does something extraordinary."
		},
		{
			"speaker": "dee",
			"text": "It gives dominion over time, way beyond the childish dark arts the Cult currently dabbles in, and way beyond the simple time projection I am using to contact you."
		},
		{
			"speaker": "dee",
			"text": "They have been trying to play the Sacred Shuffle for centuries. In the shadows."
		},
		{
			"speaker": "you",
			"text": "What’s different now?"
		},
		{
			"speaker": "dee",
			"text": "The Digital Age."
		},
		{
			"speaker": "dee",
			"text": "A single game of cards, dealt and shuffled by hand, takes no small measure of time to set in order and play to its end. With these machines of your time, hundreds, thousands shuffles can be generated and played in mere seconds."
		},
		{
			"speaker": "you",
			"text": "Makes sense. But what does all this have to do with me?"
		},
		{
			"speaker": "dee",
			"text": "You are destined to play the Sacred Shuffle."
		},
		{
			"speaker": "you",
			"text": "Great, so we’ve already won in the future?"
		},
		{
			"speaker": "dee",
			"text": "No. Some things are written. Others remain in ceaseless... shuffle."
		},
		{
			"speaker": "you",
			"text": "Ha."
		},
		{
			"speaker": "dee",
			"text": "You WILL play the Sacred Shuffle. But, who will profit from it? The Cult? You? Humanity?"
		},
		{
			"speaker": "you",
			"text": "You?"
		},
		{
			"speaker": "dee",
			"text": "I’m afraid you have no choice but to trust me."
		},
		{
			"speaker": "you",
			"choices": [
				"...",
				"I guess",
				"OK, I trust you for now."
			]
		},
		{
			"speaker": "dee",
			"text": "We hold one great advantage over the Cult. A card up our sleeve, in a manner of speaking!"
		},
		{
			"speaker": "you",
			"text": [
				"Were you the Queen's official punster?"
			]
		},
		{
			"speaker": "dee",
			"text": "The Cult does not know that the Sacred Shuffle does not choose a screen. It chooses a player. They do not know you have been chosen. They cannot know."
		},
		{
			"speaker": "you",
			"text": "Alright. How do I stop them?"
		},
		{
			"speaker": "dee",
			"text": "By playing Solitaire. Repeatedly. Endlessly."
		},
		{
			"speaker": "you",
			"text": "Great."
		},
		{
			"speaker": "dee",
			"text": "More precisely, you have to beat a shuffle on every floor."
		},
		{
			"speaker": "you",
			"text": "Ten floors. So ten games and that’s it?"
		},
		{
			"speaker": "dee",
			"text": "Not quite. When you leave the building, time will reset. You will have to do it again. To put it in simple terms : we cannot do it alone. You are performing a summoning ritual."
		},
		{
			"speaker": "you",
			"text": "To summon whom?"
		},
		{
			"speaker": "dee",
			"text": "Your other patrons through the ages. People who by fate or by chance got close to the Sacred Shuffle and whose destinies were forever intertwined with the cosmic mathematics of Solitaire."
		},
		{
			"speaker": "dee",
			"text": "Kings, Queens, Emperors, Prisoners, Poets and Adventures, among others."
		},
		{
			"speaker": "dee",
			"text": "Enough talk, you’ll understand as you go."
		},
		{
			"speaker": "dee",
			"text": "Move through time, move through space, beat the odds, generate time energy."
		},
		{
			"speaker": "dee",
			"text": "Play Solitaire."
		}
	]

const VICTORY_LINES := [
		"You have shown why you were chosen by the Sacred Shuffle. I am afraid, though, this journey is only beginning.",
		"Our victory over the Cult will only be complete when all Time Patrons are revealed."
	]

const VICTORY_CHOICES := [
		"Alright, reset time!",
		"I just want to go home."
	]

const VICTORY_RESPONSES := [
		"That is the spirit!",
		"Not until our work is done."
	]

const DEE_CHECKIN_INTRO := [
		{
			"speaker": "dee",
			"text": "You are doing well. You have a moment’s respite. If you have any questions, I will answer them to the extent of my knowledge."
		}
	]

const DEE_CHECKIN_TOPICS := [
		{
			"id": "who",
			"question": "Who are these guys, anyway?",
			"beats": [
				{
					"speaker": "dee",
					"text": "They call themselves the Cult of Patience. I call them the Cult of Doom."
				},
				{
					"speaker": "dee",
					"text": "The earlier traces of their existence date back to the 17th century, but they may have existed even before then."
				},
				{
					"speaker": "you",
					"text": "Who’s behind the masks?"
				},
				{
					"speaker": "dee",
					"text": "Nobility rejects, revolution survivors, ex-political prisoners. People who fell from high, in terms of their position in society. Their obsessive need for wealth, power and stature has twisted their minds beyond recognition."
				},
				{
					"speaker": "dee",
					"text": "They have extended their lives with dangerous dark arts. The longer they live, the less human they become. Only the obsession remains."
				},
				{
					"speaker": "dee",
					"text": "Their masks are not meant to hide their identity, they’re meant to hide from themselves their own hideous faces."
				}
			]
		},
		{
			"id": "why",
			"question": "Why do they want the Sacred Shuffle?",
			"beats": [
				{
					"speaker": "dee",
					"text": "Time and change are their enemies. They believe the Sacred Shuffle can take them back to a time where they were at the height of their power, and keep them there, forever."
				},
				{
					"speaker": "you",
					"text": "They want to make everything great again, huh."
				},
				{
					"speaker": "dee",
					"text": "Hardly. Time would be broken. It would no longer pass. They would be princes, kings, emperors, in their own individual timeloops. At least, that’s my theory. It’s better to not find out."
				},
				{
					"speaker": "you",
					"text": "I get the picture; everyone else would be their NPCs."
				},
				{
					"speaker": "dee",
					"text": "NPC?"
				},
				{
					"speaker": "you",
					"text": "Never mind."
				}
			]
		},
		{
			"id": "involved",
			"question": "Why are you involved in all this?",
			"beats": [
				{
					"speaker": "dee",
					"text": "I have been studying the history of and variants of the game you call Solitaire since my years spent in Rudolf II’s court in Prague, the center of Kabbalistic scholarship."
				},
				{
					"speaker": "dee",
					"text": "Another name Solitaire goes by is Patience. The Scandinavian word for patience is kabale."
				},
				{
					"speaker": "dee",
					"text": "While it did become a game of patience for the impatient, it’s roots lie in divination. You could say I have a passion for ciphers, secret languages, the mathematical codes that rule the cosmos."
				},
				{
					"speaker": "dee",
					"text": "As I came to understand the powers of a deck of cards, I managed to establish connections through time with other souls who became aware of the existence of the Sacred Shuffle, and shared my concern about the Cult of Doom."
				},
				{
					"speaker": "you",
					"text": "Like a group of super good guys."
				},
				{
					"speaker": "dee",
					"text": "Good? Don’t fool yourself into thinking I operate in the name of good, or that any other of the Time Patrons have good intentions. We each have our own incentives."
				},
				{
					"speaker": "you",
					"text": "Like what?"
				},
				{
					"speaker": "dee",
					"text": "Wealth, power and stature."
				},
				{
					"speaker": "you",
					"text": "…"
				},
				{
					"speaker": "dee",
					"text": "The only difference between the Time Patrons and the Cult of Doom is that we accept time and change, and rather achieve wealth, power and stature by the natural order of things."
				},
				{
					"speaker": "you",
					"text": "And by NOT destroying human civilization as we know it."
				},
				{
					"speaker": "dee",
					"text": "You can trust that, but don’t trust anybody."
				}
			]
		}
	]

const DEE_DIALOGUE3_INTRO := [
		{
			"speaker": "dee",
			"text": "You are now more than halfway through. Take a break. Go drink some water."
		},
		{
			"speaker": "you",
			"text": "I don’t think The Cult of Doom brought any water bottles."
		},
		{
			"speaker": "dee",
			"text": "Oh, I wasn’t talking to you."
		},
		{
			"speaker": "you",
			"text": "Huh?"
		},
		{
			"speaker": "dee",
			"text": "Never mind. Do you have any other questions? The other Time Patrons might not be as helpful as I."
		},
		{
			"speaker": "you",
			"text": "You keep mentioning other Time Patrons…"
		}
	]

const DEE_DIALOGUE3_TOPICS := [
		{
			"id": "who",
			"question": "Who are they?",
			"beats": [
				{
					"speaker": "dee",
					"text": "Mostly nobles, kings, princesses, lords…"
				},
				{
					"speaker": "you",
					"text": "Great, I’m caught between two groups of rich people fighting for more power."
				},
				{
					"speaker": "dee",
					"text": "I’m afraid that’s how human history goes. I presume it’s still the case in your time."
				},
				{
					"speaker": "you",
					"text": "…pretty much."
				},
				{
					"speaker": "dee",
					"text": "A lot of them also fell from high, found hardship, exile, captivity, and in duress, almost touched the Sacred Shuffle."
				},
				{
					"speaker": "you",
					"text": "What do you mean « almost »?"
				},
				{
					"speaker": "dee",
					"text": "They got close to the Sacred Shuffle by helping you find it."
				},
				{
					"speaker": "you",
					"text": "I’m confused."
				},
				{
					"speaker": "dee",
					"text": "Time paradoxes tend to do that."
				}
			]
		},
		{
			"id": "connection",
			"question": "What is their connection to Solitaire?",
			"beats": [
				{
					"speaker": "dee",
					"text": "You are."
				},
				{
					"speaker": "you",
					"text": "…"
				},
				{
					"speaker": "dee",
					"text": "Through Solitaire, they will talk to you from their time period, as I am doing. Through you, they are connected to the Sacred Shuffle."
				},
				{
					"speaker": "you",
					"text": "Which I haven’t found yet."
				},
				{
					"speaker": "dee",
					"text": "Our crude human senses can only perceive time as linear, but it is not. All of this has happened before…"
				},
				{
					"speaker": "you",
					"text": "…all of this will happen again. How did I know that?"
				},
				{
					"speaker": "dee",
					"text": "Your memory is starting to leak through time. Even if you think this is the first we’re having this conversation, it could be the millionth time."
				},
				{
					"speaker": "you",
					"text": "That’s encouraging."
				}
			]
		},
		{
			"id": "when",
			"question": "When will I meet them?",
			"beats": [
				{
					"speaker": "dee",
					"text": "You have to contact them."
				},
				{
					"speaker": "you",
					"text": "How?"
				},
				{
					"speaker": "dee",
					"text": "You need to generate Time Energy, but also you need to weave the threads of time, find the connections between the Time Patrons. Even I do not know their identities, except one."
				},
				{
					"speaker": "you",
					"text": "Who?"
				},
				{
					"speaker": "dee",
					"text": "Mary Stuart, Queen of the Scots."
				},
				{
					"speaker": "you",
					"text": "Who?"
				},
				{
					"speaker": "dee",
					"text": "Don’t they teach history in your time? Never mind. Just remember her name."
				}
			]
		}
	]

const DEE_FINAL := [
		{
			"speaker": "dee",
			"text": "You’re almost at the end of the loop. You’re about to face your greatest challenge yet."
		},
		{
			"speaker": "you",
			"text": "Any advice?"
		},
		{
			"speaker": "dee",
			"text": "Yes. Patience."
		},
		{
			"speaker": "you",
			"text": "Another pun?"
		},
		{
			"speaker": "dee",
			"text": "No. All you need to win is patience."
		},
		{
			"speaker": "you",
			"text": "What if I win?"
		},
		{
			"speaker": "dee",
			"text": "Go through the challenges of the Cult of Doom again, keep weaving the threads of the secret history of Solitaire and find the Sacred Shuffle!"
		}
	]
