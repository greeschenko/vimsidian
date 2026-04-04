vim9script

import autoload "core/vault.vim" as vault

var explorer_buf = -1
var explorer_win = -1

# Visible line -> node
var line_to_node: dict<any> = {}

# Full tree state
var nodes_by_path: dict<any> = {}
var root_nodes: list<string> = []

var clipboard_node: dict<any> = {}
var clipboard_mode = ''

# Toggle the explorer window
export def ToggleExplorer()
    if explorer_win != -1 && win_gotoid(explorer_win)
        close
        explorer_win = -1
        explorer_buf = -1
        return
    endif

    execute 'topleft vertical :30new'

    explorer_win = win_getid()
    explorer_buf = bufnr()

    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nowrap
    setlocal nonumber
    setlocal norelativenumber
    setlocal signcolumn=no
    setlocal foldcolumn=0
    setlocal winfixwidth
    setlocal nobuflisted
    setlocal modifiable
    setlocal filetype=vimsidian-explorer

    SetupMappings()
    Render()
enddef

# Public render entrypoint
export def Render()
    BuildTree()
    RenderFromTree()
enddef

# Rebuild full tree from filesystem
export def BuildTree()
    nodes_by_path = {}
    root_nodes = []

    var vault_path = vault.GetVaultPath()

    if vault_path == ''
        return
    endif

    var root_path = vault_path .. '/data'

    if !isdirectory(root_path)
        return
    endif

    BuildDirectoryTree(root_path, '', 0)
enddef

# Recursive tree builder
# parent_path is empty only for top-level nodes
# level starts at 0

def BuildDirectoryTree(path: string, parent_path: string, level: number)
    var items = sort(readdir(path))
    var dirs: list<string> = []
    var files: list<string> = []

    for item in items
        if item == '.git'
            continue
        endif

        var full_path = path .. '/' .. item

        if isdirectory(full_path)
            add(dirs, item)
        else
            add(files, item)
        endif
    endfor

    # Directories first
    for dir in dirs
        var full_path = path .. '/' .. dir

        nodes_by_path[full_path] = {
            path: full_path,
            name: dir,
            type: 'dir',
            parent: parent_path,
            level: level,
            opened: v:false,
            children: []
        }

        if parent_path == ''
            add(root_nodes, full_path)
        else
            add(nodes_by_path[parent_path].children, full_path)
        endif

        BuildDirectoryTree(full_path, full_path, level + 1)
    endfor

    # Files after directories
    for file in files
        var full_path = path .. '/' .. file

        nodes_by_path[full_path] = {
            path: full_path,
            name: file,
            type: 'file',
            parent: parent_path,
            level: level,
            children: []
        }

        if parent_path == ''
            add(root_nodes, full_path)
        else
            add(nodes_by_path[parent_path].children, full_path)
        endif
    endfor
enddef

# Render only visible nodes from tree state
export def RenderFromTree()
    if explorer_buf == -1
        return
    endif

    var current_line = line('.')
    var current_path = ''

    if has_key(line_to_node, current_line)
        current_path = line_to_node[current_line].path
    endif

    var lines: list<string> = []
    line_to_node = {}

    var visible_nodes = GetVisibleNodes()

    for idx in range(len(visible_nodes))
        var node = visible_nodes[idx]
        var indent = repeat('  ', node.level)
        var prefix = ''

        if node.type == 'dir'
            prefix = node.opened ? '▾ ' : '▸ '
        else
            prefix = '  '
        endif

        add(lines, indent .. prefix .. node.name)
        line_to_node[idx + 1] = node
    endfor

    if empty(lines)
        lines = ['Empty vault']
    endif

    setlocal modifiable
    deletebufline(explorer_buf, 1, '$')
    setline(1, lines)
    setlocal nomodifiable

    var restore_line = 1

    if current_path != ''
        for [line_num, node] in items(line_to_node)
            if node.path == current_path
                restore_line = str2nr(line_num)
                break
            endif
        endfor
    endif

    call cursor(restore_line, 1)
enddef

# Return visible nodes in correct tree order

def GetVisibleNodes(): list<dict<any>>
    var result: list<dict<any>> = []

    for root_path in root_nodes
        AddVisibleNodeRecursive(root_path, result)
    endfor

    return result
enddef

# Recursively append visible nodes

def AddVisibleNodeRecursive(path: string, result: list<dict<any>>)
    if !has_key(nodes_by_path, path)
        return
    endif

    var node = nodes_by_path[path]

    add(result, node)

    if node.type != 'dir' || !get(node, 'opened', v:false)
        return
    endif

    for child_path in node.children
        AddVisibleNodeRecursive(child_path, result)
    endfor
enddef

# Set key mappings for the explorer buffer

def SetupMappings()
    nnoremap <silent><buffer> <CR> <ScriptCmd>OpenNode()<CR>
    nnoremap <silent><buffer> o <ScriptCmd>OpenNode()<CR>
    nnoremap <silent><buffer> <C-d> <ScriptCmd>DeleteNode()<CR>
    nnoremap <silent><buffer> <C-y> <ScriptCmd>CopyNode()<CR>
    nnoremap <silent><buffer> <C-p> <ScriptCmd>PasteNode()<CR>
    nnoremap <silent><buffer> <C-m> <ScriptCmd>MoveNode()<CR>
    nnoremap <silent><buffer> r <ScriptCmd>Render()<CR>
    nnoremap <silent><buffer> q <Cmd>close<CR>
enddef

# Open file or toggle directory

def OpenNode()
    var line_num = line('.')

    if !has_key(line_to_node, line_num)
        return
    endif

    var node = line_to_node[line_num]

    if node.type == 'file'
        OpenFile(node.path)
        return
    endif

    node.opened = !get(node, 'opened', v:false)
    RenderFromTree()
enddef

# Open file in another window

def OpenFile(path: string)
    var target_win = -1

    for winid in range(1, winnr('$'))
        execute ':' .. winid .. 'wincmd w'

        if win_getid() != explorer_win
            target_win = win_getid()
            break
        endif
    endfor

    if target_win == -1
        execute 'wincmd p'

        if win_getid() == explorer_win
            execute 'vnew'
        endif
    else
        call win_gotoid(target_win)
    endif

    execute 'edit ' .. fnameescape(path)
enddef

# Delete node and rebuild tree

def DeleteNode()
    var line_num = line('.')

    if !has_key(line_to_node, line_num)
        return
    endif

    var node = line_to_node[line_num]
    var next_line = line_num

    if node.type == 'dir'
        delete(node.path, 'rf')
    else
        delete(node.path)
    endif

    RemoveNodeFromTree(node.path)
    RenderFromTree()

    var max_line = line('$')
    if next_line > max_line
        next_line = max_line
    endif

    if next_line < 1
        next_line = 1
    endif

    call cursor(next_line, 1)
enddef

# Remove node recursively from in-memory tree

def RemoveNodeFromTree(path: string)
    if !has_key(nodes_by_path, path)
        return
    endif

    var node = nodes_by_path[path]

    for child_path in copy(node.children)
        RemoveNodeFromTree(child_path)
    endfor

    if node.parent != '' && has_key(nodes_by_path, node.parent)
        var parent_children = nodes_by_path[node.parent].children
        var idx = index(parent_children, path)

        if idx != -1
            remove(parent_children, idx)
        endif
    else
        var root_idx = index(root_nodes, path)

        if root_idx != -1
            remove(root_nodes, root_idx)
        endif
    endif

    remove(nodes_by_path, path)
enddef

# Copy selected node

def CopyNode()
    var line_num = line('.')

    if !has_key(line_to_node, line_num)
        return
    endif

    clipboard_node = copy(line_to_node[line_num])
    clipboard_mode = 'copy'
enddef

# Move selected node

def MoveNode()
    var line_num = line('.')

    if !has_key(line_to_node, line_num)
        return
    endif

    clipboard_node = copy(line_to_node[line_num])
    clipboard_mode = 'move'
enddef

# Paste copied or moved node

def PasteNode()
    var line_num = line('.')

    if empty(clipboard_node)
        return
    endif

    if !has_key(line_to_node, line_num)
        return
    endif

    var target = line_to_node[line_num]

    var target_dir = target.path
    if target.type == 'file'
        target_dir = fnamemodify(target.path, ':h')
    endif

    var source_path = clipboard_node.path
    var source_name = fnamemodify(source_path, ':t')
    var destination_path = target_dir .. '/' .. source_name

    if source_path == destination_path
        return
    endif

    if clipboard_mode == 'copy'
        if clipboard_node.type == 'dir'
            system('cp -R ' .. shellescape(source_path) .. ' ' .. shellescape(destination_path))
        else
            writefile(readfile(source_path, 'b'), destination_path, 'b')
        endif

        AddNodeToTree(destination_path, target_dir)
    elseif clipboard_mode == 'move'
        rename(source_path, destination_path)

        UpdateNodePathRecursive(source_path, destination_path)

        clipboard_node = {}
        clipboard_mode = ''
    endif

    RenderFromTree()
enddef

# Add copied file or directory into in-memory tree

def AddNodeToTree(path: string, parent_dir: string)
    var name = fnamemodify(path, ':t')
    var is_dir = isdirectory(path)
    var level = 0

    if has_key(nodes_by_path, parent_dir)
        level = nodes_by_path[parent_dir].level + 1
    endif

    nodes_by_path[path] = {
        path: path,
        name: name,
        type: is_dir ? 'dir' : 'file',
        parent: parent_dir,
        level: level,
        opened: v:false,
        children: []
    }

    if has_key(nodes_by_path, parent_dir)
        add(nodes_by_path[parent_dir].children, path)
        nodes_by_path[parent_dir].opened = v:true
    else
        add(root_nodes, path)
    endif

    if is_dir
        BuildCopiedChildren(path)
    endif
enddef

# Build copied directory subtree recursively

def BuildCopiedChildren(parent_path: string)
    var items = sort(readdir(parent_path))

    for item in items
        if item == '.git'
            continue
        endif

        var child_path = parent_path .. '/' .. item
        AddNodeToTree(child_path, parent_path)
    endfor
enddef

def UpdateNodePathRecursive(old_path: string, new_path: string)
    if !has_key(nodes_by_path, old_path)
        return
    endif

    var node = nodes_by_path[old_path]
    var child_paths = copy(node.children)
    var old_parent = node.parent
    var new_parent = fnamemodify(new_path, ':h')

    remove(nodes_by_path, old_path)

    node.path = new_path
    node.name = fnamemodify(new_path, ':t')
    node.parent = has_key(nodes_by_path, new_parent) ? new_parent : ''

    # important: recalculate nesting level
    if node.parent != '' && has_key(nodes_by_path, node.parent)
        node.level = nodes_by_path[node.parent].level + 1
    else
        node.level = 0
    endif

    nodes_by_path[new_path] = node

    if old_parent != ''
        if has_key(nodes_by_path, old_parent)
            var old_children = nodes_by_path[old_parent].children
            var old_idx = index(old_children, old_path)

            if old_idx != -1
                remove(old_children, old_idx)
            endif
        endif
    else
        var root_idx = index(root_nodes, old_path)

        if root_idx != -1
            remove(root_nodes, root_idx)
        endif
    endif

    if node.parent != ''
        if has_key(nodes_by_path, node.parent)
            add(nodes_by_path[node.parent].children, new_path)
        endif
    else
        add(root_nodes, new_path)
    endif

    var new_children: list<string> = []

    for child_path in child_paths
        var child_name = fnamemodify(child_path, ':t')
        var new_child_path = new_path .. '/' .. child_name

        UpdateNodePathRecursive(child_path, new_child_path)
        add(new_children, new_child_path)
    endfor

    nodes_by_path[new_path].children = new_children
enddef
