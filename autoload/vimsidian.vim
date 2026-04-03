vim9script

import autoload 'ui/picker_logic.vim' as picker_logic
import autoload 'ui/wiki_links.vim' as wiki_links
import autoload 'core/vault.vim' as vault
import autoload 'core/path.vim' as path
import autoload 'core/notes.vim' as notes
import autoload 'core/backlinks.vim' as backlinks
import autoload 'core/daily.vim' as daily
import autoload 'editor/markdown.vim' as md
import autoload "ui/explorer/explorer.vim" as explorer

if exists('g:loaded_vimsidian')
  finish
endif
g:loaded_vimsidian = 1

# Vault path
if !exists('g:vimsidian_vault_path')
  g:vimsidian_vault_path = '~/VAULT'
endif

# ----------------------------
# Notes
# ----------------------------
export def OpenNote(title: string)
  notes.OpenNote(title)
enddef

export def OpenOrCreateNote(title: string)
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

defcompile
