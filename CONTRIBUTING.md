# Contributing to StashPost

Thanks for helping. StashPost is an add-on for **World of Warcraft: Forever**; the other flavors are not supported.

## Reporting a problem

Open an issue with what you did, what you expected and what happened, and the rules involved. Include any Lua error in full (BugSack, or `/console scriptErrors 1`).

## Setting up

1. Clone the repository and link it into the Forever client's `Interface\AddOns` folder under the name `StashPost`, for example on Windows (cmd):
   ```
   mklink /J "<Forever client>\Interface\AddOns\StashPost" "<clone>"
   ```
2. Fetch the libraries. `Libs/` is not in the repository: the [BigWigs packager](https://github.com/BigWigsMods/packager) builds it from the `externals` in `.pkgmeta`. It needs `git` and `svn` (Subversion). From the repository root:
   ```
   mkdir -p .release
   curl -fsSL -o .release/release.sh https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh
   bash .release/release.sh -dlz
   ```
   Then link `Libs` to the libraries it built, for example on Windows (cmd): `mklink /J Libs .release\StashPost\Libs`. Running `release.sh -dlz` again refreshes them. Never copy library files into the repository; a new library goes in `.pkgmeta` and `Libs.xml`.
3. Turn on the repository's Git hooks: `git config core.hooksPath .githooks`. Its `pre-push` hook refuses to push a release tag until the Checks have passed on the commit it tags; it needs the [GitHub CLI](https://cli.github.com/) (`gh`), and without it only prints a warning.
4. Restart the client: `/reload` does not pick up new files.

## Checking your change

Every push runs [luacheck](https://github.com/lunarmodules/luacheck) from the repository root (`luacheck .`), with the configuration in `.luacheckrc` (`.github/workflows/checks.yml`).

## Code

- Lua 5.1, the add-on namespace (`local _, ns = ...`), no new globals; functions are `local function` where they are defined.
- Detect APIs before using them; never compare build numbers. Registering an event the client doesn't know throws on Forever.
- Values read from the game may be secret: check `issecretvalue` before comparing, storing or concatenating them.
- Use the game's own templates for every control, so EllesmereUI can skin them.
- Comments say what the code does or why, in a short sentence.

## Documentation

Update the documents your change touches, in the same pull request:

- [README.md](README.md): what players can do, and the commands.
- [README-Technical.md](README-Technical.md): how it is built (file map, data).
- [README-Design.md](README-Design.md): the frames, as designed.
- [README-Testing.md](README-Testing.md): the in-game tests.
- [CHANGELOG.md](CHANGELOG.md): one line for players under `## [Unreleased]`, in the section that fits (Added, Changed, Fixed, Removed, Security), following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Commits and pull requests

- One subject line saying what the change does and why; a body only for context the diff doesn't show.
- One topic per pull request, with the checks passing.

## Releasing (maintainers)

1. In `CHANGELOG.md`, rename `## [Unreleased]` to the version and date, `## [0.1.0] - 2026-11-01`, add an empty `## [Unreleased]` above it, and update the links at the bottom: `[Unreleased]` compares the new version with `HEAD`, and the new version compares the previous one with it; only the first version links to its tag.
2. Read the documents in full against that version's section, and fix them in the release commit:
   - [README.md](README.md): the status note at the top, every *Coming* mark (a feature built in this version loses it), the features and the commands. The README goes into the package.
   - [README-Technical.md](README-Technical.md), [README-Design.md](README-Design.md), [README-Testing.md](README-Testing.md): their status lines and what they mark as planned.
3. Commit, then tag the commit with the version itself (`0.1.0`, no `v`), as an annotated tag whose message is `StashPost <version>`, a blank line, then that version's section of the changelog, without its `## [...]` heading: the same text the release notes get. From the repository root (Git Bash):
   ```
   version=0.1.0
   { echo "StashPost $version"; echo; awk -v heading="## [$version]" '
       index($0, heading) == 1 { found = 1; next }
       found && (/^## \[/ || /^\[[^]]*\]: /) { exit }
       found { print }' CHANGELOG.md | tr -d '\r'; } | git tag -a "$version" --cleanup=whitespace -F -
   ```
   Check it with `git for-each-ref "refs/tags/$version" --format='%(contents)'`, then push the branch, wait for its Checks to pass, and push the tag. A tag containing `alpha` or `beta` makes an alpha or beta release; any other tag, a full release.
4. `.github/workflows/package.yml` stops unless the Checks passed on the tagged commit, then packages the add-on and creates the GitHub release with that version's section of the changelog; it uploads to CurseForge once the TOC has an `X-Curse-Project-ID`. It stops if the changelog has no section for the tag.

A pushed tag is final: never delete it or push it again. A mistake found after the push is fixed in the next version.
