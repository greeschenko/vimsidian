vim9script

# ----------------------------
# Toggle checkbox (single line)
# ----------------------------
export def ToggleCheckbox()
  var line = getline('.')
  setline('.', ToggleLine(line))
enddef

# ----------------------------
# Toggle checkbox (visual mode)
# ----------------------------
export def ToggleCheckboxVisual()
  var start = line("'<")
  var end = line("'>")

  for lnum in range(start, end)
    var line = getline(lnum)
    setline(lnum, ToggleLine(line))
  endfor
enddef

# ----------------------------
# Convert line to checkbox
# ----------------------------
export def MakeCheckbox()
  var line = getline('.')

  if line =~ '^\s*[-*] '
    setline('.', substitute(line, '^\(\s*[-*]\) ', '\1 [ ] ', ''))
  else
    setline('.', '- [ ] ' .. line)
  endif
enddef

# ----------------------------
# Internal: toggle logic
# ----------------------------
def ToggleLine(line: string): string
  if line =~ '\v\[\s\]'
    return substitute(line, '\[\s\]', '[x]', '')
  elseif line =~ '\v\[x\]'
    return substitute(line, '\[x\]', '[ ]', '')
  else
    return line
  endif
enddef
