vim9script

import autoload 'core/notes.vim'
import autoload 'core/vault.vim' as vault
import autoload 'core/path.vim' as path

var g_state: dict<any> = {
  current_note: '',
  current_path: '',
  links: [],
  backlinks: [],
  selected_index: 0,
  active_popup: 'center',
}

export def GetState(): dict<any>
  return g_state
enddef

export def ResetState()
  g_state.current_note = ''
  g_state.current_path = ''
  g_state.links = []
  g_state.backlinks = []
  g_state.selected_index = 0
  g_state.active_popup = 'center'
enddef

export def LoadFromCurrentNote(): bool
  var note_path = expand('%:p')
  if empty(note_path)
    return false
  endif

  var data_path = vault.GetDataPath()
  if stridx(note_path, data_path) != 0
    return false
  endif

  var note_id = notes.GetNoteLinkId(note_path)
  g_state.current_note = note_id
  g_state.current_path = note_path
  g_state.links = FindLinks(note_path)
  g_state.backlinks = FindBacklinks(note_path)
  g_state.selected_index = 0
  g_state.active_popup = 'center'
  return true
enddef

export def ResolveNote(note_name: string): string
  return path.ResolveLink(note_name)
enddef

def FindLinks(note_path: string): list<string>
  if !filereadable(note_path)
    return []
  endif

  var content = readfile(note_path)
  var text = join(content, ' ')
  var links: list<string> = []

  var rest = text
  while true
    var open = stridx(rest, '[[')
    if open < 0 | break | endif

    var close = stridx(rest, ']]', open + 2)
    if close < 0 | break | endif

    var link = strpart(rest, open + 2, close - open - 2)
    if index(links, link) < 0
      add(links, link)
    endif
    rest = strpart(rest, close + 2)
  endwhile

  return sort(links)
enddef

def FindBacklinks(note_path: string): list<string>
  var note_id = notes.GetNoteLinkId(note_path)
  var data_path = vault.GetDataPath()

  var pattern = '\V\c[[' .. note_id .. ']]'
  var files = globpath(data_path, '**/*.md', 0, 1)
  var links: list<string> = []

  for f in files
    if f == note_path
      continue
    endif

    var lines = readfile(f)
    for line in lines
      if match(line, pattern) >= 0
        var title = notes.GetNoteTitle(f)
        if index(links, title) < 0
          add(links, title)
        endif
        break
      endif
    endfor
  endfor

  return sort(links)
enddef

export def GetSelectedName(): string
  if g_state.active_popup == 'center'
    return g_state.current_note
  elseif g_state.active_popup == 'backlinks'
    if g_state.selected_index < len(g_state.backlinks)
      return g_state.backlinks[g_state.selected_index]
    endif
  elseif g_state.active_popup == 'links'
    if g_state.selected_index < len(g_state.links)
      return g_state.links[g_state.selected_index]
    endif
  endif
  return ''
enddef

export def FocusSelected()
  var note_name = GetSelectedName()
  if empty(note_name) || g_state.active_popup == 'center'
    return
  endif

  var note_path = path.ResolveLink(note_name)
  if !filereadable(note_path)
    return
  endif

  var note_id = notes.GetNoteLinkId(note_path)
  g_state.current_note = note_id
  g_state.current_path = note_path
  g_state.links = FindLinks(note_path)
  g_state.backlinks = FindBacklinks(note_path)
  g_state.selected_index = 0
  g_state.active_popup = 'center'
enddef

export def Navigate(dir: number)
  var total = len(GetCurrentList())
  if total == 0
    return
  endif

  var new_idx = g_state.selected_index + dir
  if new_idx < 0
    new_idx = total - 1
  elseif new_idx >= total
    new_idx = 0
  endif

  g_state.selected_index = new_idx
enddef

export def SwitchPopup(direction: string)
  if direction == 'left'
    g_state.active_popup = 'backlinks'
  elseif direction == 'right'
    g_state.active_popup = 'links'
  else
    g_state.active_popup = 'center'
  endif
  g_state.selected_index = 0
enddef

export def GetCurrentList(): list<string>
  if g_state.active_popup == 'backlinks'
    return g_state.backlinks
  elseif g_state.active_popup == 'links'
    return g_state.links
  endif
  return []
enddef

defcompile