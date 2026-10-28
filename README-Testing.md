# Flag Up // In-Game Test Plan

Manual tests in the Forever, retail, Classic Era and TBC Anniversary clients, for what can't be checked offline: the real game API and the server. For the code, see [README-Technical.md](README-Technical.md).

## Setup

- Forever: two characters of the same account in the same ruleset: the one sending, and the one receiving.
- Retail: characters of the same account on a realm with connected realms, on two of them; one of the other faction on the realm of the one sending.

## Retail

- Mail to a character of the same realm, shown without its realm, and of a connected realm, shown as "Name-Realm".
- Mail to the player's own character of the other faction, on the same realm.

## Classic Era and TBC Anniversary

Tested on Classic Era, on a Season of Discovery realm; Hardcore realms run the same client. TBC Anniversary not tested yet: its client is the same as Classic Era's for what Flag Up uses.

- The mailbox panel's tabs are icon buttons; one lights up while an item is held over it.
- The rules tree: categories without a bar, round + and − buttons as marks.
- A character of the other faction on the same realm is offered nowhere as a recipient (not tested: no such character yet).

## Part stacks (both flavors)

- A Keep leaving part of a stack: the part is split into a free slot, and only it arrives; the rest stays in the bags.
- A whole stack and a part stack for one recipient, one free slot: one mail.
- Bags full: the whole-stack mails free their slots, and the part stacks follow in as many mails as those slots allow.
- Bags full and only part stacks to send: the mail fails with *No free bag slot to split a stack.*
- A typed name on a realm that isn't connected is refused with *Mail can't reach this realm.*; a typed realm with spaces or in lower case takes the game's spelling.
- A realm connected later (or a character of a connected realm seen first on its own): at login, its household joins, rules and ignored items with it.

## Tested in 1.0.0

- Sending to a "First Surname" name with `SendMail`.
- Attaching several bag slots in a row, and a part of a stack split onto the cursor (no longer done: retail attaches the whole stack that way).
- Sending as soon as the mailbox opens.
- The postage the game takes matches the mailbox panel's (30 copper per attachment).
