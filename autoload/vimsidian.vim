vim9script

import autoload 'ui/picker_logic.vim' as picker_logic
import autoload 'ui/wiki_links.vim' as wiki_links
import autoload 'ui/new_note.vim' as new_note
import autoload 'core/vault.vim' as vault
import autoload 'core/path.vim' as path
import autoload 'core/notes.vim' as notes
import autoload 'core/backlinks.vim' as backlinks
import autoload 'core/daily.vim' as daily
import autoload 'core/templates.vim' as templates
import autoload 'core/reminders.vim' as reminders
import autoload 'editor/markdown.vim' as md
import autoload "ui/explorer/explorer.vim" as explorer

if exists('g:loaded_vimsidian')
  finish
endif
g:loaded_vimsidian = 1

augroup vimsidian_startup
  autocmd!
  autocmd VimEnter * ++once call vimsidian.ScanReminders()
augroup END

# Vault path
if !exists('g:vimsidian_vault_path')
  g:vimsidian_vault_path = '~/VAULT'
endif

# Default template
if !exists('g:vimsidian_default_template')
  g:vimsidian_default_template = 'blank'
endif

# ----------------------------
# Notes
# ----------------------------
export def OpenNote(title: string)
    notes.OpenNote(title)
enddef

export def CompleteNoteNames(A: string, L: string, P: number): list<string>
    var all_notes = notes.GetAllNotes()
    return map(all_notes, (_, v) => path.NormalizeNotePath(v))
enddef

def SelectNoteCallback(name: string, template: string)
    notes.OpenOrCreateNoteWithTemplate(name, template)
enddef

export def OpenOrCreateNote(title: string)
    if empty(title)
        new_note.Open({
            on_select: SelectNoteCallback,
        })
        return
    endif

    notes.OpenOrCreateNote(title)
enddef

# ----------------------------
# Wiki links
# ----------------------------
export def FollowLink()
  wiki_links.FollowLink()
enddef

# ----------------------------
# Daily
# ----------------------------
export def TodayNote()
  daily.TodayNote()
enddef

# ----------------------------
# Backlinks
# ----------------------------
export def Backlinks()
  backlinks.Backlinks()
enddef

# ----------------------------
# Picker
# ----------------------------
export def VimsidianPicker()
  picker_logic.VimsidianPicker()
enddef

# ----------------------------
# Explore
# ----------------------------
export def OpenVaultExplorer()
    explorer.ToggleExplorer()
enddef

# ----------------------------
# Reminders
# ----------------------------
export def ScanReminders()
    reminders.ScanAllNotesForReminders()
enddef

export def ShowReminders()
    reminders.ScanAllNotesForReminders()
    var reminders_file = reminders.GetRemindersFilePath()
    execute 'edit ' .. fnameescape(reminders_file)
enddef

defcompile
