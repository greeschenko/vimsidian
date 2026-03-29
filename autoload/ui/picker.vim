vim9script

var state = {
  all: [],
  filtered: [],
  query: '',
  index: 0,
  menu: -1,
  prompt: -1,
  preview: -1,
  opts: {},
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
# CORE
# ----------------------------
def Filter()
  var q = tolower(state.query)
  var res = []

  for item in state.all
    if empty(q) || stridx(tolower(item), q) >= 0
      add(res, item)
    endif
  endfor

  state.filtered = res
  state.index = 0
enddef

def Update()
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
  var content = state.opts.preview(item)

  if type(content) != v:t_list
    content = [string(content)]
  endif

  popup_settext(state.preview, content)
enddef

# ----------------------------
# CLOSE
# ----------------------------
def Close()
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

      if has_key(state.opts, 'on_select')
        state.opts.on_select(item)
      endif
    endif
    return 1
  endif

  # --- custom action (insert etc) ---
  if key == "\<C-i>"
    if len(state.filtered) > 0
      var item = state.filtered[state.index]
      Close()

      if has_key(state.opts, 'on_insert')
        state.opts.on_insert(item)
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
