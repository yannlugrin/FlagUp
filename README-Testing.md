# Flag Up // In-Game Test Plan

Manual tests in the Forever and retail clients, for what can't be checked offline: the real game API and the server. For the code, see [README-Technical.md](README-Technical.md).

## Setup

- Forever: two characters of the same account in the same ruleset: the one sending, and the one receiving.
- Retail: characters of the same account on a realm with connected realms, on two of them; one of the other faction on the realm of the one sending.

## Retail

- Mail to a character of the same realm, shown without its realm, and of a connected realm, shown as "Name-Realm".
- Mail to the player's own character of the other faction, on the same realm.
- A typed name on a realm that isn't connected is refused with *Mail can't reach this realm.*; a typed realm with spaces or in lower case takes the game's spelling.
- A realm connected later (or a character of a connected realm seen first on its own): at login, its household joins, rules and ignored items with it.

## Tested in 1.0.0

- Sending to a "First Surname" name with `SendMail`.
- Attaching several bag slots in a row, and a part of a stack after splitting it.
- Sending as soon as the mailbox opens.
- The postage the game takes matches the mailbox panel's (30 copper per attachment).
