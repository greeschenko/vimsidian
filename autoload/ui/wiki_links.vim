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

  var wiki_start = match(line, '\[\[', 0)
  while wiki_start >= 0
    var wiki_end = match(line, '\]\]', wiki_start)
    if wiki_end < 0
      break
    endif
    if coln >= wiki_start + 1 && coln <= wiki_end + 2
      var link = strpart(line, wiki_start + 2, wiki_end - wiki_start - 2)
      if !empty(link)
        return 'wiki:' .. link
      endif
    endif
    wiki_start = match(line, '\[\[', wiki_end + 2)
  endwhile

  var md_link_start = match(line, '](', 0)
  while md_link_start >= 0
    var close_paren = match(line, ')', md_link_start + 2)
    if close_paren < 0
      break
    endif
    var link_text_start = md_link_start
    while link_text_start > 0 && line[link_text_start - 1] != '['
      link_text_start -= 1
    endwhile
    if coln >= link_text_start + 1 && coln <= close_paren + 1
      var url = strpart(line, md_link_start + 2, close_paren - md_link_start - 2)
      if !empty(url)
        var img_char = line[md_link_start - 2]
        if img_char == '!'
          return 'media:' .. url
        elseif url =~? '^http'
          return 'web:' .. url
        else
          return 'media:' .. url
        endif
      endif
    endif
    md_link_start = match(line, '](', close_paren + 1)
  endwhile

  return ''
enddef

# ----------------------------
# Follow link (wiki, media, or web)
# ----------------------------
export def FollowLink()
  var result = GetLinkUnderCursor()
  if empty(result)
    echoerr 'Vimsidian: no link under cursor'
    return
  endif

  if result =~ '^wiki:'
    var content = strpart(result, 5)
    notes.OpenOrCreateNote(content)
  elseif result =~ '^media:'
    var content = strpart(result, 6)
    if content =~? '^http'
      system('xdg-open ' .. fnameescape(content) .. ' &')
    else
      var path = vault.GetMediaPath() .. '/' .. content
      system('xdg-open ' .. fnameescape(path) .. ' &')
    endif
  elseif result =~ '^web:'
    var content = strpart(result, 4)
    system('xdg-open ' .. fnameescape(content) .. ' &')
  endif
enddef

defcompile
