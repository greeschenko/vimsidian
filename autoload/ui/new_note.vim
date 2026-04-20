vim9script

import autoload "core/vault.vim" as vault
import autoload "core/templates.vim" as templates
import autoload "core/path.vim" as path

var state: dict<any> = {
  note_name: '',
  templates: [],
  template_index: 0,
  name_input: -1,
  menu: -1,
  preview: -1,
}

var OnSelectCallback: func(string, string)

def DefaultOnSelect(name: string, template: string)
enddef

export def Open(opts: dict<any>)
  if has_key(opts, 'on_select')
    OnSelectCallback = opts.on_select
  else
    OnSelectCallback = DefaultOnSelect
  endif

  templates.EnsureTemplatesExist()
  state.templates = templates.ListTemplates()
  state.note_name = ''
  state.template_index = 0

  InitUI()
  Update()
enddef

def InitUI()
  var menu_width = 30
  var preview_width = 50
  var height = 20
  var total_width = menu_width + preview_width + 2

  var row = (&lines - height) / 2
  var col = (&columns - total_width) / 2

  state.name_input = popup_create('Note Name: ', {
    line: row - 2,
    col: col,
    minwidth: total_width,
    minheight: 1,
    border: [],
    borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    filter: function('NameInputFilter'),
    mapping: false,
    zindex: 200,
  })

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
enddef

def Close()
  if state.name_input != -1
    popup_close(state.name_input)
  endif
  if state.menu != -1
    popup_close(state.menu)
  endif
  if state.preview != -1
    popup_close(state.preview)
  endif
enddef

def Update()
  RenderNameInput()
  RenderTemplates()
  RenderPreview()
enddef

def RenderNameInput()
  popup_settext(state.name_input, 'Note Name: ' .. state.note_name)
enddef

def RenderTemplates()
  var lines: list<string> = []

  for i in range(len(state.templates))
    var tmpl = state.templates[i]
    if i == state.template_index
      add(lines, '> ' .. tmpl)
    else
      add(lines, '  ' .. tmpl)
    endif
  endfor

  if empty(lines)
    lines = ['(no templates)']
  endif

  popup_settext(state.menu, lines)

  win_execute(state.menu, 'call cursor(' .. (state.template_index + 1) .. ', 1)')
enddef

def RenderPreview()
  var tmpl = state.templates[state.template_index]
  var title = empty(state.note_name) ? 'New Note' : state.note_name

  var content = templates.GetTemplatePreview(tmpl, title)

  popup_settext(state.preview, content)
enddef

def Confirm()
  var name = state.note_name
  var tmpl = state.templates[state.template_index]

  Close()

  if !empty(name)
    OnSelectCallback(name, tmpl)
  endif
enddef

def NameInputFilter(id: number, key: string): number
  if key == "\<Esc>"
    Close()
    return 1
  endif

  if key == "\<CR>"
    Confirm()
    return 1
  endif

  if key == "\<Tab>" || key == "\<Down>" || key == "\<C-j>"
    if state.template_index < len(state.templates) - 1
      state.template_index += 1
      Update()
    endif
    return 1
  endif

  if key == "\<S-Tab>" || key == "\<Up>" || key == "\<C-k>"
    if state.template_index > 0
      state.template_index -= 1
      Update()
    endif
    return 1
  endif

  if key == "\<BS>"
    if strlen(state.note_name) > 0
      state.note_name = strcharpart(state.note_name, 0, strchars(state.note_name) - 1)
      Update()
    endif
    return 1
  endif

  if key == "\<C-w>"
    state.note_name = ''
    Update()
    return 1
  endif

  if strlen(key) == 1 && char2nr(key) >= 32
    state.note_name ..= key
    Update()
    return 1
  endif

  return 1
enddef

defcompile
