vim9script

import autoload 'ui/picker.vim'
import autoload 'core/path.vim'
import autoload 'core/notes.vim'
import autoload 'core/tags.vim' as tags

def ResolveNote(note: string): string
  return path.ResolveLink(note)
enddef

def SearchByTag(tag: string): list<string>
  return tags.SearchByTag(tag)
enddef

def GetTagSuggestions(prefix: string): list<string>
  return tags.GetTagSuggestions(prefix)
enddef

def HighlightMatches(lines: list<string>, query: string): list<string>
  if empty(query)
    return lines
  endif

  var q = tolower(query)
  var result: list<string> = []
  var context_before = 1
  var context_after = 1

  for i in range(len(lines))
    var line = lines[i]
    if stridx(tolower(line), q) >= 0
      var start = i - context_before
      if start < 0
        start = 0
      endif

      var end_idx = i + context_after
      if end_idx >= len(lines)
        end_idx = len(lines) - 1
      endif

      for j in range(start, end_idx + 1)
        if j < len(lines)
          add(result, lines[j])
        endif
      endfor

      add(result, '')
    endif
  endfor

  if empty(result)
    return lines
  endif

  return result
enddef

export def VimsidianPicker()
  var notes_list = []
  var note_paths: list<string> = []

  for f in notes.GetAllNotes()
    var normalized = path.NormalizeNotePath(f)
    add(notes_list, normalized)
    add(note_paths, path.ResolveLink(normalized))
  endfor

  picker.Open(notes_list, {
    item_paths: note_paths,

    resolve_path: (note: string) => path.ResolveLink(note),

    search_by_tag: (tag: string) => SearchByTag(tag),

    get_tag_suggestions: (prefix: string) => GetTagSuggestions(prefix),

    preview: (note) => {
      var note_path = path.ResolveLink(note)
      if !filereadable(note_path)
        return ['(file not found)']
      endif
      return readfile(note_path, '', 40)
    },

    preview_with_highlight: (note, query) => {
      var note_path = path.ResolveLink(note)
      if !filereadable(note_path)
        return ['(file not found)']
      endif
      var lines = readfile(note_path, '', 40)
      return HighlightMatches(lines, query)
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
