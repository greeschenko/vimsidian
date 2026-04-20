vim9script

import autoload 'core/vault.vim'
import autoload 'core/path.vim'
import autoload "core/templates.vim"

# ----------------------------
# Notes logic
# ----------------------------
def EnsureVaultExists()
  vault.EnsureDataDir()
enddef

def CreateNote(raw_title: string): string
    EnsureVaultExists()

    var title = raw_title
    var template_name = ''

    var parts = split(raw_title)

    if len(parts) > 1 && parts[-1] =~ '^template:'
        template_name = substitute(parts[-1], '^template:', '', '')
        remove(parts, -1)
        title = join(parts, ' ')
    endif

    var note_path = path.ResolveLink(title)
    var note_dir = fnamemodify(note_path, ':h')

    if !isdirectory(note_dir)
        mkdir(note_dir, 'p')
    endif

    if !filereadable(note_path)
        if !empty(template_name)
            if !templates.ApplyTemplate(note_path, template_name)
                throw 'Vimsidian: failed to apply template: ' .. template_name
            endif
        else
            writefile(['# ' .. fnamemodify(title, ':t:r'), ''], note_path)
        endif
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

export def OpenOrCreateNoteWithTemplate(title: string, template_name: string)
    var note_path = CreateNoteWithTemplate(title, template_name)
    execute 'edit ' .. fnameescape(note_path)
enddef

def CreateNoteWithTemplate(title: string, template_name: string): string
    EnsureVaultExists()

    var note_path = path.ResolveLink(title)
    var note_dir = fnamemodify(note_path, ':h')

    if !isdirectory(note_dir)
        mkdir(note_dir, 'p')
    endif

    if !filereadable(note_path)
        if !empty(template_name) && template_name != 'blank'
            if !templates.ApplyTemplate(note_path, template_name)
                throw 'Vimsidian: failed to apply template: ' .. template_name
            endif
        else
            writefile(['# ' .. fnamemodify(title, ':t:r'), ''], note_path)
        endif
    endif

    return note_path
enddef

# ----------------------------
# Note metadata
# ----------------------------
export def GetNoteLinkId(note_path: string): string
  var vault_path = vault.GetDataPath()
  var rel_path = substitute(note_path, '^' .. vault_path, '', '')
  rel_path = substitute(rel_path, '^/', '', '')

  var rel_dir = fnamemodify(rel_path, ':h')
  var title = GetNoteTitle(note_path)

  if rel_dir == '.'
    return title
  endif

  return rel_dir .. '/' .. title
enddef

export def GetNoteTitle(note_path: string): string
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
