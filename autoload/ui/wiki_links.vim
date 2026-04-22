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

  var open = stridx(line, '[[', coln - 10)
  if open >= 0 && coln >= open + 1
    var close = stridx(line, ']]', open + 2)
    if close >= 0 && coln <= close + 2
      return 'wiki:' .. strpart(line, open + 2, close - open - 2)
    endif
  endif

  open = stridx(line, '![', coln - 10)
  if open >= 0 && coln >= open + 1
    var close = stridx(line, '](', open + 2)
    var close2 = stridx(line, ')', close + 2)
    if close >= 0 && close2 >= 0 && coln <= close2 + 1
      var filename = strpart(line, open + 2, close - open - 2)
      return 'media:' .. filename
    endif
  endif

  open = stridx(line, 'http', coln - 20)
  if open >= 0 && coln >= open + 1
    var rest = strpart(line, open)
    var close = stridx(rest, ' ')
    if close < 0
      close = strlen(rest)
    endif
    return 'web:' .. strpart(rest, 0, close)
  endif

  return ''
enddef

# ----------------------------
# Follow wiki link (original)
# ----------------------------
export def FollowLink()
  var link = trim(GetLinkUnderCursor())
  if empty(link)
    echoerr 'Vimsidian: no wiki link under cursor'
    return
  endif

  notes.OpenOrCreateNote(link)
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
