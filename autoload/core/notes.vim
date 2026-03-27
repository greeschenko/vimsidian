vim9script

import autoload 'core/vault.vim'
import autoload 'core/path.vim'

# ----------------------------
# Notes logic
# ----------------------------
def EnsureVaultExists()
  vault.EnsureDataDir()
enddef

def CreateNote(title: string): string
  EnsureVaultExists()

  var note_path = path.ResolveLink(title)
  var note_dir = fnamemodify(note_path, ':h')
  if !isdirectory(note_dir)
    mkdir(note_dir, 'p')
  endif

  if !filereadable(note_path)
    writefile(['# ' .. fnamemodify(title, ':t:r'), ''], note_path)
  endif

  return note_path
enddef

export def OpenNote(title: string)
  var note_path = path.ResolveLink(title)
  if !filereadable(note_path)
    throw 'Vimsidian: note not found: ' .. title
  endif
  execute 'edit ' .. fnameescape(note_path)
enddef

export def OpenOrCreateNote(title: string)
  var note_path = CreateNote(title)
  execute 'edit ' .. fnameescape(note_path)
enddef

# ----------------------------
# Note metadata
# ----------------------------
export def GetNoteLinkId(note_path: string): string
  var vault_path = vault.GetDataPath()
  var rel_dir = fnamemodify(substitute(note_path, '^' .. vault_path, '', ''), ':h')
  var title = GetNoteTitle(note_path)

  if rel_dir == '.'
    return title
  endif

  return rel_dir .. '/' .. title
enddef

def GetNoteTitle(note_path: string): string
  if !filereadable(note_path)
    return ''
  endif

  var lines = readfile(note_path, '', 1)
  if empty(lines)
    return ''
  endif

  var first_line = lines[0]

  if first_line =~ '^#\s\+'
    return substitute(first_line, '^#\s\+', '', '')
  endif

  # fallback → filename
  return fnamemodify(note_path, ':t:r')
enddef

export def GetAllNotes(): list<string>
  return globpath(vault.GetDataPath(), '**/*.md', 0, 1)
enddef

defcompile
