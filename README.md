# 📓 Vimsidian

Minimalistic **Obsidian-like note system inside Vim (Vim9script)**.

Vimsidian brings wiki-links, backlinks, daily notes, and a fuzzy picker directly into your Vim — no Electron, no bloat.

---

## ✨ Features

- 🔗 Wiki links: `[[note-name]]`
- 📂 Automatic note creation
- 🔎 Backlinks search (via quickfix)
- 📅 Daily notes
- 🔍 Interactive picker with preview
- 🧠 Clean architecture (core / ui separation)
- ⚡ Written in Vim9script (fast & modern)

---

## 📁 Project Structure

```

autoload/
vimsidian.vim        # Entry point (facade)

core/
vault.vim         # Vault paths / directories
path.vim          # Slug + path resolving
notes.vim         # Note CRUD + metadata
backlinks.vim     # Backlinks domain
daily.vim         # Daily notes

ui/
picker.vim        # Popup UI
picker_logic.vim  # Picker behavior
wiki_links.vim    # Cursor link logic

````

---

## ⚙️ Installation

Using vim-plug

```bash
Plug 'greeschenko/vimsidian'
````
---

## ⚙️ Configuration

```vim
let g:vimsidian_vault_path = '~/your-vault'
```

Default:

```
~/VAULT
```

---

## 🧾 Commands

```vim
:VimsidianNew {title}       " Create or open note
:VimsidianOpen {title}      " Open existing note
:VimsidianFollowLink        " Follow [[link]] under cursor
:VimsidianToday             " Open today's note
:VimsidianBacklinks         " Show backlinks
:VimsidianPicker            " Open note picker
```


## 🧠 How it works

### Notes

* Stored as `.md` files
* Located in:

```
{vault}/data/
```

---

### Wiki Links

```
[[my-note]]
[[projects/my-note]]
```

* Automatically resolved via `ResolveLink`
* Created if not exists

---

### Backlinks

Uses:

```
:vimgrep
```

Across all notes to find:

```
[[current-note]]
```

---

### Picker

* Live filtering
* Arrow navigation
* Preview pane

Actions:

* `Enter` → open note
* `Ctrl-i` → insert link

---

## 🌍 Unicode / Cyrillic Support

* Titles remain **unchanged (UTF-8)**
* File names are **transliterated to ASCII**

Example:

```
Задача → zadacha.md
```

Benefits:

* ✅ Stable filenames
* ✅ Reliable search
* ✅ No encoding issues

---

## 🏗 Architecture Philosophy

Vimsidian follows a **clean layered design**:

* **core/** → business logic
* **ui/** → Vim interaction layer
* **vimsidian.vim** → facade / public API

This keeps:

* code testable
* logic reusable
* UI decoupled

---

## 🚀 Roadmap

* [ ] Fuzzy search scoring (instead of `stridx`)
* [ ] Tags support (`#tag`)
* [ ] Graph view
* [ ] Async file loading

---

## 🤝 Contributing

Pull requests are welcome.

If you want to improve:

* architecture
* performance
* user experience

Feel free to contribute.
