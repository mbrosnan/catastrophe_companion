# General

This is the four ideas for tracker tab layouts/button flows.

# Ideas

## Idea 1

The tracker screen will still have the banner at the top saying "Policy Tracker".  It will still have the total premium and total victory points under that.  

Below that will be 8 icons: In order left to right then top to bottom, Earthquake, Snow, Hurricane/Hurricane Florida, Fire, Hail, Tornado, Flood, California/Texas.  Clicking any of these brings up a popup that shows the policy types (Mobile home, house, and mansion), along with a plus/minus to add or subtract policies.

If the hurricane one is clicked, this is the same except next to the symbol, there's a toggle for Hurricane-Other (shown as a hurricane symbol) and Hurricane-Florida (Shown as a florida state outline).

If the California/Texas one is clicked, it's the same except at the top there's a toggle for CA/TX, each as it's state outline.  Clicking a plus adds a policy to each relevant storm type (since both of those states are dual policy states-CA with fire/eq, tx with hurricane/tornado).  clicking minus subtracts a policy from each.  

For all except CA/TX, on the individual popup, it should show how much of each policy type in that storm you have.  On the main screen, it would be great if in the corner of each storm's picture, it showed the number of each policy that you have (not for CA/TX).

See idea_1_sketch.png for inspiration.

## Idea 3

This tracker screen is similar to the other trackers in that the top banner and premium/VP is the same as usual.

Under that, there is a grid of 10 buttons.  Ideally it's 3x3, where the "Texas" and "California" buttons are half size and occupy one "slot".  Each of these, with the exception of Texas and California, have the number of policies written under it.  If you long press any of these, a popup comes up that shows the number of houses, mobile homes, and mansions in that given storm type.  Initially, all are "unselected".  If you press one, only that one becomes selected.  If any others were selected, they stop being selected.

Under that, there's a line, and under that 3 buttons for "Mobile Home", "House", and "Mansion".  Initially, all are "unselected".  If you press one, only that one becomes selected.  If any others were selected, they stop being selected.

Under that, there's a line, and under that a larger button for add, and a smaller button for remove.  

If the add button is selected, a policy of the storm type and policy type is added to the count.  If the remove button is selected, it removes one from the count of that policy/storm combination count.  After a removal or add, all buttons on screen are unselected.

If a policy and/or storm type are not yet selected for either add or remove operation, a dialogue box informs the user that they need to select one.

If california or texas is selected, the add/remove operation is for a policy of two storm types (EQ/fire for california, hurricaneother/tornado for texas).  

If not enough of that type exists for a remove operation, do not let the remove happen and notify the user via popup.  Be careful to check both types for california and texas.