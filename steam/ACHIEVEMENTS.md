# Steam Achievements — setup

The game grants achievements through GodotSteam (`SteamManager.unlock_achievement`).
For an unlock to actually appear, each achievement below must first be **created in
the Steamworks partner site** with the **exact API Name** listed here.

Where: Steamworks → your app (5007930) → **Stats & Achievements → Achievements**.
For each row: set the *API Name* exactly as shown, fill *Display Name* and
*Description*, upload the two icons (achieved + locked, 256×256 PNG), then
**publish** the Stats & Achievements changes to the live branch.

The game code is the source of truth for the API Names (see
`godot/scripts/autoload/achievements.gd`, the `CATALOG` const). If you change a
name here, change it there too.

| API Name | Display Name | Description | How it unlocks |
|---|---|---|---|
| `ACH_MEET_JOHN_DEE`   | The original 007          | Meet John Dee.                                              | Completing John Dee's first-contact dialogue (start of a run). |
| `ACH_FIRST_CONNECTION`| Why Solitaire?            | Uncover any Time Patron's connection to Solitaire.          | Spend Time Energy in the compendium to uncover a connection thread. |
| `ACH_CHANGE_CARDBACK` | Make yourself at home     | Change your card back.                                      | Select a card back other than the default in the card-back screen. |
| `ACH_REVEAL_MARY`     | The other Queen           | Unlock Mary Stuart as a Time Patron.                        | Mary is revealed when John Dee's connection is uncovered. |
| `ACH_KLONDIKE_MASTER` | Klondike Master           | Win 100 Klondike games.                                     | Clear 100 Klondike floors (lifetime, across slots is per-save). |
| `ACH_SPIDER_MASTER`   | Spider Master             | Win 100 Spider games.                                       | Clear 100 Spider floors. |
| `ACH_TRIPEAKS_MASTER` | Tripeaks Master           | Win 100 TriPeaks games.                                     | Clear 100 TriPeaks floors. |
| `ACH_PYRAMID_MASTER`  | Pyramid Master            | Win 100 Pyramid games.                                      | Clear 100 Pyramid floors. |
| `ACH_FREECELL_MASTER` | Freecell Master           | Win 10 FreeCell games.                                      | Clear 10 FreeCell floors. |
| `ACH_PATIENCE`        | Patience is all you need  | Win 25 FreeCell games.                                      | Clear 25 FreeCell floors. |
| `ACH_SACRED_SHUFFLE`  | A sacred Destiny          | Find the Sacred Shuffle.                                    | **Not wired yet** — the Sacred Shuffle feature is not in the game. Create it now (hidden), wire the trigger when the feature ships. |

## Notes

- **Retroactive:** `Achievements.refresh()` re-derives the win-count and
  profile-based achievements from the save on load, slot switch, and after each
  triggering action — so a returning player unlocks whatever their existing
  progress already earns the next time the profile is evaluated.
- **No double popups:** the game does not show its own toast on unlock; Steam
  shows its own banner. When Steam is not running, nothing is shown (dev/CI).
- **Win = clearing a floor** of that variant. Wins are counted per save slot in
  `game_stats[type]["won"]`; the Steam achievement itself is per Steam account.
- **`ACH_SACRED_SHUFFLE`** should be marked **Hidden** in Steamworks until the
  feature exists, so its description doesn't spoil an unimplemented mechanic.
- Testing locally: run the Steam client, keep `steam_appid.txt` (5007930) next to
  the executable, and the unlocks fire live. `steamShutdown`/`storeStats` are
  handled by the game.
