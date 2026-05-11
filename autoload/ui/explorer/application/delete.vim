vim9script

import autoload "core/vault.vim" as vault
import autoload "ui/explorer/domain/tree.vim" as tree
import autoload "ui/explorer/infrastructure/window.vim" as window
import autoload "ui/explorer/infrastructure/render.vim" as render

def MoveToBin(path: string)
  var vault_path = vault.GetVaultPath()
  vault.EnsureBinDir()

  var date_dir = strftime('%Y-%m-%d')
  var rel_path = path[len(vault_path) : ]
  var dest = vault.GetBinPath() .. '/' .. date_dir .. rel_path

  var parent = fnamemodify(dest, ':h')
  if !isdirectory(parent)
    mkdir(parent, 'p')
  endif

  if isdirectory(dest) || filereadable(dest)
    var counter = 1
    var suffix = ''
    while isdirectory(dest .. suffix) || filereadable(dest .. suffix)
      suffix = '_' .. counter
      counter += 1
    endwhile
    dest ..= suffix
  endif

  rename(path, dest)
enddef

export def DeleteNode()
    var line_num = window.GetCurrentLine()
    var selected_node = window.GetLineNode(line_num)

    if empty(selected_node)
        return
    endif

    var path = selected_node.path

    MoveToBin(path)

    tree.RemoveNode(path)

    render.RenderFromTree()

    var max_line = line('$')
    var next_line = line_num

    if next_line > max_line
        next_line = max_line
    endif

    if next_line < 1
        next_line = 1
    endif

    call cursor(next_line, 1)
enddef

defcompile