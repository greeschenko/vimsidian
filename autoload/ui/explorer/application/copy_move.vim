vim9script

import autoload "ui/explorer/domain/tree.vim" as tree
import autoload "ui/explorer/infrastructure/window.vim" as window
import autoload "ui/explorer/infrastructure/clipboard.vim" as clipboard
import autoload "ui/explorer/infrastructure/render.vim" as render

export def CopyNode()
    var line_num = window.GetCurrentLine()
    var selected_node = window.GetLineNode(line_num)

    if empty(selected_node)
        return
    endif

    clipboard.Copy(selected_node)
enddef

export def MoveNode()
    var line_num = window.GetCurrentLine()
    var selected_node = window.GetLineNode(line_num)

    if empty(selected_node)
        return
    endif

    clipboard.Move(selected_node)
enddef

export def PasteNode()
    var line_num = window.GetCurrentLine()
    var selected_node = window.GetLineNode(line_num)

    if clipboard.IsEmpty()
        return
    endif

    if empty(selected_node)
        return
    endif

    var node_to_paste = clipboard.GetNode()
    var target_dir = selected_node.path

    if selected_node.type == 'file'
        target_dir = fnamemodify(selected_node.path, ':h')
    endif

    var source_path = node_to_paste.path
    var source_name = fnamemodify(source_path, ':t')
    var destination_path = target_dir .. '/' .. source_name

    if source_path == destination_path
        return
    endif

    var mode = clipboard.GetMode()

    if mode == 'copy'
        if node_to_paste.type == 'dir'
            system('cp -R ' .. shellescape(source_path) .. ' ' .. shellescape(destination_path))
        else
            writefile(readfile(source_path, 'b'), destination_path, 'b')
        endif

        tree.AddNode(destination_path, target_dir)

    elseif mode == 'move'
        rename(source_path, destination_path)

        tree.UpdateNodePath(source_path, destination_path)

        clipboard.Clear()
    endif

    render.RenderFromTree()
enddef

defcompile