# StashPost // Design

The frames of StashPost: their structure, and their functional and visual description. For the code, see [README-Technical.md](README-Technical.md); for players, [README.md](README.md). The mockups are on the [design canvas](https://claude.ai/artifact/JnnxuCGggEvhecWfqwneph).

StashPost is a World of Warcraft add-on (WoW: Forever, a Classic-era world with the modern game UI). At a mailbox, the character being played mails the items its rules choose to the player's other characters. It only sends: it never takes mail from the inbox.

## Concepts

### Characters

A recipient is one of the player's characters:

- **Known**: every character that logged in with StashPost is remembered.
- **Typed**: a name the player types ("First Surname"), for a character StashPost hasn't seen, such as an alt on another account.

Mail only reaches a character of the same ruleset and faction, so StashPost keeps the characters and rules of each ruleset and faction apart (PvP Alliance, PvP Horde, Normal Horde…). The character being played sees all the rules of its ruleset and faction, with the overrides of every character of it, not only its own; it never sees another ruleset or faction. A typed character belongs to the ruleset and faction of the character that typed it.

Mail never goes to the character being played. Bound items are never sent.

### Rules

The rules are shared by the player's characters of one ruleset and faction; each ruleset and faction has its own. They form a tree that follows the game's item categories:

- **Category** (Trade Goods), **subcategory** (Herb), **specific item** (Peacebloom) under its subcategory.

Each line holds these fields:

- **Rule**: one dropdown listing the recipients and *Don't send*. Choosing a recipient sends to it; choosing *Don't send* removes the recipient.
- **Qualities** (on the equipment categories, Armor and Weapon, and their subcategories): the qualities it applies to, a multi-select (Poor, Common, Uncommon, Rare, Epic, Legendary). None selected means no filter: every quality.
- **Keep** (on a specific item): how many stay in the bags; only the rest is sent.

**Inherited fields.** Each field has a checkbox. Checked, the line sets the field; unchecked, the field is greyed out and shows the value it inherits from the line above: an item from its subcategory, a subcategory from its category. Above the categories, hidden, are the defaults: *Don't send*, no quality selected, nothing kept. So for an item, each field comes from the closest line that sets it, else from the defaults. A new line starts with every field inherited.

### Character overrides

A character can override a shared rule for itself, field by field: the rule (another recipient, or don't send), the keep count, the qualities. A character's "own" rule is an override of a shared rule: for example a shared "Herb: Don't send" that one character overrides to "Send to Lyra". There are no per-character rule lists.

## Design Constraints

- **Look**: the default game look, built from the game's own templates; with EllesmereUI installed, the same frames take its theme through its skinning API. No custom-styled widgets.
- **Names**: characters are shown as "First Surname" (WoW: Forever has no realms).
- **Item names** take their quality colour.

## Frames

### 1. Rules Window

A movable window with the add-on's portrait and a close button.

- **Toolbar**: a search box, **Add item** (frame 3) and **Add category** (frame 4).
- **Tree** (left): only the lines that were added, with the categories above them as plain headings. Columns: *Category or item*, *Rule*. *Rule* shows what the character being played will do with the line: the recipient's name or *Don't send*, and ", keep 20" when some are kept; it is greyed out when the line inherits all its fields. When that character overrides the line, *Rule* shows its override and a small glyph follows the line's name; who else overrides it is in the pane's overrides section (frame 2). Categories collapse with the game's +/− buttons. The whole window accepts an item dropped on it: it is added under its category. A hint at the bottom of the tree says so.
- **Right pane**, top section: the selected line's name and path (Trade Goods › Herb), then its fields, each with its checkbox: **Rule** (one dropdown: the recipients and *Don't send*), **Qualities** on an equipment category or subcategory, **Keep** on an item. Then **Remove rule** (frame 9). Unchecking the last checked field also opens frame 9.

### 2. Rules Window — Character Overrides Section

The bottom section of the right pane, under the shared rule, titled **Character overrides**.

- **Overridden by**: the characters that override the selected rule, as tags; the selected tag's override shows below. A **+** tag opens a small list under it: a field to type a name, then the known characters without an override on this rule.
- For each field the line has (Rule, Qualities, Keep): a checkbox to override it, the character's value, and the shared value beside it (set on the line or inherited).
- **Remove <character>'s override**.

### 3. Add Item (Dialog)

- **Item ID or link**, with **Add**: type the item's ID, or shift-click an item to paste its link.

Dropping an item on the rules window does the same without the dialog.

### 4. Add Category (Dialog)

The game's categories as a tree, with a filter. A category already in the tree is grey, marked *already added*. **Add <category>** adds it to the tree; **Cancel**.

### 5. Settings (in the Game's Options → AddOns Tab)

The game's own settings list, laid out like its options (label left, control right):

- **General**: show the minimap button; show StashPost in the add-on compartment.
- **Mailbox**: **Send automatically**; **Send key** (Shift, Ctrl, Alt, None; Shift by default). Like the game's auto-loot key: with automatic sending on, holding the key when the mailbox opens skips sending; with it off, holding it sends.

### 6. Minimap Button and Add-on Compartment

The usual add-on minimap button, the one most add-ons show (LibDBIcon). Left-click on the button, or the compartment entry: open the rules window. Right-click on the button: a menu with **Open** (the rules window) and **Settings** (frame 5).

### 7. Mailbox Side Panel — Preview

A panel attached to the right of the mailbox, open with it.

- The items to send, grouped by recipient, each group with its number of mails. Each item has a checkbox: unchecked, it stays in the bags this time only.
- At the bottom: the number of mails, the postage, and **Send**.

With automatic sending on (or the send key held while it is off), the panel opens on frame 8 instead.

### 8. Mailbox Side Panel — Sending

- Each mail with its recipient and items, marked *Sent*, *Sending…*, *Waiting* or *Failed*. A failed mail shows the game's error in red under it, and sending goes on with the next mail.
- At the bottom: how many are sent and failed, and **Stop**.
- Every mail's subject is "StashPost".

### 9. Remove Rule (Dialog)

Opens on **Remove rule**, always, and when the last checked field of the line is unchecked. Its buttons depend on the line:

- **Remove**: the line and its overrides. The lines under it stay and inherit from the line above it.
- **Inherit**, only when characters override the line (the text names them): every field of the line is unchecked and inherited; the line stays with its overrides as they are.
- **Cancel**: nothing changes; an unchecked field is checked again.

## Commands

- `/stashpost`: lists the commands.
- `/stashpost open`: opens the rules window.
- `/stashpost settings`: opens frame 5.

## Open Questions

- An alt on another account can't receive account-bound items: how StashPost knows a typed character is on another account.
- Search by name in Add item, for later: the game finds an item by its exact name only once it has been in the bags or bank this session, and has no search by part of a name; a search would cover a list StashPost builds itself.
