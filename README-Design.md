# StashPost // Design

The frames of StashPost: their structure, and their functional and visual description. For the code, see [README-Technical.md](README-Technical.md); for players, [README.md](README.md). The mockups are on the [design canvas](https://claude.ai/artifact/JnnxuCGggEvhecWfqwneph).

StashPost is a World of Warcraft add-on (WoW: Forever, a Classic-era world with the modern game UI). At a mailbox, the character being played mails the items its rules choose to the player's other characters. It only sends: it never takes mail from the inbox.

## Concepts

### Characters

A recipient is one of the player's characters:

- **Known**: every character that logged in with StashPost is remembered.
- **Typed**: a name the player types ("First Surname"), for a character StashPost hasn't seen, such as an alt on another account.

Mail never goes to the character being played. Bound items are never sent.

### Rules

The rules are shared by all the player's characters. They form a tree that follows the game's item categories:

- **Category** (Trade Goods), **subcategory** (Herb), **specific item** (Peacebloom) under its subcategory.
- **By quality**: a separate branch of rules on a quality, whatever the category (Uncommon to the enchanter).

Each rule holds:

- **Rule**: *Send to* a character, or *Don't send*. The recipient is part of the rule: "Don't send" has none.
- **Qualities** (on a category or subcategory): the qualities it applies to, a multi-select (Poor, Common, Uncommon, Rare, Epic, Legendary), all checked by default.
- **Keep in bags** (on a specific item): how many stay in the bags; only the rest is sent.

**Which rule applies.** A line without a rule takes nothing of its own: the broader rule decides. For an item, the most specific rule wins: the specific item, then its subcategory, then its category, then a quality rule.

### Character overrides

A character can override a shared rule for itself, field by field: the rule (another recipient, or don't send), the keep count, the qualities. A character's "own" rule is an override of a shared rule: for example a shared "Herb: Don't send" that one character overrides to "Send to Lyra". There are no per-character rule lists.

## Design Constraints

- **Look**: the default game look, built from the game's own templates; with EllesmereUI installed, the same frames take its theme through its skinning API. No custom-styled widgets.
- **Names**: characters are shown as "First Surname" (WoW: Forever has no realms).
- **Item names** take their quality colour.

## Frames

### 1. Rules Window — Tab "Shared"

A movable window with the add-on's portrait and a close button.

- **Toolbar**: a search box, **Add item** (frame 3) and **Add category** (frame 4).
- **Tree** (left): only the lines that have a rule, with the categories above them as plain headings. Columns: *Category or item*, *Rule*, *Overrides*. Categories collapse with the game's +/− buttons. A line overridden by at least one character shows a mark in *Overrides*; who overrode it is in tab 2. The whole window accepts an item dropped on it: it is added under its category. A hint at the bottom of the tree says so.
- **Right pane**, tab **Shared**: the selected line's name and path (Trade Goods › Herb), its **Rule** (Send to [character dropdown] / Don't send), its **Qualities** on a category, its **Keep in bags** on an item, and **Remove rule**.

### 2. Rules Window — Tab "Character overrides"

The same window, the right pane on its second tab.

- **Overridden by**: the characters that override the selected rule, as tags; the selected tag's override shows below. A **+** tag opens a small list under it: a field to type a name, then the known characters without an override on this rule.
- For each field (Rule, Keep in bags, Qualities): a checkbox to override it, the character's value, and the shared value beside it.
- **Remove <character>'s override**.

### 3. Add Item (Dialog)

- **Item ID or link**, with **Add**.
- **Search by name**: the matching items, with their category.

Dropping an item on the rules window does the same without the dialog.

### 4. Add Category (Dialog)

The game's categories as a tree, with a filter. A category that already has a rule is grey, marked *has a rule*. **Add <category>** adds it to the tree; **Cancel**.

### 5. Settings (in the Game's Options → AddOns Tab)

The game's own settings list, laid out like its options (label left, control right):

- **General**: show the minimap button; show StashPost in the add-on compartment.
- **Mailbox**: **Send automatically**; **Send key** (Shift, Ctrl, Alt, None; Shift by default). Like the game's auto-loot key: with automatic sending on, holding the key when the mailbox opens skips sending; with it off, holding it sends.

### 6. Minimap Button and Add-on Compartment

Left-click on the button, or the compartment entry: open the rules window. Right-click on the button: a menu with **Open** (the rules window) and **Settings** (frame 5).

### 7. Mailbox Side Panel — Preview

A panel attached to the right of the mailbox, open with it.

- The items to send, grouped by recipient, each group with its number of mails. Each item has a checkbox: unchecked, it stays in the bags this time only.
- At the bottom: the number of mails, the postage, and **Send**.

With automatic sending on (or the send key held while it is off), the panel opens on frame 8 instead.

### 8. Mailbox Side Panel — Sending

- Each mail with its recipient and items, marked *Sent*, *Sending…*, *Waiting* or *Failed*. A failed mail shows the game's error in red under it, and sending goes on with the next mail.
- At the bottom: how many are sent and failed, and **Stop**.
- Every mail's subject is "StashPost".

## Commands

- `/stashpost`: lists the commands.
- `/stashpost open`: opens the rules window.
- `/stashpost settings`: opens frame 5.

## Open Questions

- An alt on another account can't receive account-bound items: how StashPost knows a typed character is on another account.
- Search by name: the game can only find items its client already knows (bags, bank, seen this session); to check against the API.
- Each template named above, the top tabs especially, to check against the Forever UI source.
