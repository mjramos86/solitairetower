# Klondike Scoring — Solitaire Tower of Doom

## Per-Card Scoring System

Each card has a **maximum of 20 points** it can contribute. Points accumulate through stages:

| Action | Points | Notes |
|--------|--------|-------|
| **Waste → Tableau** | **+5** | Moving a card from waste to a tableau column |
| **Waste → Foundation** | **+5** | Waste bonus (same as waste→tab), then foundation remainder |
| **Reveal face-down card** | **+5** | When a tableau move exposes a hidden card |
| **Card → Foundation** | **up to +20** | Awards `20 - already_earned` for that card |

### Examples

- Card dealt face-up in tableau → moved to foundation: earns **20 pts** (0 prior + 20 foundation)
- Card drawn from waste → played to tableau (+5) → later moved to foundation (+15) = **20 pts**
- Card revealed face-down (+5) → moved to foundation (+15) = **20 pts**
- Card drawn from waste (+5) → played to tableau, revealing hidden card → moved to foundation (+15) = **20 pts** for moved card + **5 pts** for revealed card

### Totals

- **Perfect game**: 52 cards × 20 pts = **1,040 pts** (from card scoring alone)
- **Floor clear bonus**: +100 × (10 - floor) — awarded separately when advancing

## Progress Bar

A gold progress bar below the instruction line shows `current / 1040` card points earned.

## Things That Do NOT Score

| Action | Points |
|--------|--------|
| Drawing from Stock | 0 |
| Reshuffling Stock | 0 |
| Moving between Tableau columns | 0 |
| Undo | 0 |
| Moving from Foundation back to Tableau | 0 |

Score can never go below **0**.
