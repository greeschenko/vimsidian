vim9script

import autoload "ui/explorer/domain/tree.vim" as tree
import autoload "ui/explorer/infrastructure/window.vim" as window
import autoload "ui/explorer/infrastructure/render.vim" as render

export def OpenNode()
    var line_num = window.GetCurrentLine()
    var selected_node = window.GetLineNode(line_num)

    if empty(selected_node)
        return
    endif

    if selected_node.type == 'file'
        OpenFile(selected_node.path)
        return
    endif

    tree.ToggleNode(selected_node.path)

    render.RenderFromTree()
enddef

def OpenFile(path: string)
    var win = window.GetWindowId()

    if win == -1
        return
    endif

    var target_win = -1

    for winid in range(1, winnr('$'))
        execute ':' .. winid .. 'wincmd w'

        if win_getid() != win
            target_win = win_getid()
            break
        endif
    endfor

    if target_win == -1
        execute 'wincmd p'

        if win_getid() == win
            execute 'vnew'
        endif
    else
        call win_gotoid(target_win)
    endif

    execute 'edit ' .. fnameescape(path)
enddef

defcompile