# The Astrologer — Complete Redesign

> *"The stars do not command. They suggest. The rest is up to you."*

---

## Core Mechanic: The Star Chart（星盘）

### What It Is

The Star Chart is a **visible, persistent UI element** — a circular track of 6 Houses. It is not a hidden counter. The player sees it at all times during combat.

```
        [I Dawn]
   [VI Fate]    [II Noon]
   
   [V Wisdom]   [III Dusk]
        [IV Night]
```

Stars rotate **clockwise** through these houses every turn.

### The Six Houses

| House | Name | Passive Bonus | Alignment Effect |
|-------|------|---------------|------------------|
| **I** | House of Dawn | +1 Energy this turn | Double energy gain |
| **II** | House of Noon | +2 damage to all attacks | Deal damage equal to total stars × 3 |
| **III** | House of Dusk | +2 block from all skills | Gain 2× stars Block |
| **IV** | House of Night | Draw 1 extra card at turn start | Draw stars × 1 cards |
| **V** | House of Wisdom | First card played each turn is duplicated | Upgrade a random card in hand permanently |
| **VI** | House of Fate | Random bonus (+1 energy / +2 damage / +2 block / draw 1) | 🌀 Unpredictable — triggers ALL other alignment effects at half strength |

### Core Loop

```
Place Stars → Orbit → Align → Eclipse → Rebirth
```

1. **Place** — Play Constellation cards to put a Star into a specific House
2. **Orbit** — At end of each turn, every Star moves clockwise one House
3. **Align** — When 2+ Stars share a House, Alignment triggers (once per House per turn)
4. **Eclipse** — When all 6 Houses have ≥1 Star: consume all Stars, gain 3 Energy + draw 5 cards + deal 15 damage to all enemies
5. **Rebirth** — After Eclipse, the chart is empty. Begin placing again.

---

## Character Stats

| Stat | Value |
|------|-------|
| Max HP | 72 |
| Starting Energy per turn | 3 |
| Card Draw per turn | 5 |
| Starting Gold | 99 |

## Starting Deck (12 cards)

| Count | Card | Type | Cost | Effect |
|-------|------|------|------|--------|
| 4× | **Stellar Strike** | Attack | 1 | Deal 6 damage. If there is a Star in House of Noon, deal 9 instead. |
| 4× | **Stellar Guard** | Skill | 1 | Gain 5 Block. If there is a Star in House of Dusk, gain 8 instead. |
| 1× | **Place Saturn** | Skill | 1 | Place a Star in House of Dusk. Gain 4 Block. |
| 1× | **Place Mercury** | Skill | 0 | Place a Star in House of Dawn. |
| 1× | **Read the Heavens** | Skill | 1 | Scry 3. Draw 1 card. |
| 1× | **Destined Strike** | Attack | 2 | Deal 10 damage. If this kills an enemy, place a Star in House of Fate. |

## Starting Relic

**Brass Astrolabe** (reworked)
> At the start of combat, place 2 Stars in random Houses.
> At the start of each turn, all Stars rotate clockwise one House.

---

## Card Pool — 60 Cards

### ⭐ Constellation Cards (Power — "Place a Star that grants persistent effects")

*Each Constellation card places a Star AND has an ongoing effect while its Star exists.*

| # | Card | Rarity | Cost | Effect | Upgrade |
|---|------|--------|------|--------|---------|
| 1 | **Mars, the Warrior** | Uncommon | 2 | **Power.** Place a Star in House of Noon. While this Star orbits, your Attacks deal +3 damage. | +5 damage |
| 2 | **Venus, the Lover** | Uncommon | 2 | **Power.** Place a Star in House of Dusk. While this Star orbits, gain 3 Block at the start of each turn. | 5 Block |
| 3 | **Jupiter, the King** | Rare | 2 | **Power.** Place a Star in a House of your choice. While this Star orbits, you have +1 Energy each turn. | Place 2 Stars |
| 4 | **Saturn, the Teacher** | Rare | 2 | **Power.** Place a Star in House of Wisdom. While this Star orbits, when you play a card, add a temporary copy to your hand next turn. | Copy stays this turn |
| 5 | **Uranus, the Awakener** | Rare | 3 | **Power.** Place a Star in House of Fate. While this Star orbits, a random Star moves an extra House each turn. | 2 extra movements |
| 6 | **Neptune, the Dreamer** | Uncommon | 2 | **Power.** Place a Star in House of Night. While this Star orbits, draw 1 extra card at the start of your turn. | Draw 2 |
| 7 | **Pluto, the Judge** | Rare | 3 | **Power.** Place a Star in House of Fate. While this Star orbits, the first enemy killed each combat drops double gold. | Triple gold |
| 8 | **Binary Star** | Uncommon | 1 | **Power.** Place 2 Stars in the same House (triggers Alignment). Ethereal. | Not Ethereal |

### 🔮 Alignment Cards (Skill/Attack — "Trigger or interact with Star alignments")

| # | Card | Rarity | Cost | Effect | Upgrade |
|---|------|--------|------|--------|---------|
| 9 | **Celestial Alignment** | Common | 1 | **Skill.** Choose a House. If it has ≥2 Stars, trigger its Alignment effect. Exhaust. | Not Exhaust |
| 10 | **Conjunction** | Uncommon | 1 | **Skill.** Choose 2 Stars in different Houses. Move them both to the House between them. | Any 2 Stars |
| 11 | **Opposition** | Uncommon | 1 | **Attack.** If two Stars are in opposite Houses (3 apart), deal 14 damage. | 20 damage |
| 12 | **Grand Trine** | Rare | 2 | **Skill.** If Stars occupy 3 Houses that are equally spaced (2 apart), gain 2 Energy and draw 3 cards. | 3 Energy, draw 4 |
| 13 | **Stellium** | Uncommon | 2 | **Skill.** Move all Stars to the House with the most Stars. For each Star moved, gain 2 Block. | 3 Block per Star |
| 14 | **Retrograde** | Common | 0 | **Skill.** Choose a Star. It moves counter-clockwise one House. Draw 1 card. | Draw 2 |
| 15 | **Aspect** | Common | 1 | **Skill.** Look at the top 3 cards of your draw pile. You may discard any of them. Place a Star in House of Wisdom. | Look at 5 |
| 16 | **Cosmic Mirror** | Uncommon | 1 | **Skill.** Choose a House. Create a copy of the Alignment effect that would trigger there (without consuming the Stars). Exhaust. | Not Exhaust |
| 17 | **Star Swarm** | Common | 1 | **Attack.** Deal 2 damage × (number of Stars you have). | 3 damage × Stars |
| 18 | **Astral Projection** | Uncommon | 2 | **Skill.** Next turn, your Stars do not rotate (they stay in their current Houses). Ethereal. | Not Ethereal |

### 🌑 Eclipse / Rebirth Cards (Payoff — "Consume Stars for massive effect")

| # | Card | Rarity | Cost | Effect | Upgrade |
|---|------|--------|------|--------|---------|
| 19 | **Forced Eclipse** | Rare | 3 | **Skill.** Trigger Eclipse immediately: consume all Stars. Gain 2 Energy + draw 5 + deal 12 damage to all enemies for each 6 Stars consumed. | 15 damage per 6 |
| 20 | **Supernova** | Rare | 2 | **Attack.** Choose a House. Consume all Stars in that House. Deal 8 damage per Star consumed to ALL enemies. | 12 per Star |
| 21 | **Nova** | Uncommon | 1 | **Attack.** Consume 1 Star. Deal 10 damage to ALL enemies. | 15 damage |
| 22 | **Starburst** | Common | 1 | **Skill.** Consume 1 Star. Gain 6 Block and draw 2 cards. | 9 Block |
| 23 | **Cosmic Rebirth** | Rare | X | **Skill.** Consume all Stars. For each Star consumed, gain 1 Energy and place 1 new Star in a random House. Exhaust. | Stars placed in chosen Houses |
| 24 | **Heat Death** | Rare | 3 | **Attack.** Consume all Stars. Deal 5 damage per Star × (turn number). Exhaust. | 7 damage per Star |
| 25 | **Singularity** | Uncommon | 2 | **Skill.** If you have exactly 1 Star, triple all its House bonuses this turn. Exhaust. | Quadruple |
| 26 | **Constellation Shift** | Common | 0 | **Skill.** Consume 1 Star. Place 2 Stars in different Houses. | Place 3 Stars |

### ✨ Destiny / Prophecy Cards ("I see what's coming — and I change it")

| # | Card | Rarity | Cost | Effect | Upgrade |
|---|------|--------|------|--------|---------|
| 27 | **Prophecy** | Uncommon | 1 | **Skill.** Look at the top 5 cards of your draw pile. Choose 1 to put into your hand. Shuffle the rest. | Top 8, choose 2 |
| 28 | **Fate's Thread** | Common | 1 | **Skill.** Scry 5. | Scry 8 |
| 29 | **Weave Destiny** | Uncommon | 2 | **Skill.** Choose a card in your hand. It gains Retain. Next turn, it costs 0. | 0 cost this turn |
| 30 | **Predetermined Outcome** | Rare | 3 | **Skill.** Look at ALL enemy intents. Next turn, ALL enemy attacks deal 0 damage. Exhaust. | Also draw 2 |
| 31 | **Omen** | Common | 1 | **Skill.** Next turn, place a Star in a random House at start of turn. Draw 1 card. | Place 2 Stars |
| 32 | **Astral Forecast** | Common | 1 | **Skill.** Show which House will have the most Stars next turn. Gain 4 Block. | 7 Block |
| 33 | **Rewrite Fate** | Rare | 2 | **Skill.** If you would die this combat, instead heal to 1 HP and Consume all Stars. (Once per combat. This card Exhausts after it triggers.) | Heal to 25% HP |
| 34 | **Inertia** | Uncommon | 1 | **Skill.** This turn, Stars do NOT rotate. Gain 5 Block. | 8 Block |
| 35 | **Accelerate** | Uncommon | 1 | **Skill.** All Stars rotate one extra House immediately. Draw 1 card. | Rotate twice |

### 🌟 Celestial / General Cards ("The raw power of the cosmos")

| # | Card | Rarity | Cost | Effect | Upgrade |
|---|------|--------|------|--------|---------|
| 36 | **Starfall** | Common | 1 | **Attack.** Deal 7 damage. Place a Star in House of Noon. | 10 damage |
| 37 | **Moonshield** | Common | 1 | **Skill.** Gain 7 Block. Place a Star in House of Dusk. | 10 Block |
| 38 | **Solar Flare** | Uncommon | 2 | **Attack.** Deal 12 damage. ALL Stars advance one House immediately. | 16 damage |
| 39 | **Lunar Tide** | Uncommon | 2 | **Skill.** Gain 10 Block. ALL Stars move backward one House. | 14 Block |
| 40 | **Meteor Shower** | Uncommon | X | **Attack.** Deal 4 damage × X to a random enemy. Place X Stars in random Houses. | 6 damage × X |
| 41 | **Cosmic Ray** | Common | 1 | **Attack.** Deal 6 damage. Gain bonuses equal to the Houses where Stars currently sit. | 9 damage |
| 42 | **Gravity Well** | Uncommon | 2 | **Skill.** ALL enemies lose 2 Strength this turn. Place a Star in House of Night. | Lose 4 Strength |
| 43 | **Event Horizon** | Rare | 3 | **Power.** At the start of each turn, draw 1 card and place a Star in House of Night. | Draw 2 cards |
| 44 | **Zodiac Cycle** | Rare | 2 | **Power.** At the start of each turn, rotate Stars one extra House. Stars never decay. | Stars also gain +1 bonus |
| 45 | **Dark Matter** | Uncommon | 1 | **Skill.** Gain 1 Intangible. Place a Star in House of Fate. Exhaust. | Not Exhaust |
| 46 | **Celestial Shield** | Uncommon | 2 | **Skill.** Gain Block equal to (Stars × 4). | Stars × 6 |
| 47 | **Astral Strike** | Rare | 2 | **Attack.** Deal damage equal to (Stars × 5). If you have ≥5 Stars, deal double. | Stars × 7 |
| 48 | **Stardust** | Common | 1 | **Skill.** Gain 3 Block. Place a Star in a random House. | 5 Block, chosen House |

### 🃏 Build-Defining Rare Powers

| # | Card | Rarity | Cost | Effect | Upgrade |
|---|------|--------|------|--------|---------|
| 49 | **Fixed Star** | Rare | 2 | **Power.** Choose a House. The first Star placed there never rotates (stays permanently). | 2 Stars stay |
| 50 | **Retrograde Motion** | Rare | 2 | **Power.** At the start of each turn, ALL Stars rotate counter-clockwise instead of clockwise. | Choose direction each turn |
| 51 | **Grand Cross** | Rare | 3 | **Power.** If you have 4 Stars equally spaced (every other House) at the start of your turn, deal 20 damage to ALL enemies and gain 2 Energy. | 30 damage |
| 52 | **Stellar Nursery** | Rare | 2 | **Power.** At the end of each turn, if you have fewer than 3 Stars, place a Star in a random House. | Place 2 Stars |
| 53 | **Twin Destiny** | Rare | 3 | **Power.** Choose a House. ALL Alignment effects in that House trigger twice. | Triple |
| 54 | **Cosmic Inflation** | Rare | 2 | **Power.** Every time you play a card that costs 2+, place a Star in House of Dawn. | Any card |
| 55 | **Dark Nebula** | Rare | 2 | **Power.** Stars you consume deal 3 damage to a random enemy when consumed. | 5 damage |
| 56 | **Astral Resonance** | Rare | 2 | **Power.** When a Star enters House of Wisdom, add a random card from your draw pile to your hand. | Draw 2 instead |

### 🔵 Commons Pool (for draft variety)

| # | Card | Rarity | Cost | Effect | Upgrade |
|---|------|--------|------|--------|---------|
| 57 | **Quick Read** | Common | 0 | **Skill.** Scry 2. If you have a Star in House of Wisdom, draw 1 card. | Scry 3, draw 1 |
| 58 | **Orbital Strike** | Common | 1 | **Attack.** Deal 8 damage. If you have a Star in House of Noon, deal +4 damage. | 12 + 6 |
| 59 | **Dusk Barrier** | Common | 1 | **Skill.** Gain 7 Block. If you have a Star in House of Dusk, gain +4 Block. | 10 + 5 |
| 60 | **Stargazer** | Common | 1 | **Skill.** Place a Star in the House directly opposite your current most populous House. Scry 2. | Scry 4 |

### 🃏 Curse Card (Flavor)

| # | Card | Rarity | Cost | Effect |
|---|------|--------|------|--------|
| 1C | **Bad Omen** | Curse | — | **Unplayable.** At the end of your turn, if this is in your hand, remove 1 Star from the Chart. Ethereal. |

---

## Card Distribution Summary

| Rarity | Count | Types |
|--------|-------|-------|
| Starter (Basic) | 6 unique | 2 Attack, 3 Skill, 1 Skill |
| Common | 20 | 8 Attack, 10 Skill, 0 Power, 0 Curse |
| Uncommon | 18 | 4 Attack, 12 Skill, 2 Power |
| Rare | 16 | 3 Attack, 4 Skill, 9 Power |
| Curse | 1 | Curse |
| **Total (non-basic, non-curse)** | **54** | — |
| **Total playable cards** | **60** | — |

---

## Artifact Pool — 16 Relics

### Starting Relic

**Brass Astrolabe** (Basic)
> At combat start, place 2 Stars in random Houses.
> At end of each turn, all Stars rotate clockwise one House.

*This is the engine of the Star Chart. Without it, no Stars can be placed. It is always present.*

### Common Relics (4)

| Relic | Effect |
|-------|--------|
| **Star Map** | At the start of each combat, Scry 3. |
| **Lens of Clarity** | Whenever you Scry, Scry 1 additional card. |
| **Mercury's Quill** | The first Constellation card you play each combat costs 0. |
| **Comet Shard** | Whenever you consume a Star, gain 2 Block. |

### Uncommon Relics (5)

| Relic | Effect |
|-------|--------|
| **Lunar Calendar** | Every 3rd turn, Stars rotate one extra House. |
| **Jupiter's Favor** | When you place a Star, if the target House was empty, gain 1 Energy. |
| **Constellation Globe** | At combat start, choose which House gets the 2 starting Stars from Brass Astrolabe. |
| **Eclipse Prism** | When Eclipse triggers, also heal 10 HP. |
| **Saturn's Ring** | Stars in House of Dusk give +1 extra Block per Star. |

### Rare Relics (4)

| Relic | Effect |
|-------|--------|
| **Cosmic Clock** | You can see which House each Star will be in next turn. (Visual indicator on Star Chart) |
| **Nebula Gem** | When you place a Star, it comes with a second Star in the same House 50% of the time. |
| **Dark Star** | The first time each combat you would die, instead consume all Stars, heal to 1 HP, and gain 1 Intangible. (Once per run.) |
| **Zodiac Codex** | At the start of your turn, if any House has 3+ Stars, gain 1 Energy. |

### Boss Relics (3)

| Relic | Effect |
|-------|--------|
| **Heliocentric Model** | Gain 1 Energy at the start of each turn. Stars rotate counter-clockwise instead of clockwise. |
| **Telescope of Fate** | At the start of each turn, Scry 3. You may place a Star in the House of your choice. |
| **Orrery of Worlds** | When you play a Constellation card, place 1 additional Star in the same House. Gain 1 less Energy per turn. |

---

## Potion Pool — 5 Potions

| Potion | Rarity | Effect |
|--------|--------|--------|
| **Starlight Elixir** | Common | Place 2 Stars in random Houses. |
| **Alignment Tincture** | Common | Trigger the Alignment effect of a House of your choice. |
| **Eclipse in a Bottle** | Uncommon | Trigger Eclipse immediately. |
| **Cosmic Tonic** | Uncommon | Gain 2 Energy. ALL Stars rotate 2 Houses immediately. |
| **Nebula Phial** | Rare | Place a Star in every House. Ethereal cards in your hand are no longer Ethereal. |

---

## Build Archetypes

### 1. **The Aligner（对齐者）**
> *"When the stars speak, the universe listens."*

**Core**: Stack Stars in specific Houses → trigger repeated Alignments → overwhelm with value.

**Key Cards**: Stellium, Conjunction, Celestial Alignment, Binary Star, Cosmic Mirror, Twin Destiny
**Key Relics**: Nebula Gem, Zodiac Codex, Constellation Globe
**Playstyle**: Carefully position Stars to create consistent Alignment triggers. High-skill, high-reward. Every turn you're looking at the chart asking "where will they be next turn?"

### 2. **The Eclipsebringer（蚀灭者）**
> *"All light must die. Then be reborn."*

**Core**: Flood the chart with Stars → trigger Eclipse → rebuild from empty → repeat.

**Key Cards**: Stellar Nursery, Meteor Shower, Cosmic Rebirth, Forced Eclipse, Heat Death, Supernova
**Key Relics**: Eclipse Prism, Heliocentric Model
**Playstyle**: Aggressively fill the chart as fast as possible. Eclipse is your win condition — each cycle is bigger than the last. Low floor, very high ceiling. Feels like a rhythmic heartbeat: fill → burst → fill → burst.

### 3. **The Prophet（预言者）**
> *"I have seen this moment. You have already lost."*

**Core**: Scry and deck manipulation → set up perfect turns → win through inevitability.

**Key Cards**: Prophecy, Fate's Thread, Weave Destiny, Predetermined Outcome, Read the Heavens, Omen, Astral Forecast, Rewrite Fate
**Key Relics**: Star Map, Lens of Clarity, Telescope of Fate
**Playstyle**: You don't brute-force anything. You see the future and you change it. Every fight is a puzzle: find the right sequence, set it up, execute. Very high skill ceiling. Feels completely different from other StS characters — you're playing the deck, not the board.

### 4. **The Navigator（导航者）**
> *"The chart is not fixed. I choose the course."*

**Core**: Control Star movement — speed up, slow down, reverse, stop → create impossible Alignments.

**Key Cards**: Retrograde, Accelerate, Inertia, Astral Projection, Solar Flare, Lunar Tide, Zodiac Cycle, Uranus, Retrograde Motion
**Key Relics**: Lunar Calendar, Cosmic Clock, Heliocentric Model
**Playstyle**: The most technical build. You manipulate the orbit itself to create alignments that shouldn't be possible. Extremely high skill ceiling. When played perfectly, feels like you're cheating physics.

---

## Why These Builds Are Actually Different

| | Aligner | Eclipsebringer | Prophet | Navigator |
|---|---|---|---|---|
| **Win condition** | Value from repeated small bursts | Cyclical massive bursts | Inevitability through deck control | Engineered perfect turns |
| **Star Chart role** | Target for stacking | Resource for consumption | Support / prediction tool | Object of manipulation |
| **Skill floor** | Medium | Low | High | Very High |
| **Skill ceiling** | High | Medium | Very High | Extreme |
| **Feels like** | Architect | Heartbeat | Fortune teller | Physicist |
| **Plays differently?** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |

---

## What Distinguishes This from Official Characters

| Dimension | Why It's Different |
|---|---|
| **Spatial reasoning** | No StS character cares about *position*. The Star Chart introduces a spatial puzzle — "where is that Star going to be in 2 turns?" |
| **Cross-turn planning** | Most StS cards are "play now, effect now." The Astrologer is constantly setting up for 2-3 turns ahead. You're playing a timeline, not a turn. |
| **Visible state** | The Star Chart is always visible. It's not a hidden counter or stack. It's a game board within the card game. |
| **Natural rhythm** | The orbit creates a natural rhythm — you can feel the "pulse" of Stars moving. Eclipse creates a dramatic reset moment. No other character has this cadence. |
| **Risk of over-committing** | Stars take time to move. Placing a Star now means committing to a location for several turns. If the fight changes, your Stars might be in the wrong place. This creates genuine tension. |

---

## Implementation Notes

### What needs new engine code:

1. **StarChart UI** (`scripts/ui/StarChart.gd` + scene)
   - Custom UI registered on Player via `register_custom_ui("star_chart")`
   - Renders 6 Houses in a circle, shows Stars in each, highlights where Stars will be next turn
   - Animates rotation at end of turn

2. **Star Chart Data** (store in PlayerData or Global.profile_data)
   - `star_chart: Array[int]` — array of 6 ints, each = number of Stars in that House
   - Helper methods: `place_star(house)`, `consume_stars(house, count)`, `rotate_stars()`, `get_star_count()`

3. **New Card Actions**
   - `ActionPlaceStar.gd` — adds a Star to a specific House
   - `ActionConsumeStar.gd` — removes Stars from a House
   - `ActionRotateStars.gd` — rotates all Stars
   - `ActionEclipse.gd` — triggers the Eclipse effect

4. **Brass Astrolabe Artifact Script** (`scripts/artifacts/ArtifactBrassAstrolabe.gd`)
   - Connects to `player_turn_ended` to rotate Stars
   - Connects to `combat_started` to place initial Stars
   - Connects to `combat_ended` to clear Stars

5. **New Signals**
   - `star_placed(house: int)`
   - `star_consumed(house: int, count: int)`
   - `stars_rotated(old_positions, new_positions)`
   - `alignment_triggered(house: int, stars: int)`
   - `eclipse_triggered(total_stars: int)`

### What works with existing systems:

- Card framework (CardData, card play actions, validators)
- Artifact system (signals, counters, actions)
- Consumable system (actions on use)
- Status effects (for Star-related persistent buffs)
- Scry system (already exists)
- Energy, Block, Damage, Draw — all standard actions
