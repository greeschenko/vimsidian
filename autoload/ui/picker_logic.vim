vim9script

import autoload 'ui/picker.vim'
import autoload 'core/path.vim'
import autoload 'core/notes.vim'

# ----------------------------
# Picker logic
# ----------------------------
export def VimsidianPicker()
  var notes_list = []
  for f in notes.GetAllNotes()
    add(notes_list, path.NormalizeNotePath(f))
  endfor

  picker.Open(notes_list, {
    preview: (note) => {
      var note_path = path.ResolveLink(note)
      if !filereadable(note_path)
        return ['(file not found)']
      endif
      return readfile(note_path, '', 40)
    },

    on_select: (note) => {
      execute 'edit ' .. fnameescape(path.ResolveLink(note))
    },

    on_insert: (note) => {
      var link = '[[' .. note .. ']]'
      var line = getline('.')
      var coln = col('.') - 1

      setline('.', strpart(line, 0, coln) .. link .. strpart(line, coln))
      cursor(line('.'), coln + strlen(link) + 1)
    }
  })
enddef

defcompile
