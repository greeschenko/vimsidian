vim9script

# ----------------------------
# Helper: get visual selection text
# ----------------------------
export def GetSelectedText(): string
  normal! "zy
  var text = getreg('z')
  return text
enddef

# ----------------------------
# Helper: replace visual selection
# ----------------------------
export def ReplaceVisual(text: string)
  setreg('z', text)
  normal! gv"zp
enddef

# ----------------------------
# Toggle bold (visual)
# ----------------------------
export def ToggleBold()
  var text = GetSelectedText()

  if text =~ '^\*\*.*\*\*$'
    text = text[2 : -3]
  else
    text = '**' .. text .. '**'
  endif

  ReplaceVisual(text)
enddef

# ----------------------------
# Toggle italic (visual)
# ----------------------------
export def ToggleItalic()
  var text = GetSelectedText()

  if text =~ '^\*.*\*$'
    text = text[1 : -2]
  else
    text = '*' .. text .. '*'
  endif

  ReplaceVisual(text)
enddef

# ----------------------------
# Toggle inline code (visual)
# ----------------------------
export def ToggleCode()
  var text = GetSelectedText()

  if text =~ '^`.*`$'
    text = text[1 : -2]
  else
    text = '`' .. text .. '`'
  endif

  ReplaceVisual(text)
enddef

# ----------------------------
# Toggle code block (visual)
# ----------------------------
export def ToggleCodeBlock()
  var text = GetSelectedText()
  var lines = split(text, "\n")

  if len(lines) >= 2 && lines[0] =~ '^```' && lines[-1] =~ '^```$'
    lines = lines[1 : -2]
  else
    insert(lines, '```', 0)
    add(lines, '```')
  endif

  ReplaceVisual(join(lines, "\n"))
enddef

# ----------------------------
# Toggle quote (visual)
# ----------------------------
export def ToggleQuote()
  var text = GetSelectedText()
  var lines = split(text, "\n")

  for i in range(len(lines))
    if lines[i] =~ '^> '
      lines[i] = substitute(lines[i], '^> ', '', '')
    else
      lines[i] = '> ' .. lines[i]
    endif
  endfor

  ReplaceVisual(join(lines, "\n"))
enddef

# ----------------------------
# Toggle list (visual)
# ----------------------------
export def ToggleList()
  var text = GetSelectedText()
  var lines = split(text, "\n")

  for i in range(len(lines))
    if lines[i] =~ '^[-*] '
      lines[i] = substitute(lines[i], '^[-*] ', '', '')
    else
      lines[i] = '- ' .. lines[i]
    endif
  endfor

  ReplaceVisual(join(lines, "\n"))
enddef
