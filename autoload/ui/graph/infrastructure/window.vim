vim9script

import autoload 'ui/graph/domain/graph_state.vim' as domain
import autoload 'core/notes.vim' as notes

var state: dict<any> = {
  popup_center: -1,
  popup_backlinks: [],
  popup_links: [],
  active_popup_idx: 0,
  active_side: 'center',
  start_row: 0,
  center_row: 0,
  start_col: 0,
}

var WIDTH = 45
var HEIGHT = 15
var SPACING = 2
var VERT_SPACING = 2

def GetMaxSide(): number
  return (&lines - 6) / (1 + VERT_SPACING)
enddef
defcompile

export def GetWindowId(): number
  return state.popup_center
enddef

export def CloseWindow()
  if state.popup_center != -1
    popup_close(state.popup_center)
    state.popup_center = -1
  endif

  for pid in state.popup_backlinks
    if pid != -1
      popup_close(pid)
    endif
  endfor
  state.popup_backlinks = []

  for pid in state.popup_links
    if pid != -1
      popup_close(pid)
    endif
  endfor
  state.popup_links = []

  domain.ResetState()
enddef

export def OpenWindow()
  CloseWindow()

  if !domain.LoadFromCurrentNote()
    return
  endif

  var g = domain.GetState()

  var total_height = GetMaxSide() + 2
  var start_row = (&lines - total_height) / 2
  var center_row = start_row + GetMaxSide() / 2
  var start_col = (&columns - WIDTH * 3 - SPACING * 2) / 2

  state.start_row = start_row
  state.center_row = center_row
  state.start_col = start_col

  var center_text = '● ' .. g.current_note
  state.popup_center = popup_create([center_text], {
    line: center_row,
    col: start_col + WIDTH + SPACING,
    minwidth: WIDTH,
    maxwidth: WIDTH,
    minheight: 1,
    maxheight: 1,
    border: [],
    borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    cursorline: 1,
    mapping: false,
    zindex: 200,
    filter: function('PopupFilter'),
  })

  var back_count = len(g.backlinks)
  if back_count > GetMaxSide()
    back_count = GetMaxSide()
  endif
  for i in range(back_count)
    var note_name = g.backlinks[i]
    var row = start_row + i * (1 + VERT_SPACING)
    var prefix = (i == 0 && state.active_side == 'backlinks') ? '▶ ' : '  '
    var pid = popup_create([prefix .. note_name], {
      line: row,
      col: start_col,
      minwidth: WIDTH,
      maxwidth: WIDTH,
      minheight: 1,
      maxheight: 1,
      border: [],
      borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
      cursorline: 1,
      mapping: false,
      zindex: 199,
      filter: function('PopupFilter'),
    })
    add(state.popup_backlinks, pid)
  endfor

  var link_count = len(g.links)
  if link_count > GetMaxSide()
    link_count = GetMaxSide()
  endif
  for i in range(link_count)
    var note_name = g.links[i]
    var row = start_row + i * (1 + VERT_SPACING)
    var prefix = (i == 0 && state.active_side == 'links') ? '▶ ' : '  '
    var pid = popup_create([prefix .. note_name], {
      line: row,
      col: start_col + WIDTH * 2 + SPACING * 2,
      minwidth: WIDTH,
      maxwidth: WIDTH,
      minheight: 1,
      maxheight: 1,
      border: [],
      borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
      cursorline: 1,
      mapping: false,
      zindex: 199,
      filter: function('PopupFilter'),
    })
    add(state.popup_links, pid)
  endfor

  state.active_side = 'center'
  state.active_popup_idx = 0
enddef

def RecreateBacklinks()
  for pid in state.popup_backlinks
    if pid != -1
      popup_close(pid)
    endif
  endfor
  state.popup_backlinks = []

  var g = domain.GetState()
  var max_side = GetMaxSide()
  var back_count = len(g.backlinks)
  if back_count > max_side
    back_count = max_side
  endif

  for i in range(back_count)
    var note_name = g.backlinks[i]
    var row = state.start_row + i * (1 + VERT_SPACING)
    var prefix = '  '
    var pid = popup_create([prefix .. note_name], {
      line: row,
      col: state.start_col,
      minwidth: WIDTH,
      maxwidth: WIDTH,
      minheight: 1,
      maxheight: 1,
      border: [],
      borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
      cursorline: 1,
      mapping: false,
      zindex: 199,
      filter: function('PopupFilter'),
    })
    add(state.popup_backlinks, pid)
  endfor
enddef

def RecreateLinks()
  for pid in state.popup_links
    if pid != -1
      popup_close(pid)
    endif
  endfor
  state.popup_links = []

  var g = domain.GetState()
  var max_side = GetMaxSide()
  var link_count = len(g.links)
  if link_count > max_side
    link_count = max_side
  endif

  for i in range(link_count)
    var note_name = g.links[i]
    var row = state.start_row + i * (1 + VERT_SPACING)
    var prefix = '  '
    var pid = popup_create([prefix .. note_name], {
      line: row,
      col: state.start_col + WIDTH * 2 + SPACING * 2,
      minwidth: WIDTH,
      maxwidth: WIDTH,
      minheight: 1,
      maxheight: 1,
      border: [],
      borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
      cursorline: 1,
      mapping: false,
      zindex: 199,
      filter: function('PopupFilter'),
    })
    add(state.popup_links, pid)
  endfor
enddef

export def Render()
  var g = domain.GetState()

  var active_idx = state.active_popup_idx
  var active_side = state.active_side

  var max_side = GetMaxSide()
  var back_count = len(g.backlinks) > max_side ? max_side : len(g.backlinks)
  var link_count = len(g.links) > max_side ? max_side : len(g.links)
  var actual_count = back_count > link_count ? back_count : link_count

  var total_height = actual_count * (1 + VERT_SPACING) + 2
  if total_height > &lines - 4
    total_height = &lines - 4
  endif
  state.start_row = (&lines - total_height) / 2
  state.center_row = state.start_row + actual_count * (1 + VERT_SPACING) / 2
  state.start_col = (&columns - WIDTH * 3 - SPACING * 2) / 2

  if len(state.popup_backlinks) != back_count
    RecreateBacklinks()
  endif

  if len(state.popup_links) != link_count
    RecreateLinks()
  endif

  if state.popup_center != -1
    var center_text = '● ' .. g.current_note
    if active_side == 'center'
      center_text = '▶ ' .. g.current_note
    endif
    popup_settext(state.popup_center, [center_text])
  endif

  for i in range(len(state.popup_backlinks))
    if i < len(g.backlinks)
      var prefix = (i == active_idx && active_side == 'backlinks') ? '▶ ' : '  '
      popup_settext(state.popup_backlinks[i], [prefix .. g.backlinks[i]])
    endif
  endfor

  for i in range(len(state.popup_links))
    if i < len(g.links)
      var prefix = (i == active_idx && active_side == 'links') ? '▶ ' : '  '
      popup_settext(state.popup_links[i], [prefix .. g.links[i]])
    endif
  endfor
enddef

def CloseAll()
  var all_ids = [state.popup_center] + state.popup_backlinks + state.popup_links
  for pid in all_ids
    if pid != -1
      popup_close(pid)
    endif
  endfor
  state.popup_center = -1
  state.popup_backlinks = []
  state.popup_links = []
  domain.ResetState()
enddef

def PopupFilter(id: number, key: string): number
  if key == 'q'
    CloseAll()
    return 1
  endif

  var note_name = ''
  var g = domain.GetState()
  var active_idx = state.active_popup_idx

  if state.active_side == 'center'
    note_name = g.current_note
  elseif state.active_side == 'backlinks'
    if active_idx < len(g.backlinks)
      note_name = g.backlinks[active_idx]
    endif
  elseif state.active_side == 'links'
    if active_idx < len(g.links)
      note_name = g.links[active_idx]
    endif
  endif

  if key == '\<CR>' || key == 'o'
    if !empty(note_name)
      notes.OpenOrCreateNote(note_name)
    endif
    return 1
  endif

  if key == 'h' || key == '\<Left>'
    if state.active_side == 'center'
      state.active_side = 'backlinks'
    elseif state.active_side == 'links'
      state.active_side = 'center'
    endif
    state.active_popup_idx = 0
    Render()
    return 1
  endif

  if key == 'l' || key == '\<Right>'
    if state.active_side == 'center'
      state.active_side = 'links'
    elseif state.active_side == 'backlinks'
      state.active_side = 'center'
    endif
    state.active_popup_idx = 0
    Render()
    return 1
  endif

  if key == 'j' || key == '\<Down>' || key == '\<C-j>'
    var max_idx = 0
    if state.active_side == 'backlinks'
      max_idx = len(g.backlinks) - 1
    elseif state.active_side == 'links'
      max_idx = len(g.links) - 1
    else
      return 1
    endif

    if max_idx > 0
      state.active_popup_idx = (state.active_popup_idx + 1) % (max_idx + 1)
      Render()
    endif
    return 1
  endif

  if key == 'k' || key == '\<Up>' || key == '\<C-k>'
    var max_idx = 0
    if state.active_side == 'backlinks'
      max_idx = len(g.backlinks) - 1
    elseif state.active_side == 'links'
      max_idx = len(g.links) - 1
    else
      return 1
    endif

    if max_idx > 0
      state.active_popup_idx = state.active_popup_idx - 1
      if state.active_popup_idx < 0
        state.active_popup_idx = max_idx
      endif
      Render()
    endif
    return 1
  endif

  return 0
enddef

defcompile