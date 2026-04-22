vim9script

import autoload 'core/notes.vim'
import autoload 'core/media.vim' as media
import autoload 'core/vault.vim' as vault

# ----------------------------
# Get link under cursor (wiki, media, or web)
# ----------------------------
def GetLinkUnderCursor(): string
  var line = getline('.')
  var coln = col('.')
  var start = coln - 1
  if start < 0
    start = 0
  endif

  var search_start = start - 50
  if search_start < 0
    search_start = 0
  endif

  var open = stridx(line, '[[', search_start)
  while open >= 0 && open < start
    var close = stridx(line, ']]', open + 2)
    if close >= 0 && start >= open + 2 && start <= close + 2
      return 'wiki:' .. strpart(line, open + 2, close - open - 2)
    endif
    open = stridx(line, '[[', open + 2)
  endwhile

  open = stridx(line, '![', search_start)
  while open >= 0 && open < start
    var close = stridx(line, '](', open + 2)
    var close2 = stridx(line, ')', close + 2)
    if close >= 0 && close2 >= 0 && start >= open + 2 && start <= close2 + 1
      var filename = strpart(line, open + 2, close - open - 2)
      return 'media:' .. filename
    endif
    open = stridx(line, '![', open + 2)
  endwhile

  open = stridx(line, 'http', search_start)
  while open >= 0 && open < start
    var rest = strpart(line, open)
    var close = stridx(rest, ' ')
    if close < 0
      close = strlen(rest)
    endif
    if start >= open && start <= open + close
      return 'web:' .. strpart(rest, 0, close)
    endif
    open = stridx(line, 'http', open + 4)
  endwhile

  return ''
enddef

# ----------------------------
# Follow wiki link (original)
# ----------------------------
export def FollowLink()
  var result = GetLinkUnderCursor()
  if empty(result)
    echoerr 'Vimsidian: no wiki link under cursor'
    return
  endif

  if stridx(result, 'wiki:') == 0
    var content = strpart(result, 5)
    notes.OpenOrCreateNote(content)
  endif
enddef

# ----------------------------
# Open link under cursor (universal)
# ----------------------------
export def OpenLink()
  var result = GetLinkUnderCursor()
  if empty(result)
    echoerr 'Vimsidian: no link under cursor'
    return
  endif

  var type = strpart(result, 0, 4)
  var content = strpart(result, 5)

  if type == 'wiki'
    execute 'vsplit ' .. fnameescape(notes.OpenOrCreateNote(content))
  elseif type == 'media'
    var path = vault.GetMediaPath() .. '/' .. content
    system('xdg-open ' .. fnameescape(path) .. ' &')
  elseif type == 'web'
    system('xdg-open ' .. fnameescape(content) .. ' &')
  endif
enddef

defcompile
