# High Level Description
Catastrophe Companion is an app that goes along with a board game.  The board game involves players playing as insurance companies.  They acquire policies, collect victory points and premiums, and pick up/use various ability or point cards.

The app allows the player to track their acquired policies, know how much premium to collect and how many victory points they have, and perform various calculations.

The app is targeted primarily at mobile, ie Android and iOS.  It should be able to be used on tablets and eventually web as well.

# Screens
There need to be various screens or tabs.

## Tracker
There are 8 storm types (Snow, Earthquake, Hurricane-Other, Flood, Fire, Hail, Tornado, and Hurricane-Florida).  There are 3 property types (Mansion, House, and Mobile Home).  A policy is one of the 24 combinations of these (Snow House, Flood Mobile Home, etc).

The tracker tab allows the user to press an up or down button to increase or decrease the quantity of each of the 24 policy types.  There will be a threshold for which when the player gets a certain quantity of a policy type, a pop up tells them to collect a physical card in the game.  Thresholds are subject to change, but after getting 2 policies of a storm type, you get prompted to pick up that storm's Ability card, and after picking up 7 of a storm type, you get prompted to pick up that storm's Agent of the Year card.

Each of the 24 policy types has a premium and victory point amount, so the tracker tab will multiply accordingly and tell the player their total premium and victory point numbers.

## Payout Calculator
When a storm happens, the player has to pay out from their money.  There are two dice that the players roll in the game.  The first die determines whether or not the storm happens.  If it does happen, they roll the second die to figure out how much they pay out per policy.

The payout calculator has dropdowns for each storm type for each potential payout value for that storm (different per storm).  It multiplies this by the number of policies of that storm type that a player has, adds up all of the storm payouts, and tells the user how much they need to pay out.

## Cards
There are various cards in the game.  Some of these have victory point values associated with them, and the Cards tab tracks this.  It's a list of cards and checkboxes.  If you have the card, you check it, and the tracker tab updates to add those victory points in.

## Insolvency Calculator
This screen takes in the current money count that a player has and does calculations based on possible dice rolls to determine how likely it is that during the next turn, the player has to pay out more money than they have.

There should be an input for money.  There should be an output for percent involvent.

The simulation engine should go through all possible rolls to determine what the possibility of going out.  Since the calculation may take a bit, a status bar or something to show progress of the simulation would be ideal.

Odds:
Occurrence, whether or not the storm happens (on a D20, so multiply by by 5% to get a percentage):
snow: 12
earthquake: 2
hurricane (triggers both hurricane-other and hurricane-florida): 4
flood: 5
fire: 3
hail: 7
tornado: 6

6 sided severity die options (if storm happens, how much per policy to pay out)
snow: 5/5/5/10/15/20
earthquake: 5/10/15/20/25/30
hurricane-other: 5/15/25/30/35/40
flood: 10/15/20/20/25/30
fire: 20/20/35/35/50/50
hail: 15/15/20/20/25/25
tornado: 25/25/30/30/35/35
hurricane-florida: 10/30/50/60/70/80


## Map Configuration
This screen allows the user to select from various profiles to randomly (or in premade/weighted configurations) assign mobile homes and mansions to the spaces on the board.

## Settings
This screen allows the user to see and change any default values.

# Data

## Policy Counts
Each of the 24 needs to be saved in the tracker tab.  It should persist when changing screens.  Each of the 8 storm types (sum of the 3 property types of a given storm) need to be accessible to the payout calculator and insolvency calculator.

## Card Victory Points
The total victory points given by cards needs to be accessible to the tracker tab.

## Constants
- premium and victory point per policy/storm combo
- victory points per cards
- possible payouts per storm type
- dice stats for insolvency stuff

# Aesthetics

The app should be designed initially such that non-default animations, color schemes, etc, can be added later.  Flexibility is key here.

The color scheme and order of the storm types is as follows:

1. Snow: white
2. Earthquake: brown
3. Hurricane-Other: lavender
4. Flood: blue
5. Fire: red
6. Hail: yellow
7. Tornado: grey
8. Hurricane-Florida: purple

# Implementation Plan

## Core Items

The app cannot exist without these things.  Completion of these things marks the MVP for test.  Ideally there are placeholders for the unimplemented tabs.

1. Tracker tab
2. Payout tab
3. Cards tab
4. Build for Android

## Secondary Items

These are important for implementation but can wait until after an MVP is created.

1. Insolvency calculator
2. Build for iOS

## Tertiary Items

The app can live without these if necessary.

1. Map configuration tab
2. Build for web
	1. I'd also deploy this to a site

