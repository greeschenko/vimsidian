vim9script

import autoload "core/path.vim" as path
import autoload "core/tags.vim" as tags_module

var state: dict<any> = {
  all: [],
  filtered: [],
  query: '',
  index: 0,
  menu: -1,
  prompt: -1,
  preview: -1,
  opts: {},
  content_matches: [],
  content_timer: 0,
  content_search_done: 0,
  all_paths: [],
}

# ----------------------------
# PUBLIC API
# ----------------------------
export def Open(items: list<string>, opts: dict<any>)
  state.all = items
  state.filtered = items
  state.query = ''
  state.index = 0
  state.opts = opts

  state.content_matches = []
  state.content_search_done = 0
  state.all_paths = []

  if has_key(opts, 'item_paths')
    state.all_paths = opts.item_paths
  endif

  if has_key(opts, 'search_by_tag')
    tags_module.ScanAllNotesForTags()
  endif

  if state.content_timer != 0
    timer_stop(state.content_timer)
    state.content_timer = 0
  endif

  InitUI()
  Update()
enddef

# ----------------------------
# UI INIT
# ----------------------------
def InitUI()
  var menu_width = 60
  var preview_width = 60
  var height = 20

  var total_width = menu_width + preview_width + 2

  var row = (&lines - height) / 2
  var col = (&columns - total_width) / 2

  state.menu = popup_create([], {
    line: row,
    col: col,
    minwidth: menu_width,
    minheight: height,
    maxheight: height,
    border: [],
    borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    cursorline: 1,
    mapping: false,
    zindex: 200,
  })

  state.preview = popup_create([], {
    line: row,
    col: col + menu_width + 2,
    minwidth: preview_width,
    maxwidth: preview_width,
    minheight: height,
    maxheight: height,
    border: [],
    borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    wrap: true,
    mapping: false,
    zindex: 200,
  })

  state.prompt = popup_create('Search: ', {
    line: row - 2,
    col: col,
    minwidth: total_width,
    minheight: 1,
    border: [],
    borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    filter: function('PromptFilter'),
    mapping: false,
    zindex: 200,
  })
enddef

# ----------------------------
# FUZZY SEARCH
# ----------------------------
def FuzzyScore(item: string, query: string): number
  var q = tolower(query)
  var s = tolower(item)

  if empty(q)
    return 1
  endif

  if s == q
    return 1000
  endif

  if stridx(s, q) == 0
    return 900 + strchars(s)
  endif

  if stridx(s, q) >= 0
    return 800 + strchars(s)
  endif

  var score = 0
  var q_idx = 0
  var last_pos = -1
  var consecutive = 0

  for i in range(strchars(s))
    if q_idx >= strchars(q)
      break
    endif

    var ch = s[i]
    if ch == q[q_idx]
      if last_pos == i - 1
        consecutive += 1
        score += 10 + consecutive * 5
      else
        consecutive = 0
        score += 5
      endif

      if i == 0 || i > 0 && (s[i - 1] == ' ' || s[i - 1] == '-' || s[i - 1] == '_' || s[i - 1] == '/' || s[i - 1] == '.')
        score += 15
      endif

      last_pos = i
      q_idx += 1
    endif
  endfor

  if q_idx < strchars(q)
    return 0
  endif

  return score
enddef

# ----------------------------
# CORE
# ----------------------------
def Filter()
  var q = state.query

  if empty(q)
    state.filtered = copy(state.all)
    state.index = 0
    return
  endif

  if q[0] == '#' && has_key(state.opts, 'search_by_tag')
    var tag_name = strpart(q, 1)
    if !empty(tag_name)
      var note_paths = state.opts.search_by_tag(tag_name)
      var results: list<string> = []

      for np in note_paths
        var normalized = path.NormalizeNotePath(np)
        add(results, normalized)
      endfor

      if !empty(results)
        state.filtered = results
        state.all_paths = note_paths
        state.index = 0
        return
      endif
    endif
  endif

  var scored: list<dict<any>> = []

  for item in state.all
    var score = FuzzyScore(item, q)
    if score > 0
      add(scored, {item: item, score: score})
    endif
  endfor

  scored = sort(scored, (a, b) => b.score - a.score)

  state.filtered = []
  for s in scored
    add(state.filtered, s.item)
  endfor
  state.index = 0

  StartContentSearch()
enddef

def StartContentSearch()
  if state.content_timer != 0
    timer_stop(state.content_timer)
    state.content_timer = 0
  endif

  state.content_matches = []
  state.content_search_done = 0

  if empty(state.query) || empty(state.all_paths)
    state.content_search_done = 1
    return
  endif

  state.content_timer = timer_start(3000, function('RunContentSearch'))
enddef

def RunContentSearch(timer: number)
  if empty(state.query) || empty(state.all_paths)
    state.content_search_done = 1
    return
  endif

  state.content_matches = []
  var q = tolower(state.query)

  for idx in range(len(state.all_paths))
    if idx >= len(state.all)
      continue
    endif

    var item_path = state.all_paths[idx]
    if !filereadable(item_path)
      continue
    endif

    var lines = readfile(item_path, '', 100)
    var found = false

    for line in lines
      if stridx(tolower(line), q) >= 0
        found = true
        break
      endif
    endfor

    if found
      add(state.content_matches, state.all[idx])
    endif
  endfor

  state.content_search_done = true

  for cm in state.content_matches
    var found = false
    for f in state.filtered
      if stridx(tolower(f), tolower(cm)) >= 0
        found = true
        break
      endif
    endfor

    if !found
      add(state.filtered, '~' .. cm)
    endif
  endfor

  if !empty(state.content_matches)
    RenderMenu()
  endif
enddef

def Update()
  if state.content_timer != 0
    timer_stop(state.content_timer)
    state.content_timer = 0
  endif

  Filter()
  RenderMenu()
  RenderPrompt()
  RenderPreview()
enddef

# ----------------------------
# RENDER
# ----------------------------
def RenderMenu()
  var lines = empty(state.filtered) ? ['(no results)'] : copy(state.filtered)

  popup_settext(state.menu, lines)

  win_execute(state.menu,
        'call cursor(' .. (state.index + 1) .. ', 1)')
enddef

def RenderPrompt()
  popup_settext(state.prompt, 'Search: ' .. state.query)
enddef

def RenderPreview()
  if empty(state.filtered)
    popup_settext(state.preview, ['(no preview)'])
    return
  endif

  if !has_key(state.opts, 'preview')
    popup_settext(state.preview, ['(no preview handler)'])
    return
  endif

  var item = state.filtered[state.index]
  var q = state.query

  if stridx(item, '~') == 0
    var item_clean = strpart(item, 1)
    if has_key(state.opts, 'resolve_path')
      var note_path = state.opts.resolve_path(item_clean)
      if filereadable(note_path)
        popup_settext(state.preview, readfile(note_path, '', 40))
        return
      endif
    endif
    popup_settext(state.preview, ['(content match - path not resolved)'])
    return
  endif

  var content: list<string>

  if has_key(state.opts, 'preview_with_highlight')
    content = state.opts.preview_with_highlight(item, q)
  else
    content = state.opts.preview(item)
  endif

  if type(content) != v:t_list
    content = [string(content)]
  endif

  popup_settext(state.preview, content)
enddef

# ----------------------------
# CLOSE
# ----------------------------
def Close()
  if state.content_timer != 0
    timer_stop(state.content_timer)
    state.content_timer = 0
  endif

  if state.menu != -1
    popup_close(state.menu)
  endif
  if state.prompt != -1
    popup_close(state.prompt)
  endif
  if state.preview != -1
    popup_close(state.preview)
  endif
enddef

# ----------------------------
# INPUT
# ----------------------------
def PromptFilter(id: number, key: string): number

  # --- exit ---
  if key == "\<Esc>"
    Close()
    return 1
  endif

  # --- select ---
  if key == "\<CR>"
    if len(state.filtered) > 0
      var item = state.filtered[state.index]
      Close()

      if stridx(item, '~') == 0
        var item_clean = strpart(item, 1)
        if has_key(state.opts, 'on_select')
          state.opts.on_select(item_clean)
        endif
      elseif has_key(state.opts, 'on_select')
        state.opts.on_select(item)
      endif
    endif
    return 1
  endif

  # --- custom action (insert etc) ---
  if key == "\<C-i>"
    if len(state.filtered) > 0
      var item = state.filtered[state.index]
      var item_to_use = item

      if stridx(item, '~') == 0
        item_to_use = strpart(item, 1)
      endif

      Close()

      if has_key(state.opts, 'on_insert')
        state.opts.on_insert(item_to_use)
      endif
    endif
    return 1
  endif

  # --- navigation ---
  if key == "\<Down>" || key == "\<C-j>"
    if state.index < len(state.filtered) - 1
      state.index += 1
      RenderMenu()
      RenderPreview()
    endif
    return 1
  endif

  if key == "\<Up>" || key == "\<C-k>"
    if state.index > 0
      state.index -= 1
      RenderMenu()
      RenderPreview()
    endif
    return 1
  endif

  # --- backspace ---
  if key == "\<BS>"
    if strlen(state.query) > 0
      state.query =
        strcharpart(state.query, 0, strchars(state.query) - 1)
      Update()
    endif
    return 1
  endif

  # --- typing ---
  if strlen(key) == 1 && char2nr(key) >= 32
    state.query ..= key
    Update()
    return 1
  endif

  return 1
enddef

defcompile
