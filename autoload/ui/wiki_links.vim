vim9script

import autoload 'core/notes.vim'

# ----------------------------
# Wiki links UI domain
# ----------------------------
def GetLinkUnderCursor(): string
  var line = getline('.')
  var coln = col('.')
  var pos = 0

  while true
    var open = stridx(line, '[[', pos)
    if open < 0 | break | endif

    var close = stridx(line, ']]', open + 2)
    if close < 0 | break | endif

    if coln >= open + 1 && coln <= close + 2
      return strpart(line, open + 2, close - open - 2)
    endif

    pos = close + 2
  endwhile

  return ''
enddef

export def FollowLink()
  var link = trim(GetLinkUnderCursor())
  if empty(link)
    echoerr 'Vimsidian: no wiki link under cursor'
    return
  endif

  notes.OpenOrCreateNote(link)
enddef

defcompile
