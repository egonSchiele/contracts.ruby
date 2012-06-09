- How to avoid writing "class Object"? Seriously.
- documentation with RDoc
- write specs
- make a complete easy walkthrough
- maybe make some screencasts
- bug: default args don't get typechecked at all, so they could violate your contract.
The reason is, of course, that they aren't passed in as args and we only check those args. Is there some way to get a list of the default args in a function?
