This is about getting catastrophe companion onto my VPS.  Here's the sequence of events that I want to happen:


1. claude code on VPS get to correct branch and see this file
2. configure VPS so that it can properly host catastrophe companion.  domain not yet pointing, but if user types in IP type address, it goes to the app on VPS instead of AWS where it currently lives
3. make a tiny change to prove that the flow of making a change and deploying works.  this figures out deploying an update to the app to the VPS.  note: i've had issues in the past with caching so that changes took forever (and multiple commands/items to click on cloudflare) to update.  i want that to be fixed
4. set up a beta or test sub-site for testing that doesn't go onto the main page.  this will be used for testing updates before they make it to the final site
5. move the domain to point to the VPS
6. TBD