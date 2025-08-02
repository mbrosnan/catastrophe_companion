# Overview

This document outlines a list of known bugs, changes, and features for the catastrophe companion app.

# Implementation Directions

Before implementation, please review each and let me know if you have questions.  Generate a file in the 20250723_Notes folder that contains your questions and a space for my responses.

Implement these one at a time unless otherwise indicated.  I will test them after each item has been tackled.

# Change List

## 1. Colors

Note: these changes should apply to all tabs that have colors with the storms.

Change Snow to light blue color text on a dark grey background.

For Hurricane-Other, keep the text color but change the background color to a dark grey.

# 2. Order

Change the order of earthquake and snow (snow should come after earthquake).  This should apply across all tabs that have an order.

# 3. Agent of the year threshold.

Each agent of the year should provide a notification after 6 policies instead of 7.

# 4. Default mobile homes and mansions

In the Map tab, the default number of mobile homes and mansions should be changed to 15.

# 5. Billionaire Bailout

On the payout tab, add a checkbox with the text "Billionaire Bailout".  If this box is checked, mansion properties do NOT add to the payout at all.

# 6. Northward Migration

TBD (ignore for now.  do not ask questions on this)

# 7. Stacked Together Preset

Remove the stacked together preset entirely.

# 8. Florida with the map

For the map, florida should NOT be considered a separate storm type.  It is part of hurricane.  So for the purposes of any assignment, a florida space is just a hurricane space.  It should still show as dark purple, but it should count as hurricane for all other things including thresholds, state balancing, etc.

# 9. Diversified Agent of the Year

In the cards tab, add a "Diversified Agent of the Year".  This is worth 10 VPs.  It is acquired when you have 1 policy in every storm type and should have a pop up notification when you hit that.

# 10. Loan Card

In the cards tab, add a "Loan" card.  When pressed, this shows a popup.  The popup says "What is the VP cost of this loan?" and has a dropdown with values from "0" to "-10".  Once "OK" is selected, the selected value gets added to the victory point total (always negative, so the victory point total always goes down).  If you try to deselect the loan card, a popup appears saying "You are not allowed to remove the loan card.  Only deselect if if you entered the wrong amount and are fixing it." With options of "Ok", which keeps the loan on, and "Remove Loan", which removes it and no longer changes the VP total until it's selected again.

# 11. Payout Tab - Hurricane FL

In the payout tab, Hurricane FL should still be shown, but the severity should always be double the selected severity of the hurricane-other.  Essentially make it an unmodifiable text instead of a dropdown.