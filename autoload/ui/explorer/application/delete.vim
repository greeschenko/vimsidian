vim9script

import autoload "ui/explorer/domain/tree.vim" as tree
import autoload "ui/explorer/infrastructure/window.vim" as window
import autoload "ui/explorer/infrastructure/render.vim" as render

export def DeleteNode()
    var line_num = window.GetCurrentLine()
    var selected_node = window.GetLineNode(line_num)

    if empty(selected_node)
        return
    endif

    var path = selected_node.path
    var node_type = selected_node.type

    if node_type == 'dir'
        delete(path, 'rf')
    else
        delete(path)
    endif

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