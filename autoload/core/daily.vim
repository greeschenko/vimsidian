vim9script

import autoload 'core/vault.vim'

# ----------------------------
# Daily notes domain
# ----------------------------
export def TodayNote()
  var vault_path = vault.GetVaultPath()
  var today = strftime('%Y-%m-%d')
  var year = strftime('%Y')

  var dir = vault_path .. '/data/daily/' .. year
  if !isdirectory(dir)
    mkdir(dir, 'p')
  endif

  var path = dir .. '/' .. today .. '.md'
  if !filereadable(path)
    writefile(['# ' .. today, ''], path)
  endif

  execute 'edit ' .. fnameescape(path)
enddef

defcompile
