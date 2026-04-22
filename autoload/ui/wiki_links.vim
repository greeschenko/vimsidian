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
  var word = expand('<cword>')

  if empty(word)
    return ''
  endif

  if stridx(word, '[[') == 0
    var link = substitute(word, '^\[\[', '', '')
    link = substitute(link, '\]\]$', '', '')
    if !empty(link)
      return 'wiki:' .. link
    endif
  endif

  if stridx(word, '![') == 0
    var name = substitute(word, '^\!\[', '', '')
    var close = stridx(name, '](')
    if close > 0
      name = strpart(name, 0, close)
      return 'media:' .. name
    endif
  endif

  if word =~? '^http'
    return 'web:' .. word
  endif

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
