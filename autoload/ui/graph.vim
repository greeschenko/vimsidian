vim9script

import autoload 'core/notes.vim'
import autoload 'core/vault.vim' as vault
import autoload 'core/backlinks.vim' as backlinks

var graph_win = -1
var graph_buf = -1
var current_note_id: string = ''
var forward_links: list<string> = []
var back_links: list<string> = []

export def OpenGraphView()
  var note_path = expand('%:p')
  if empty(note_path)
    echom 'Vimsidian: no note open'
    return
  endif

  if graph_win != -1 && win_gotoid(graph_win)
    CloseGraphWindow()
    return
  endif

  current_note_id = notes.GetNoteLinkId(note_path)

  execute ':sp'

  graph_win = win_getid()
  graph_buf = bufnr()

  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nowrap
  setlocal nonumber
  setlocal norelativenumber
  setlocal signcolumn=no
  setlocal foldcolumn=0
  setlocal nobuflisted
  setlocal modifiable
  setlocal filetype=vimsidian-graph

  RenderGraph()

  nnoremap <buffer> <CR> <ScriptOpen><SID>OpenSelected()<CR>
  nnoremap <buffer> o <ScriptOpen><SID>OpenSelected()<CR>
  nnoremap <buffer> <Tab> <ScriptOpen><SID>ToggleSection()<CR>
  nnoremap <buffer> q <ScriptOpen><SID>CloseGraph()<CR>
enddef

def RenderGraph()
  forward_links = FindForwardLinks(current_note_id)
  back_links = FindBacklinks(current_note_id)

  var lines: list<string> = []

  add(lines, '# ' .. current_note_id)
  add(lines, '')
  add(lines, '## → Links (' .. len(forward_links) .. ')')
  for link in forward_links
    add(lines, '  → ' .. link)
  endfor

  add(lines, '')
  add(lines, '## ← Backlinks (' .. len(back_links) .. ')')
  for link in back_links
    add(lines, '  ← ' .. link)
  endfor

  add(lines, '')
  add(lines, '<CR>/o open | <Tab> toggle section | q quit')

  setline(1, lines)
  setlocal nomodifiable
enddef

def FindForwardLinks(note_id: string): list<string>
  var note_path = expand('%:p')
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

def FindBacklinks(note_id: string): list<string>
  var pattern = '\V\c[[' .. note_id .. ']]'
  var data_path = vault.GetDataPath()

  var files = globpath(data_path, '**/*.md', 0, 1)
  var links: list<string> = []

  for f in files
    if f == expand('%:p')
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

def OpenSelected()
  var line = getline('.')
  if stridx(line, '# ') == 0
    return
  endif

  var link = substitute(line, '^[→←]\s\+', '', '')
  if empty(link)
    return
  endif

  CloseGraphWindow()
  notes.OpenOrCreateNote(link)
enddef

def ToggleSection()
  var l = line('.')
  var line = getline(l)
  if stridx(line, '## ← Backlinks') >= 0
    execute '4'
  elseif stridx(line, '## → Links') >= 0
    normal! gg
  endif
enddef

def CloseGraph()
  CloseGraphWindow()
enddef

def CloseGraphWindow()
  if graph_win != -1
    var wid = graph_win
    graph_win = -1
    graph_buf = -1
    current_note_id = ''
    forward_links = []
    back_links = []
    if win_gotoid(wid)
      close
    endif
  endif
enddef

defcompile