vim9script

import autoload 'core/notes.vim'
import autoload 'core/vault.vim' as vault
import autoload 'core/path.vim' as path

var graph_win = -1
var graph_buf = -1
var current_note_id = ''

export def OpenGraphPanel()
  if graph_win != -1 && win_gotoid(graph_win)
    return
  endif

  execute 'vertical :30new'

  graph_win = win_getid()
  graph_buf = bufnr()

  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nowrap
  setlocal nonumber
  setlocal norelativenumber
  setlocal signcolumn=no
  setlocal foldcolumn=0
  setlocal winfixwidth
  setlocal nobuflisted
  setlocal modifiable
  setlocal filetype=vimsidian-graph

  UpdateGraph()

  nnoremap <buffer> <CR> <ScriptOpen><SID>OpenLinkFromGraph()<CR>
  nnoremap <buffer> o <ScriptOpen><SID>OpenLinkFromGraph()<CR>
  nnoremap <buffer> q <ScriptOpen><SID>CloseGraphPanel()<CR>
enddef

export def CloseGraphPanel()
  if graph_win != -1
    var wid = graph_win
    graph_win = -1
    graph_buf = -1
    current_note_id = ''
    if win_gotoid(wid)
      close
    endif
  endif
enddef

export def ToggleGraphPanel()
  if graph_win != -1 && win_gotoid(graph_win)
    CloseGraphPanel()
  else
    OpenGraphPanel()
  endif
enddef

export def UpdateGraph()
  var note_path = expand('%:p')
  if empty(note_path)
    return
  endif

  var data_path = vault.GetDataPath()
  if stridx(note_path, data_path) != 0
    return
  endif

  if graph_buf == -1 || !bufexists(graph_buf)
    return
  endif

  current_note_id = notes.GetNoteLinkId(note_path)
  var forward = FindLinks(note_path)
  var back = FindBacklinks(note_path)

  var lines: list<string> = []
  add(lines, '📄 ' .. current_note_id)
  add(lines, '')

  if !empty(forward)
    add(lines, '→ Links (' .. len(forward) .. ')')
    for l in forward
      add(lines, '  → ' .. l)
    endfor
  endif

  if !empty(back)
    add(lines, '')
    add(lines, '← Backlinks (' .. len(back) .. ')')
    for l in back
      add(lines, '  ← ' .. l)
    endfor
  endif

  if empty(forward) && empty(back)
    add(lines, '(no links)')
  endif

  setbufline(graph_buf, 1, lines)
  setbufline(graph_buf, len(lines) + 1, '')

  if graph_win != -1
    win_gotoid(graph_win)
    normal! gg
  endif
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

def OpenLinkFromGraph()
  var line = getline('.')
  if stridx(line, '→ ') != 0 && stridx(line, '← ') != 0
    return
  endif

  var link = strpart(line, 2)
  if link =~ '^ '
    link = strpart(link, 1)
  endif

  if empty(link)
    return
  endif

  notes.OpenOrCreateNote(link)
enddef

def CloseGraphPanelWindow()
  if graph_win != -1
    var wid = graph_win
    graph_win = -1
    graph_buf = -1
    current_note_id = ''
    if win_gotoid(wid)
      close
    endif
  endif
enddef

defcompile