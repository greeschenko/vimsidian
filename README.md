# 📓 Vimsidian

Minimalistic Obsidian-like note system inside Vim (Vim9script).

Vimsidian brings wiki-links, backlinks, daily notes, reminders, templates, fuzzy picker, and a vault explorer directly into your Vim — no Electron, no bloat.

---

## ✨ Features

* 🔗 Wiki links: `[[note-name]]` and `[[path/to/note]]`
* 🏷️ Tags: `#tagname` with autocomplete
* 📝 Template system with variables (`{{TITLE}}`, `{{DATE}}`, etc.)
* ⏰ Reminders: `every:1d`, `every:monday`, `on:2026-04-20`
* 🔍 Hybrid fuzzy search (filename + content)
* 📂 Automatic note creation
* 🔎 Backlinks search via quickfix
* 📅 Daily notes with auto-added reminders
* 🔍 Interactive picker with preview
* 🌳 Built-in vault explorer
* ☑️ Markdown checkbox support
* 📝 Markdown formatting helpers
* 🗺️ Interactive graph view (backlinks + outgoing links)
* 🧠 Clean architecture (core / ui / editor separation)
* ⚡ Written in Vim9script

---

## 📁 Project Structure

```
autoload/
├── core/
│   ├── backlinks.vim      # Backlinks search
│   ├── daily.vim          # Daily notes
│   ├── notes.vim          # Note operations
│   ├── path.vim           # Path resolution & slugify
│   ├── reminders.vim      # Reminders system
│   ├── tags.vim           # Tags system
│   ├── templates.vim      # Template system
│   └── vault.vim          # Vault configuration
├── editor/
│   ├── checkbox.vim       # Checkbox toggling
│   ├── list.vim           # List handling
│   ├── markdown.vim       # Markdown formatting
│   ├── tags_complete.vim  # Tag autocomplete
│   └── visual.vim         # Visual mode helpers
├── ui/
│   ├── explorer/
│   │   └── explorer.vim   # Vault tree explorer
│   ├── graph/
│   │   ├── domain/
│   │   │   └── graph_state.vim    # Graph state management
│   │   ├── graph.vim      # Graph public API
│   │   └── infrastructure/
│   │       └── window.vim # Graph popup window
│   ├── new_note.vim       # New note picker
│   ├── picker.vim         # Fuzzy picker
│   ├── picker_logic.vim   # Picker business logic
│   └── wiki_links.vim     # Wiki link handling
└── vimsidian.vim

plugin/
└── vimsidian.vim          # Plugin entry point

syntax/
└── markdown.vim          # Markdown syntax highlighting
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
" Required: Set your vault path
let g:vimsidian_vault_path = '~/your-vault'

" Optional: Default template for new notes (default: 'blank')
let g:vimsidian_default_template = 'daily'
```

Notes are stored inside:

```
{vault}/data/
```

---

## 🧾 Commands

### Core

```vim
:VimsidianNew [title]          " Create note (opens picker if no title)
:VimsidianOpen {title}         " Open existing note
:VimsidianFollowLink           " Follow [[link]] under cursor
:VimsidianToday                " Open today's daily note
:VimsidianBacklinks            " Show backlinks
:VimsidianPicker               " Open note picker
:VimsidianToggleExplorer       " Open vault/data explorer
:VimsidianToggleGraph          " Toggle graph panel
:VimsidianReminders            " Show reminders file
:VimsidianScanReminders        " Force scan all notes for reminders
:VimsidianScanTags            " Force scan all notes for tags
```

### Markdown Editing

```vim
:VimsidianToggleCheckbox         " Toggle checkbox on current line
:VimsidianToggleCheckboxVisual   " Toggle checkboxes in visual selection
:VimsidianMakeCheckbox           " Convert current line into checkbox

:VimsidianToggleBold             " Toggle bold in visual mode
:VimsidianToggleItalic          " Toggle italic in visual mode
:VimsidianToggleCode            " Toggle inline code in visual mode
:VimsidianToggleCodeBlock       " Toggle fenced code block in visual mode
:VimsidianToggleQuote           " Toggle quote block in visual mode
:VimsidianToggleList            " Toggle markdown list in visual mode
```

---

## ⌨️ Default Keymaps

### Core

```vim
<leader>vn    New note (opens picker)
<leader>vv    Open picker
<leader>vf    Follow wiki link under cursor
<leader>vt    Open today's note
<leader>vb    Show backlinks
<leader>ve    Open vault explorer
<leader>vg    Toggle graph panel
<leader>vr    Show reminders
```

### Markdown Editing

These mappings are enabled automatically for markdown files.

```vim
Normal mode:
<C-x>         Toggle checkbox
<C-c>         Convert line into checkbox
<CR>          Continue current list / checkbox

Insert mode (in markdown):
<C-x><C-o>   Tag autocomplete (after #)

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

```
[[my-note]]
[[projects/my-note]]
```

* Automatically resolved via link parser
* Target note is created automatically if missing

### Templates

Templates are stored in `{vault}/data/templates/`.

**Available variables:**

| Variable | Description |
|----------|-------------|
| `{{TITLE}}` | Note title |
| `{{DATE}}` | YYYY-MM-DD |
| `{{TIME}}` | HH:MM |
| `{{DATETIME}}` | YYYY-MM-DD HH:MM |
| `{{YEAR}}` | Year |
| `{{MONTH}}` | Month (01-12) |
| `{{DAY}}` | Day (01-31) |
| `{{WEEKDAY}}` | Day name |
| `{{VAULT}}` | Vault path |
| `{{TEMPLATE}}` | Template name |

**Default templates:**
* `blank.md` - Empty note with title
* `daily.md` - Daily note with Tasks/Notes/Review sections

### Reminders

Add reminders using checkbox syntax:

```markdown
- [ ] Call mom every:sunday
- [ ] Pay bills every:1d
- [ ] Review notes every:1w
- [ ] Meeting on:2026-04-25
- [ ] Check reports every:15s
```

**Syntax:**
* `every:Nd` - Every N days
* `every:Nw` - Every N weeks  
* `every:monday` - Every Monday (or any day name)
* `every:Ns` - Nth day of month
* `on:YYYY-MM-DD` - One-time reminder

**Behavior:**
* Scanned on Vim startup and daily note creation
* Due reminders auto-added to daily note
* Consolidated view in `data/reminders.md`

### Tags

Add tags using `#tagname` syntax anywhere in your notes:

```markdown
#project #review #important

This note is about the project.
```

**Usage:**
* Type `#` in picker to filter notes by tag
* In markdown files: `Ctrl-x Ctrl-o` to trigger tag autocomplete
* Tags are highlighted with unique color in markdown

**Behavior:**
* Auto-refreshes on autocomplete trigger
* Search by tag in picker with `#tagname`

### Picker

Features:
* Live fuzzy filtering
* Arrow navigation
* Preview pane with file content
* Content search (starts after 3 seconds)

Actions:
* `Enter` → open note
* `Ctrl-i` → insert wiki link
* `Esc` → close picker
* `Tab/Down` → cycle templates (in new note picker)

### Vault Explorer

Tree-based file explorer for `{vault}/data/`.

Keymaps:
* `Enter` or `o` - Open file / toggle directory
* `r` - Refresh
* `C-d` - Delete
* `C-y` - Copy
* `C-p` - Paste
* `C-m` - Move
* `q` - Close

### Graph Panel

Interactive 3-panel graph view showing current note with backlinks (left) and outgoing links (right).

Keymaps:
* `h` / `Left` - Move to backlinks panel
* `l` / `Right` - Move to links panel
* `j` / `Down` - Navigate down in current panel
* `k` / `Up` - Navigate up in current panel
* `Enter` or `o` - Open selected note
* `q` - Close graph panel

---

## 🌍 Unicode / Cyrillic Support

* Titles remain unchanged (UTF-8)
* File names are transliterated to ASCII

Example:

```
Задача → zadacha.md
```

Benefits:
* Stable filenames
* Reliable search
* No encoding issues

---

## 🏗 Architecture Philosophy

Vimsidian follows a clean layered design:

* `core/` → business logic (notes, reminders, templates)
* `ui/` → Vim interaction layer (picker, explorer)
* `editor/` → markdown editing helpers
* `vimsidian.vim` → public facade
* `plugin/vimsidian.vim` → commands and autocmds

This keeps:
* code testable
* logic reusable
* UI decoupled

---

## 🚀 Roadmap

* [x] Tags support (`#tag`)
* [x] Graph view
* [ ] Media insertion helpers

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
