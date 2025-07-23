# Questions about Features and Bugs Implementation

## 1. Colors
**Question:** For Hurricane-Other, you mentioned keeping the text color but changing the background to dark grey. What is the current text color that should be kept?

**Answer:** 
The current text color is a light purple.
---

## 2. Order
**Question:** The current order appears to be: Snow, Earthquake, Hurricane-Other, Flood, Fire, Hail, Tornado, Hurricane-Florida. After the change, should it be: Earthquake, Snow, Hurricane-Other, Flood, Fire, Hail, Tornado, Hurricane-Florida?

**Answer:** 
Yes.
---

## 3. Agent of the Year Threshold
**Question:** Does this apply to all Agent of the Year cards (Agent of the Year - Earthquake, Fire, Flood, Hail, Hurricane, Snow, Tornado)?

**Answer:** 
Yes.
---

## 5. Billionaire Bailout
**Question:** Should the Billionaire Bailout checkbox state persist between app sessions like other data?

**Answer:** 
Yes.
---

## 8. Florida with the Map
**Question:** To clarify - Hurricane-Florida spaces should still display as dark purple on the map, but for all calculations (thresholds, state balancing, assignments) they should be treated as regular Hurricane spaces, correct?

**Answer:** 
Yes.
---

## 9. Diversified Agent of the Year
**Question:** For the "1 policy in every storm type" requirement, does this mean all 8 storm types (including both Hurricane-Other and Hurricane-Florida), or just 7 (treating hurricanes as one type)?

**Answer:** 
Treat hurricanes as one type.
---

## 10. Loan Card
**Question:** 
1. Should multiple loan cards be allowed to be selected?
2. If multiple loans are allowed, should each have its own VP value that can be different?
3. Should the loan card VP values persist between app sessions?

**Answer:** 
no, only one loan card may be selected.

The VP value must persist between app sessions.