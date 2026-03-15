# 20260314 Changes - Questions and Implementation Plan

## Questions

### Data Model / Storm Types

Q1. Currently CA and TX are multi-storm states (CA = Fire + Earthquake, TX = Tornado + Hurricane). After this change, they become single storm types (Fire California, Tornado Texas). Should the StormType enum become: `snow, hurricaneOther, flood, fire, hail, tornado, hurricaneFlorida, fireCalifornia, tornadoTexas`? (9 types total, replacing the 8 we have minus earthquake)

Answer: Go with Snow, Flood, Hail, Hurricane, Fire, Tornado, Florida, California, Texas.

Q2. For game_config.json policy keys, what naming convention do you want? e.g. `fireCalifornia_mansion`, `tornadoTexas_house`, etc.?

Answer: whatever we use for hurricane florida, do for this.

Q3. The spreadsheet `20260314_new_values.xlsx` — does it contain all 27 policy premium/VP values (9 storm types × 3 property types)? Or just the new/changed ones? (Will review once converted to CSV)

Answer: Yes.  It also has all severities and occurrences.

### Tracker Tab

Q4. The 9 buttons — what's the desired grid layout? Currently 3×3. Proposed order:
   - Row 1: Snow, Hurricane, Flood
   - Row 2: Fire, Hail, Tornado
   - Row 3: California, Texas, Florida
   Does that work, or do you want a different arrangement?

Answer: The order from Q1 should be the order here.

Q5. Currently CA and TX buttons show gradients of their two storm colors. With the change, should California just be a darker red (darker than Fire) and Texas a darker grey (darker than Tornado)? Confirming the color doc section.

Answer: yes.

Q6. For Growth Target and Agent of the Year thresholds — do these still apply to the state-specific types? e.g., can you earn a "Fire Agent" card from Fire California policies, or only from regular Fire policies? Same question for Tornado Texas counting toward Tornado Agent.

Answer: a Fire California policy counts as a Fire policy for this.  Same as Texas, and they both work how Hurricane Florida works now.

Q7. Hurricane Florida currently counts toward Hurricane for Growth Target and Agent of the Year. Do Fire California and Tornado Texas similarly count toward their parent storm types for these cards?

Answer: yes.

### Payout Calculator

Q8. For the Fire button popup with California addition: you described buttons for "California Addition" values. The deck is 4×"5", 2×"10", 2×"0" drawn until 0. Should the popup just present all possible total addition values (0, 5, 10, 15, 20, 25, 30, etc.) as buttons? Or should we simulate the card draw mechanic (click to flip cards one at a time)?

Answer: no simulation.  for now, all possible addition values as buttons is good.

Q9. Same question for Hurricane Florida's deck (2×"+10", 2×"+20", 2×"+30") — should the popup present the 3 possible values (+10, +20, +30) as buttons?

Answer: yes.

Q10. For Texas: when the flipped card reveals another storm that has already been set as occurred, should it automatically pick up that severity? And if the other storm hasn't been set yet, should Texas payout update retroactively when that storm is later added?

Answer: yes on both.  At the end of the day, it must pay both it's tornado plus its other storm (if it occurs) regardless of order that it's clicked.

Q11. Texas edge case: if the flipped card is "Fire" and Fire was already rolled — does Tornado Texas payout = Tornado severity + Fire severity? And does this stack with Fire California if the player also has California policies?

Answer: If fire was already rolled, and Texas also has a fire, then yes, it's tornado severity + fire severity.  It has no relation to california, because a texas policy and california policy are mutually exclusive, so it'll only add the base fire in that case.  

Q12. For the "greyed out" state-specific parts when a player has no CA/TX/FL policies: does "has no policy" mean zero policies of that specific state type in the tracker? So if they have 0 Fire California policies, the California addition section is greyed out in the Fire payout popup?

Answer: yes.  

Q13. When the state-specific part is greyed out, should the user still be able to select a value (just not required), or should it be completely non-interactive?

Answer: completely non-interactive.  If that makes it harder, we can do still interactable, but that's worse.

### Cards

Q14. With earthquake removed, Diversified Agent of the Year currently requires 7+ storm types. There are now only 6 base storm types. Does Diversified now require 6 types? Or does it now count to 9 (including CA, TX, FL) and still require 7? Or some other threshold?

Answer: it requires one of the 6, with CA, TX, and FL counting towards their respective base storm types.

Q15. Are there any new cards being added (e.g., a California Agent, Texas Agent)?

Answer: no.

### Payout Config (game_config.json)

Q16. stormPayouts currently has arrays of payout amounts per storm. Do Fire California and Tornado Texas have their own stormPayouts entries, or do they use the base storm's payouts plus the addition mechanic?

Answer: base storm plus addition mechanic.

Q17. stormFrequencyD20 — Fire California triggers whenever Fire triggers, and Tornado Texas triggers whenever Tornado triggers. So they don't need their own frequency entries, correct?

Answer: yes.

Q18. stormSeverityD6 — same question. They use the base storm severity plus the card/deck addition, not their own D6?

Answer: yes.

### Map

Q19. Alaska needs to be added to the map configuration. Do you know how many spaces Alaska has on the board? And it should be Snow-only?

Answer: is alaska not currently on the map?  same for hawaii, is it just not there?

Q20. Does California change from [Earthquake, Fire] to just [Fire, FireCalifornia]? Does Texas change from [Tornado, Hurricane] to just [Tornado, TornadoTexas]?

Answer: to be clear, California is not both a fire and a fire california policy.  It's just a fire california policy (which counts as a fire policy).  Therefore, i'd assume that california is just fire california and texas is just tornado texas.

### Colors

Q21. "Flood should move to the same color as used in the mobile, house, and mansion buttons" — currently the property type buttons use a teal/dark teal color scheme. Is that the color you mean?

Answer: yes.  Color will likely require iteration but that works for now.

Q22. Tornado icon replacement — the doc mentions replacing it but doesn't say with what. Do you have a specific icon in mind?

Answer: it should look like a classic twister logo.

---

## Follow-up Questions (from answers above)

### Map - Alaska & Hawaii (from Q19)

Q23. Confirmed: neither Alaska nor Hawaii exists in the map configuration code (`map_configuration.dart`). They DO exist as shapes in the SVG map files. So both need to be added to the configuration. What storm type should Hawaii be? (Alaska = Snow per your changes doc.) And how many board spaces does each have?

Answer: alaska is snow, 1.  Hawaii fire, 1.

### Payout - California Addition Possible Values (from Q8)

Q24. For the California deck (4×"5", 2×"10", 2×"0", draw until 0), the possible totals are: 0, 5, 10, 15, 20, 25, 30. However some of these are extremely unlikely (e.g., 25 and 30 require drawing all non-zero cards). Should we show all 7 possible values as buttons, or cap it at a reasonable maximum like 20?

Answer: no, keep all 7 there.

### Payout - Texas "No Storm" Wording (from Q10)

Q25. When Texas flips "no storm", the Tornado Texas payout is just the tornado severity with no addition. In the popup, should "No Storm" be an explicit button the user selects, or should it be the default (i.e., user only picks a storm if one was flipped)?

Answer: no storm shoudl be an option that must be clicked. not a default.

### Payout - Texas Storm Flip Display (from Q10/Q11)

Q26. When a Texas storm flip matches an already-occurred storm, should the payout tab show the Texas calculation broken down (e.g., "Tornado: 20 + Fire: 30 = 50") or just the total?

Answer: the broken down is nice.

### Cards - Diversified Threshold Clarification (from Q14)

Q27. Just to confirm: Diversified Agent of the Year now requires policies in ALL 6 base storm types (was 7 of 8, now 6 of 6)? So if you have Snow, Hurricane, Flood, Fire, Hail, and Tornado (with state-specific counting toward their parent), you get it?

Answer: yes.

### Map - California and Texas Storm Assignment (from Q20)

Q28. Understood that California the state only has Fire California policies (not regular Fire). And Texas the state only has Tornado Texas policies (not regular Tornado). For the map configuration profiles, do these states still participate in the random property assignment (mansion/house/mobile home), just under their state-specific storm type?

Answer: yes, except with the button of limiting one per.  If those are clicked, then only one in that state is allowed.

### Payout - Billionaire Bailout with State Types (existing feature)

Q29. The current Billionaire Bailout checkbox excludes mansions from payout. Does this apply identically to state-specific policies? i.e., Fire California mansions are excluded, Tornado Texas mansions are excluded, Hurricane Florida mansions are excluded?

Answer: yes.

### Config - Deck Definitions in game_config.json

Q30. Should the deck compositions (Florida: 2×10, 2×20, 2×30; California: 4×5, 2×10, 2×0; Texas: 5 storms + no storm) be hardcoded or added to game_config.json so they're configurable? Given that other game values are in the config, config seems consistent — but these are unlikely to change.

Answer: yes, it should be in the config.

---

## Implementation Plan (Detailed Steps)

### Phase 1: Core Data Model + Tracker (Test checkpoint)

**1a. Remove Earthquake from StormType enum**
- Remove `earthquake` from `StormType` enum in `policy_data.dart`
- Remove all earthquake entries from `stormColors`, `stormBackgroundColors`, display names
- Remove earthquake policy keys from `game_config.json` (earthquake_mansion, earthquake_house, earthquake_mobileHome)
- Remove earthquake from `stormPayouts`, `stormFrequencyD20`, `stormSeverityD6` in config
- Remove Earthquake Agent from cards config

**1b. Add new state-specific storm types**
- Add `fireCalifornia` and `tornadoTexas` to `StormType` enum
- Add display names, colors (darker variants of fire/tornado)
- Add policy entries to `game_config.json` with new premium/VP values (from spreadsheet)
- Add stormPayouts entries if needed (pending Q16)

**1c. Update GameConfig model**
- Update `GameConfig.fromJson()` to handle new policy keys
- Add any new config fields for the card decks (Florida hurricane deck, California fire deck, Texas storm deck)
- Consider adding deck definitions to game_config.json:
  - `hurricaneFloridaDeck`: [10, 10, 20, 20, 30, 30]
  - `fireCaliforniaDeck`: [5, 5, 5, 5, 10, 10, 0, 0] (draw until 0)
  - `texasDeck`: ["snow", "hurricane", "flood", "fire", "hail", "noStorm"]

**1d. Update PolicyTrackerProvider**
- Remove earthquake logic
- Remove CA/TX multi-storm combination logic
- Add `fireCalifornia` and `tornadoTexas` as standalone tracked types
- Update `hasDiversifiedAgent()` logic (pending Q14 on threshold)
- Update Growth Target / Agent of Year logic for new types (pending Q6/Q7)

**1e. Update Tracker Screen (tracker_v3_screen.dart)**
- Change from gradient CA/TX buttons to single-color buttons
- Update grid layout to 9 buttons (3×3) with new arrangement
- Update button colors per new color scheme
- Update Alaska in any tracker-related map references

**1f. Update premium/VP values**
- Parse spreadsheet CSV and update all values in `game_config.json`
- Verify totals match expected values

**1g. Update map configuration**
- Change Alaska from earthquake (or add Alaska) as Snow
- Update California storm types
- Update Texas storm types
- Update `map_configuration.dart` state definitions

**1h. Update colors**
- Fire California: darker red than Fire
- Tornado Texas: darker grey than Tornado
- Flood: change to match property button color (pending Q21)

### Phase 2: Cards + Payout (Test checkpoint)

**2a. Update Cards Screen**
- Remove Earthquake Agent card
- Update Diversified Agent of the Year requirements (pending Q14)
- Add any new agent cards if applicable (pending Q15)

**2b. Update CardsProvider**
- Remove earthquake card logic
- Update diversified calculation

**2c. Update Payout Calculator - basic storms**
- Remove earthquake button
- Reduce to 6 base storm buttons (Snow, Hurricane, Flood, Fire, Hail, Tornado)
- Verify Snow, Flood, Hail work unchanged

**2d. Update Payout Calculator - Fire with California**
- Modify Fire severity popup to include California Addition section
- Add California addition buttons (possible values from deck)
- Grey out California section when player has 0 Fire California policies
- Calculate: Fire California payout = base severity + California addition
- Regular Fire policies still use just base severity

**2e. Update Payout Calculator - Hurricane with Florida**
- Replace current auto-2x Florida logic with new deck mechanic
- Add Florida addition buttons (+10, +20, +30) to Hurricane popup
- Grey out Florida section when player has 0 Hurricane Florida policies
- Calculate: Hurricane Florida payout = base severity + Florida card value

**2f. Update Payout Calculator - Tornado with Texas**
- Add Texas storm flip section to Tornado popup (6 options: 5 storms + no storm)
- Grey out Texas section when player has 0 Tornado Texas policies
- If flipped storm was also rolled: Tornado Texas payout = Tornado severity + that storm's severity
- If flipped storm was NOT rolled: Tornado Texas payout = Tornado severity only
- Handle bidirectional updates (Texas set before/after the other storm)
- This is the most complex payout change — needs careful state management

**2g. Update PayoutCalculatorProvider**
- Add state for California addition, Florida addition, Texas flipped storm
- Add calculation logic for state-specific payouts
- Handle Texas dynamic recalculation

### Phase 3: Map + Icon (Test checkpoint)

**3a. Update map SVG/configuration**
- Change Alaska to Snow in map data
- Update any visual indicators on map

**3b. Replace Tornado icon**
- Swap icon asset (pending Q22 on which icon)

### Phase 4: Insolvency Calculator (if time permits)

**4a. Update insolvency algorithm**
- Remove earthquake from probability calculations
- Add Fire California, Tornado Texas probability distributions
- California: Fire probability × card draw distribution
- Texas: Tornado probability × conditional storm probability
- Florida: Hurricane probability × card draw distribution
- This requires significant rework of the convolution logic

**4b. Update Insolvency UI**
- Remove earthquake severity input
- Add any new inputs needed for state-specific policies
