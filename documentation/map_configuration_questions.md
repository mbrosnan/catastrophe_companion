# Map Configuration Implementation Questions

After analyzing the map configuration notes, here are the clarification questions before implementation:

## 1. File Format Clarification
- The notes mention both `.json` and `.md` files for profiles. Which format should we use? JSON seems more appropriate for structured data.
JSON is fine.

## 2. Algorithm Clarification
- How exactly should the "acceptable storm difference" constraint work during assignment? Should it:
  - Prevent any assignment that would exceed the difference?
  Yes, during the "randomization", it will not allow this
  - Rebalance after all assignments?
  - Use a priority queue to ensure balance during assignment?

## 3. Multi-Storm States
- For TX (Tornado + Hurricane) and CA (Fire + Earthquake), when counting for storm balance, do they count as 1 token for each storm type? This could make balancing challenging.
yes, so TX counts as 1 tornado and 1 hurricane.  they can only be drawn if there are enough tokens available to keep the proper balance.  i leave the algorithm on this to you.

## 4. Hurricane Types
- The notes mention "Hurricane (Florida)" is separate but treated as regular Hurricane for assignment. Should we track these separately in the output?
no.  just show Florida as a state in the output.

## 5. Empty Spaces
- How should we handle states that don't get assigned all their available spaces? Should the output indicate which states have empty spaces?
Sure, make a 3rd output with empty states.

## 6. UI/UX Questions
- Should the output show a visual map or just lists?
right now, it's a list.  eventually it will be a visual map.  can you let me know how difficult adding a map would be?  I have a picture of the gameboard with the spots on it.
- Should users be able to manually adjust assignments after generation?
No.
- Should we show running totals by storm type?
No.

## 7. Persistence
- Should generated configurations be saveable/loadable for game sessions?
No, they shouldn't have to persist across app quits, but they should persist if you navigate away from the screen and back to it.

## 8. Edge Cases
- What if the number of tokens requested exceeds available spaces?
Popup error.
- What if storm balancing is impossible with the given constraints and weights?
Popup error.

## 9. Weight Interpretation
- Are weights relative probabilities? (e.g., weight 2.0 is twice as likely as 1.0)
yes.
- How do we handle very low weights (0.2) - should there be a minimum threshold?
no.