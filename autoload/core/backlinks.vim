vim9script

import autoload 'core/vault.vim'
import autoload 'core/notes.vim'

# ----------------------------
# Backlinks domain
# ----------------------------
export def Backlinks()
  var path = expand('%:p')
  if empty(path)
    echoerr 'Vimsidian: no note selected'
    return
  endif

  var id = notes.GetNoteLinkId(path)
  echom 'Searching: ' .. id

  var pattern = '\V[[' .. id .. ']]'

  var files = globpath(vault.GetDataPath(), '**/*.md', 0, 1)
  var files_escaped = map(copy(files), (_, v) => fnameescape(v))
  var files_str = join(files_escaped, ' ')

  try
    execute 'silent! vimgrep /' .. pattern .. '/j ' .. files_str

    if len(getqflist()) == 0
      echo 'No backlinks for: ' .. id
      return
    endif

    copen
  catch
    echo 'No backlinks for: ' .. id
  endtry
enddef

defcompile
