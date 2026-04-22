vim9script

import autoload "ui/explorer/domain/tree.vim" as tree
import autoload "ui/explorer/domain/node.vim" as node
import autoload "ui/explorer/infrastructure/window.vim" as window

var current_path = ''

export def Render()
    RenderFromTree()
enddef

export def RenderFromTree()
    var buf = window.GetBufferId()

    if buf == -1
        return
    endif

    var current_line = window.GetCurrentLine()
    var selected_node = window.GetLineNode(current_line)

    if !empty(selected_node)
        current_path = node.GetNodePath(selected_node)
    endif

    window.ClearLineNode()

    var visible_nodes = GetVisibleNodes()

    var lines: list<string> = []

    for i in range(len(visible_nodes))
        var nd = visible_nodes[i]
        var indent = repeat('  ', node.GetNodeLevel(nd))
        var prefix = ''

        if node.IsDirectory(nd)
            prefix = node.IsOpened(nd) ? '▾ ' : '▸ '
        else
            prefix = '  '
        endif

        add(lines, indent .. prefix .. node.GetNodeName(nd))
        window.SetLineNode(i + 1, nd)
    endfor

    if empty(lines)
        lines = ['Empty vault']
    endif

    window.SetContent(lines)

    var restore_line = 1

    if current_path != ''
        var all_nodes = window.GetAllLineNodes()
        for [line_num, nd] in items(all_nodes)
            if node.GetNodePath(nd) == current_path
                restore_line = str2nr(line_num)
                break
            endif
        endfor
    endif

    call cursor(restore_line, 1)
enddef

def GetVisibleNodes(): list<dict<any>>
    var result: list<dict<any>> = []

    for root_path in tree.GetRootNodes()
        AddVisibleRecursive(root_path, result)
    endfor

    return result
enddef

def AddVisibleRecursive(path: string, result: list<dict<any>>)
    var nd = tree.GetNode(path)

    if empty(nd)
        return
    endif

    add(result, nd)

    if !node.IsDirectory(nd) || !node.IsOpened(nd)
        return
    endif

    for child_path in node.GetChildren(nd)
        AddVisibleRecursive(child_path, result)
    endfor
enddef

defcompile