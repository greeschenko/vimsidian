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
  var pos = coln - 1

  if pos < 0
    pos = 0
  endif

  var rest = line
  var i = 0
  while i < strlen(rest)
    var p = stridx(rest, '[[')
    if p >= 0 && p <= pos && pos <= p + 3
      var q = stridx(rest, ']]', p + 2)
      if q >= 0
        return 'wiki:' .. strpart(rest, p + 2, q - p - 2)
      endif
    endif

    p = stridx(rest, '![')
    if p >= 0 && p <= pos
      var q = stridx(rest, '](', p + 2)
      var q2 = stridx(rest, ')', q + 2)
      if q >= 0 && q2 >= 0 && pos >= p + 2 && pos <= q2 + 1
        return 'media:' .. strpart(rest, p + 2, q - p - 2)
      endif
    endif

    p = stridx(rest, 'http')
    if p >= 0 && p <= pos
      var sp = stridx(rest, ' ', p)
      if sp < 0
        sp = strlen(rest)
      endif
      if pos <= sp
        return 'web:' .. strpart(rest, p, sp - p)
      endif
    endif

    if i >= strlen(rest) - 1
      break
    endif
    i += 1
    rest = strpart(rest, 1)
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
