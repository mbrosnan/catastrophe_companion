# Questions and Answers for Catastrophe Companion Implementation

## Data & Game Mechanics

### What are the specific premium and victory point values for each of the 24 policy combinations?
<!-- Please fill in the values for each combination -->
Snow + Mansion: premium=10, victory=-3
Snow + House: premium=8, victory=4
Snow + Mobile Home: premium=4, victory=7
Earthquake + Mansion: premium=4, victory=0
Earthquake + House: premium=3, victory=3
Earthquake + Mobile Home: premium=2, victory=4
Hurricane-Other + Mansion: premium=9, victory=-2
Hurricane-Other + House: premium=7, victory=4
Hurricane-Other + Mobile Home: premium=4, victory=6
Flood + Mansion: premium=9, victory=-2
Flood + House: premium=7, victory=4
Flood + Mobile Home: premium=4, victory=6
Fire + Mansion: premium=10, victory=-3
Fire + House: premium=8, victory=4
Fire + Mobile Home: premium=4, victory=7
Hail + Mansion: premium=12, victory=-3
Hail + House: premium=10, victory=5
Hail + Mobile Home: premium=5, victory=8
Tornado + Mansion: premium=16, victory=-4
Tornado + House: premium=12, victory=7
Tornado + Mobile Home: premium=7, victory=10
Hurricane-Florida + Mansion: premium=18, victory=-6
Hurricane-Florida + House: premium=14, victory=8
Hurricane-Florida + Mobile Home: premium=8, victory=12

### What are the threshold values that trigger popups for each policy type?
Right now, it is two policies of a storm type that triggers the popup.

### What are the possible payout values for each storm type (for the dice rolls)?
<!-- Please list the possible payout values for each storm type -->
Snow: 5,10,15,20
Earthquake: 5,10,15,20,25,30
Hurricane-Other: 5,15,25,30,35,40
Flood: 10,15,20,25,30
Fire: 20,35,50
Hail: 15,20,25
Tornado: 25,30,35
Hurricane-Florida: 10,30,50,60,70,80

### What specific cards exist in the game and their victory point values?
<!-- List each card name and its victory point value -->
one "agent" per storm type "Snow Agent" for example.  each one 10 VPs
Major Celebrity Endorsement: 20 VPs
Minor Celebrity Endorsement: 5 VPs

### What are the dice probabilities/mechanics for the insolvency calculator?
<!-- Explain the dice mechanics and probabilities -->
ignore this for now

## User Experience

### Should policy counts persist between app sessions or reset each game?
<!-- Answer here -->
they should persist in case of an app crash

### Can policy counts go negative, or should they be capped at 0?
<!-- Answer here -->
policy counts cannot go negative

### Should there be an undo/redo feature for policy changes?
<!-- Answer here -->
in a future update

### Do you want a "reset all" or "new game" function?
<!-- Answer here -->
in a future update

### Should the payout calculator remember the last selected values?
<!-- Answer here -->
yes, with a button to reset all severities to 0.

## Map Configuration

### How many spaces are on the game board?
<!-- Answer here -->
map config to be handled in future update.  ignore for now.

### What are the rules/constraints for placing mansions and mobile homes?
<!-- Explain the placement rules -->
map config to be handled in future update.  ignore for now.

### What premade configurations do you want available?
<!-- List any specific configurations -->
map config to be handled in future update.  ignore for now.

### Should generated configurations be saveable/shareable?
<!-- Answer here -->
map config to be handled in future update.  ignore for now.

## Visual/UI Preferences

### Do you have specific icons/imagery for storm types and property types?
<!-- Describe any specific visual requirements or preferences -->
snow: snowflake
earthquake: split in the ground
hurricane-other: hurricane icon that goes on the map on TV
flood: waterline
fire: a flame
hail: lightning with hail coming down
tornado: basic tornado shape
hurricane florida: same as hurricane other but florida state outline in it too

### Should the app support dark mode?
<!-- Answer here -->
not at first

### Any specific font preferences?
<!-- Answer here -->
no

### Do you want sound effects for actions like policy changes or threshold popups?
<!-- Answer here -->
no sound now, but maybe in the future

## Technical Considerations

### Do you need offline functionality, or is internet connection assumed?
<!-- Answer here -->
no internet connection should be required.  only offline.

### Should there be multiple player profiles or just one active game?
<!-- Answer here -->
one active game

### Do you want analytics/statistics tracking (like most acquired policy type)?
<!-- Answer here -->
not right now.

### Any specific Android/iOS version requirements?
<!-- Answer here -->
not specifically.  ideally anything that has been available for the last 6ish years.

## Additional Notes
<!-- Add any other information you think would be helpful -->