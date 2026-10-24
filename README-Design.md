# Flag Up // Design

The frames of Flag Up: their structure, and their functional and visual description. For the code, see [README-Technical.md](README-Technical.md); for players, [README.md](README.md). The mockups are on the [design canvas](https://claude.ai/artifact/JnnxuCGggEvhecWfqwneph).

Flag Up is a World of Warcraft add-on for WoW: Forever (a Classic-era world with the modern game UI) and retail. At a mailbox, the character being played mails the items its rules choose to the player's other characters. It only sends: it never takes mail from the inbox.

## Concepts

### Characters

A recipient is one of the player's characters:

- **Known**: every character that logged in with Flag Up is remembered.
- **Typed**: a name the player types, for a character Flag Up hasn't seen, such as an alt on another account: "First Surname" on Forever; "Name-Realm" on retail, a name alone being on the realm being played, and the realm one mail reaches.

Mail only reaches some characters, so Flag Up keeps the characters and rules of each household apart. On Forever, a household is a ruleset and faction (PvP Alliance, PvP Horde, Normal Horde…). On retail, it is a realm and the realms connected to it, both factions; mail crosses factions only between the player's own characters (known ones) of one realm, so a rule that would send across factions otherwise keeps the items, as *Don't send*. The character being played sees all the rules of its household, with the overrides of every character of it, not only its own; it never sees another household. A typed character belongs to the household of the character that typed it, and to its faction. On retail, a realm connected to the household later brings its own household along: its characters, rules and ignored items join, and on a line both have, the household being played keeps its fields.

A known character that is renamed, which the game can force, keeps its rules and overrides: Flag Up recognises it at its next login.

Mail never goes to the character being played. Bound items, and items of an equipment set, are never sent.

### Rules

The rules are shared by the player's characters of one household; each household has its own. They form a tree that follows the game's item categories:

- **Category** (Trade Goods), **subcategory** (Herb), **specific item** (Peacebloom) under its subcategory.

Each line holds these fields:

- **Rule**: one dropdown listing *Don't send*, the recipients, then *Other character…*, which asks for a name to type. Choosing a recipient sends to it; choosing *Don't send* removes the recipient.
- **Qualities** (on the equipment categories, Armor and Weapon, and their subcategories): the qualities it applies to, a multi-select (Poor, Common, Uncommon, Rare, Epic, Legendary). None selected means no filter: every quality.
- **Keep** (on a specific item): how many stay in the bags; only the rest is sent.
- **Stacks** (on every line): *Full stacks only* or *Any amount*. With *Full stacks only*, an item that stacks is sent only in full stacks: what the bags hold, after Keep, is counted as a whole, split or joined into as many full stacks as it makes, and the rest stays (45 herbs that stack by 20, keep 10: one stack of 20 sent, 25 stay). An item that doesn't stack is sent as usual.

**Inherited fields.** Each field has a checkbox. Checked, the line sets the field; unchecked, the field is greyed out and shows the value it inherits from the line above: an item from its subcategory, a subcategory from its category. Above the categories, hidden, are the defaults: *Don't send*, no quality selected, nothing kept, any amount. So for an item, each field comes from the closest line that sets it, else from the defaults. A new line starts with every field inherited.

### Character overrides

A character can override a shared rule for itself, field by field: the rule (another recipient, or don't send), the keep count, the qualities, the stacks. A character's "own" rule is an override of a shared rule: for example a shared "Herb: Don't send" that one character overrides to "Send to Lyra". There are no per-character rule lists.

For each field, the closest line that sets it decides, from the item up to its category; on one line, the character's override comes before the shared value. With a shared Herb *Don't send* that Silvia overrides to *Send to Lyra*, and a shared Peacebloom *Send to Borin*, Silvia sends Peacebloom to Borin and the other herbs to Lyra.

A rule never makes a character mail itself: for the character a rule sends to, the rule is *Don't send*. With a shared Herb *Send to Lyra*, Lyra keeps her herbs, and her pane shows *Don't send*.

### Ignored items

An ignored item is never offered at the mailbox, whatever the rules say: it is not a rule, it means "don't show me this any more". An item is ignored by every character of the household, or by one character only. Ignored by every character, it is no longer ignored by each one apart: taking it back makes it offered to all. Only items are ignored; a whole category is a *Don't send* rule. An ignored item keeps its rule line, if it has one; the line says it is ignored. In the tree, its Rule column reads *Ignored* for the character being played. In the pane, an item ignored by every character shows only *Ignored by every character*, **Stop ignoring** and **Remove rule**, in place of its fields and overrides; an item ignored by one character shows that notice and **Stop ignoring** in place of the character's override, and that character has a tag. Dropping an ignored item on the rules window adds its line, shown ignored. A category or subcategory of the tree holding ignored items (by every character or by one) shows the ignore glyph, in grey, just left of the *Rule* column (before the override glyph, when both show); a click on it opens the Ignored tab, filtered on it. An ignored item's line shows the glyph too; a click on it opens the tab filtered on the item's subcategory.

## Design Constraints

- **Look**: the default game look, built from the game's own templates; with EllesmereUI installed, the same frames take its theme through its skinning API. No custom-styled widgets.
- **Names**: characters are shown as "First Surname" on Forever, which has no realms; on retail as "Name-Realm", without the realm being played.
- **Item names** take their quality colour.

## Frames

### 1. Rules Window

A movable window with the add-on's portrait and a close button, and the game's tabs under it: **Rules** (this frame) and **Ignored** (frame 10).

- **Toolbar**: a search box, **Add item** (frame 3) and **Add category** (frame 4). The search box filters the tree as it is typed in: the lines whose name holds the text, with the categories above them, all open; a category or subcategory found keeps every line under it.
- **Tree** (left): only the lines that were added, with the categories above them as plain headings. Columns: *Category or item*, *Rule*. *Rule* shows what the character being played will do with the line: the recipient's name or *Don't send*, then ", full stacks" when only full stacks are sent, then ", keep 20" when some are kept (Lyra Moonfield, full stacks, keep 20); it is greyed out when the line inherits all its fields. When that character overrides the line, *Rule* shows its override and a small glyph sits just left of the *Rule* column, so the rules stay aligned; who else overrides it is in the pane's overrides section (frame 2). A plain heading can be selected too: the pane shows what it inherits, every field unchecked. Categories collapse with the game's +/− buttons. The whole window accepts an item dropped on it: it is added under its category. A hint at the bottom of the tree says so.
- **Right pane**, top section: the selected line's icon (an item's own, with its tooltip; a crate for a category or subcategory), name and path (Trade Goods › Herb), then its fields, each with its checkbox: **Rule** (one dropdown: the recipients and *Don't send*), **Qualities** on an equipment category or subcategory, **Keep** on an item, **Stacks** (one dropdown: *Full stacks only* and *Any amount*). Then **Remove rule** (frame 9). Unchecking the last checked field asks instead: **Remove the line**, or **Keep the line**, every field inherited (Escape keeps it too); the text names the characters whose overrides would go with it. With no line selected, the pane shows only *Select a line in the tree.*

### 2. Rules Window — Character Overrides Section

The bottom section of the right pane, under the shared rule, titled **Character overrides**.

- **Tags**, straight under the title: the character being played, always, even without an override; then the characters that override the selected rule; then a **+** tag. The selected tag's override shows below; the character being played without an override shows every field unchecked. The **+** tag opens a menu of the known characters without an override on this rule, the one being played left out; it is disabled when there are none.
- For each field the line has (Rule, Qualities, Keep, Stacks): a checkbox to override it, and the character's value. The shared values are in the section above.
- **Remove <character>'s override**, at the bottom, only when the selected character has an override.

### 3. Add Item (Dialog)

- **Item ID or link**, with **Add**: type the item's ID, or shift-click an item to paste its link.

Dropping an item on the dialog puts its link in the field. Dropping an item on the rules window adds it without the dialog.

### 4. Add Category (Dialog)

The game's categories as a tree, with a filter. A category already in the tree is grey, marked *already added*. **Add <category>** adds it to the tree; **Cancel**.

### 5. Settings (in the Game's Options → AddOns Tab)

The game's own settings list, laid out like its options (label left, control right):

- **General**: show the minimap button; show Flag Up in the add-on compartment.
- **Mailbox**: **Send automatically**; **Send key** (Shift, Ctrl, Alt, None; Shift by default). Like the game's auto-loot key: with automatic sending on, holding the key when the mailbox opens skips sending; with it off, holding it sends. **Uncheck cheap items** (on by default): an item whose vendor value (its price times the count sent) is below the postage of its stacks (30 copper each) starts unchecked. **Uncheck unsellable items** (off by default): an item a vendor won't buy starts unchecked. An item they uncheck is still listed and can be checked; an automatic sending leaves it out.

### 6. Minimap Button and Add-on Compartment

The usual add-on minimap button, the one most add-ons show (LibDBIcon). Left-click on the button: show or hide the rules window. Right-click on the button: a menu with **Open** (the rules window) and **Settings** (frame 5). A click on the compartment entry opens the settings (frame 5), as other add-ons' entries do.

### 7. Mailbox Side Panel — Preview

A panel attached to the right of the mailbox, open with it.

- The items to send, grouped by recipient, each group with its number of mails. Each item has a checkbox: unchecked, it stays in the bags this time only. Its count is a number box: the count typed goes this time only, up to what the bags hold, in place of the rules' (Keep and Full stacks only no longer apply to it), and shows in gold; its tooltip gives how many the bags hold, and how many the rules keep (when they keep some), or send when set by hand; 0 unchecks the item; emptied, it goes back to the rules' count. At the end of its row, an **Ignore** button (the game's loot Pass glyph) opens the game's popup: **All characters**, **Only <character being played>**, **Cancel**; the item leaves the list at once.
- At the bottom: the number of mails, the postage, and **Send**.

With automatic sending on (or the send key held while it is off), the panel opens on frame 8 instead.

### 8. Mailbox Side Panel — Sending

- Each mail with its recipient and items, marked *Sent*, *Sending…*, *Waiting* or *Failed*. A failed mail shows the game's error in red under it, and sending goes on with the next mail.
- At the bottom: how many are sent and failed, and **Stop**; once the sending is over (finished or stopped), **Back** returns to the preview, with what is left in the bags.
- Every mail's subject is "Flag Up parcel".

### 9. Remove Rule (Dialog)

Opens on **Remove rule**. Its buttons depend on the line:

- **Remove**: the line and its overrides. The lines under it stay and inherit from the line above it.
- **Inherit**, only when characters override the line (the text names them): every field of the line is unchecked and inherited; the line stays with its overrides as they are.
- **Cancel**: nothing changes.

### 10. Rules Window — Ignored Tab

The items ignored in the household being played, by every character or by one.

- A dropdown filters the list: *All categories*, then the categories and subcategories that hold ignored items. While a filter is set, the rows' cross in grey, red under the mouse, at its right goes back to *All categories*.
- Columns *Item* (icon and name in its quality colour) and *Ignored by* (*All characters*, or the character's name); an item ignored by every character and by a character has a row for each. A red cross (the game's ready check cross) at the end of the row takes the item back.

## Commands

- `/flagup`: lists the commands.
- `/flagup open`: shows or hides the rules window.
- `/flagup settings`: opens frame 5.

## Open Questions

- An alt on another account can't receive account-bound items: how Flag Up knows a typed character is on another account.
- Search by name in Add item, for later: the game finds an item by its exact name only once it has been in the bags or bank this session, and has no search by part of a name; a search would cover a list Flag Up builds itself.
