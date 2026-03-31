vim9script

# ----------------------------
# Continue list on Enter
# ----------------------------
export def ContinueList(): string
  var line = getline('.')

  if line =~ '^\s*[-*]\s\+'
    var marker = matchstr(line, '[-*]')
    var checkbox = matchstr(line, '\v\[\s\]|\[x\]|\[-\]')

    if line =~ '^\s*[-*]\s*\(\[[ x-]\]\s*\)\?$'
      return "\<CR>"
    endif

    var new_line = marker .. ' '
    if checkbox != ''
      new_line ..= checkbox .. ' '
    endif

    return "\<CR>" .. new_line
  endif

  if line =~ '^\s*\d\+\.\s\+'
    var num = str2nr(matchstr(line, '\d\+'))
    var next = num + 1

    if line =~ '^\s*\d\+\.\s*$'
      return "\<CR>"
    endif

    var new_line = next .. '. '

    var checkbox = matchstr(line, '\v\[\s\]|\[x\]|\[-\]')
    if checkbox != ''
      new_line ..= checkbox .. ' '
    endif

    return "\<CR>" .. new_line
  endif

  return "\<CR>"
enddef
