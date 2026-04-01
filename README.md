# 📓 Vimsidian

Minimalistic Obsidian-like note system inside Vim (Vim9script).

Vimsidian brings wiki-links, backlinks, daily notes, markdown editing helpers, and a fuzzy picker directly into your Vim — no Electron, no bloat.

---

## ✨ Features

* 🔗 Wiki links: `[[note-name]]`
* 📂 Automatic note creation
* 🔎 Backlinks search via quickfix
* 📅 Daily notes
* 🔍 Interactive picker with preview
* 🌳 Built-in vault explorer using `:Explore`
* ☑️ Markdown checkbox support
* 📝 Markdown formatting helpers
* 🧠 Clean architecture (core / ui / editor separation)
* ⚡ Written in Vim9script

---

## 📁 Project Structure

```text
autoload/
├── core/
│   ├── backlinks.vim
│   ├── daily.vim
│   ├── notes.vim
│   ├── path.vim
│   └── vault.vim
├── editor/
│   ├── checkbox.vim
│   ├── list.vim
│   ├── markdown.vim
│   └── visual.vim
├── ui/
│   ├── picker_logic.vim
│   ├── picker.vim
│   └── wiki_links.vim
└── vimsidian.vim

plugin/
└── vimsidian.vim
```

---

## ⚙️ Installation

Using vim-plug:

```vim
Plug 'greeschenko/vimsidian'
```

---

## ⚙️ Configuration

```vim
let g:vimsidian_vault_path = '~/your-vault'
```

Default:

```text
~/VAULT
```

Notes are stored inside:

```text
{vault}/data/
```

---

## 🧾 Commands

```vim
:VimsidianNew {title}            " Create or open note
:VimsidianOpen {title}           " Open existing note
:VimsidianFollowLink             " Follow [[link]] under cursor
:VimsidianToday                  " Open today's daily note
:VimsidianBacklinks              " Show backlinks
:VimsidianPicker                 " Open note picker
:OpenVaultExplorer               " Open vault/data explorer

:VimsidianToggleCheckbox         " Toggle checkbox on current line
:VimsidianToggleCheckboxVisual   " Toggle checkboxes in visual selection
:VimsidianMakeCheckbox           " Convert current line into checkbox

:VimsidianToggleBold             " Toggle bold in visual mode
:VimsidianToggleItalic           " Toggle italic in visual mode
:VimsidianToggleCode             " Toggle inline code in visual mode
:VimsidianToggleCodeBlock        " Toggle fenced code block in visual mode
:VimsidianToggleQuote            " Toggle quote block in visual mode
:VimsidianToggleList             " Toggle markdown list in visual mode
```

---

## ⌨️ Default Keymaps

### Core

```vim
<leader>vv    Open picker
<leader>vf    Follow wiki link under cursor
<leader>vt    Open today's note
<leader>vb    Show backlinks
<leader>ve    Open vault explorer
```

### Markdown Editing

These mappings are enabled automatically for markdown files.

```vim
Normal mode:
<C-x>         Toggle checkbox
<C-c>         Convert line into checkbox
<CR>          Continue current list / checkbox

Visual mode:
<C-x>         Toggle checkbox
<C-b>         Toggle bold
<C-i>         Toggle italic
<C-c>         Toggle inline code
<C-C>         Toggle code block
<C-q>         Toggle quote block
<C-l>         Toggle markdown list
```

---

## 🧠 How It Works

### Notes

* Stored as `.md` files
* Located in `{vault}/data/`
* Created automatically when opening a missing note

### Wiki Links

```text
[[my-note]]
[[projects/my-note]]
```

* Automatically resolved via link parser
* Target note is created automatically if missing

### Backlinks

Uses `:vimgrep` across all notes to find references like:

```text
[[current-note]]
```

### Picker

Features:

* Live filtering
* Arrow navigation
* Preview pane

Actions:

* `Enter` → open note
* `Ctrl-i` → insert wiki link

### Vault Explorer

Uses Vim built-in `:Explore` / netrw in tree mode.

Explorer opens directly inside:

```text
{vault}/data/
```

---

## 🌍 Unicode / Cyrillic Support

* Titles remain unchanged (UTF-8)
* File names are transliterated to ASCII

Example:

```text
Задача → zadacha.md
```

Benefits:

* Stable filenames
* Reliable search
* No encoding issues

---

## 🏗 Architecture Philosophy

Vimsidian follows a clean layered design:

* `core/` → business logic
* `ui/` → Vim interaction layer
* `editor/` → markdown editing helpers
* `vimsidian.vim` → public facade

This keeps:

* code testable
* logic reusable
* UI decoupled

---

## 🚀 Roadmap

* [ ] Tags support (`#tag`)
* [ ] Media insertion helpers
* [ ] Better fuzzy search scoring
* [ ] Graph view
* [ ] Async file loading
* [ ] File picker integration

---

## 🤝 Contributing

Pull requests are welcome.

Ideas for improvement:

* architecture
* performance
* markdown UX
* picker experience
* vault navigation

Feel free to contribute.
