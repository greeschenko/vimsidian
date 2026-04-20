vim9script

import autoload "core/tags.vim" as tags

export def TagComplete(findstart: number, base: string): any
  if findstart
    return FindTagStart()
  endif

  tags.ScanAllNotesForTags()
  var suggestions = tags.GetTagSuggestions(base)

  var result: list<dict<any>> = []
  for t in suggestions
    add(result, {
      word: t,
      menu: 'tag',
    })
  endfor

  return result
enddef

def FindTagStart(): number
  var line = getline('.')
  var coln = col('.')
  var pos = coln - 1

  while pos >= 0
    if pos > 0 && line[pos - 1] == '#'
      return pos
    endif
    if pos > 0 && line[pos - 1] =~ '\s'
      return -1
    endif
    pos -= 1
  endwhile

  return -1
enddef

def TagCompleteAsync()
  var line = getline('.')
  var coln = col('.')
  var pos = coln - 1

  while pos > 0
    if line[pos - 1] == '#'
      break
    endif
    if line[pos - 1] =~ '\s'
      return
    endif
    pos -= 1
  endwhile

  if pos > 0 && line[pos - 1] == '#'
    var search_start = pos
    var search_end = coln - 1
    var current = strpart(line, search_start, search_end - search_start)

    var suggestions = tags.GetTagSuggestions(current)

    if empty(suggestions)
      return
    endif

    var result: list<dict<any>> = []
    for t in suggestions
      add(result, {
        word: '#' .. t .. ' ',
        menu: 'tag',
      })
    endfor

    if !empty(result)
      complete#start(coln, result)
    endif
  endif
enddef

defcompile