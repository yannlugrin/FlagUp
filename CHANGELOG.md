# Changelog

All notable changes to Flag Up. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-10-29

### Added

- Mailbox panel: change how many of an item go, this time only; the count's tooltip tells how many are in the bags.
- Retail: your characters of a realm and its connected realms share their rules and mail each other, the other faction too on your own realm; names show without the realm you play.
- Mailbox panel: drop an item on a recipient's heading or items to send it all there, this time only; the rules' row elsewhere stays, at 0.
- Mailbox panel: your alts with nothing to receive show as tabs beside it, with their class icon; drop an item on one to send it all there.
- Rules window: a Characters tab chooses which characters get a tab at the mailbox, changes their icon (the game's icon picker, professions on top) and forgets a typed one.
- Mailbox panel: a tab with Flag Up's icon opens or closes the rules window.
- Classic Era (Season of Discovery and Hardcore included) and TBC Anniversary: works as on retail, except that mail never goes to the other faction.

### Fixed

- Part of a stack (a Keep, or a count set by hand) is sent alone; retail mailed the whole stack.

## [1.0.0] - 2026-10-23

### Added

- Rules window: choose what goes where by the game's item categories and subcategories, or item by item; add a category from the game's list, an item by its ID, its link or by dropping it on the window; a search box filters the tree by name.
- Keep a number of an item in your bags, and send only full stacks of what stacks.
- Rules shared by your characters of one ruleset and faction; a character can override any field for itself. A renamed character keeps its rules.
- Recipients: the characters that logged in with Flag Up, or a name you type for an alt on another account.
- Mailbox panel: what will be sent, by recipient, with the postage; uncheck an item to keep it this time. Then it sends mail after mail and shows each one sent, or failed with the game's reason.
- Send automatically when the mailbox opens, or only on Send; a key you choose does the opposite while you hold it.
- Ignore an item from the mailbox panel, for all your characters or only the one you play; the rules window's Ignored tab lists them by category, to take one back.
- Items worth less than their postage start unchecked at the mailbox; a setting turns it off, another one does the same for items without a vendor price.
- Settings in Options › AddOns, a minimap button, an add-on compartment entry and the `/flagup` commands.

[Unreleased]: https://github.com/yannlugrin/FlagUp/compare/1.1.0...HEAD
[1.1.0]: https://github.com/yannlugrin/FlagUp/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/yannlugrin/FlagUp/releases/tag/1.0.0
