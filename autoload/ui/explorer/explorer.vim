vim9script

import autoload "core/vault.vim" as vault

var explorer_buf = -1
var explorer_win = -1
var line_to_node: dict<any> = {}
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

# Render the root vault directory
export def Render()
    var vault_path = vault.GetVaultPath()

    if vault_path == ''
        setline(1, ['No vault path configured'])
        return
    endif

    var lines: list<string> = []
    line_to_node = {}

    RenderDirectory(vault_path .. "/data", 0, lines)

    setlocal modifiable
    deletebufline(explorer_buf, 1, '$')
    setline(1, lines)
    setlocal nomodifiable
enddef

# Render a directory into the provided lines list
def RenderDirectory(path: string, level: number, lines: list<string>)
    var items = sort(readdir(path))
    var dirs: list<string> = []
    var files: list<string> = []

    # Separate directories and files
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

    var indent = repeat('  ', level)

    # Add directories first
    for dir in dirs
        var full_path = path .. '/' .. dir
        add(lines, indent .. '▸ ' .. dir)

        line_to_node[len(lines)] = {
            path: full_path,
            type: 'dir',
            opened: v:false,
            level: level
        }
    endfor

    # Add files after directories
    for file in files
        var full_path = path .. '/' .. file
        add(lines, indent .. ' ' .. file)

        line_to_node[len(lines)] = {
            path: full_path,
            type: 'file',
            level: level
        }
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
    nnoremap <silent><buffer> q <Cmd>close<CR>
enddef

# Open or toggle the node under cursor
def OpenNode()
    var line_num = line('.')

    if !has_key(line_to_node, line_num)
        return
    endif

    var node = line_to_node[line_num]

    # Open file directly
    if node.type == 'file'
        OpenFile(node.path)
        return
    endif

    setlocal modifiable

    if get(node, 'opened', v:false)
        CollapseDirectory(line_num, node)
    else
        ExpandDirectory(line_num, node)
    endif

    setlocal nomodifiable
enddef

# Open a file in the previous non-explorer window
def OpenFile(path: string)
    var current_win = win_getid()
    var target_win = -1

    # Find first non-explorer window
    for winid in range(1, winnr('$'))
        execute ":" .. winid .. 'wincmd w'

        if win_getid() != explorer_win
            target_win = win_getid()
            break
        endif
    endfor

    # If no other window exists, create a new one
    if target_win == -1
        execute 'wincmd p'
        if win_getid() == explorer_win
            execute 'vnew'
        endif
    else
        call win_gotoid(target_win)
    endif

    # Open file in target window
    execute 'edit ' .. fnameescape(path)
enddef

# Expand a directory under the given line
def ExpandDirectory(line_num: number, node: dict<any>)
    var dir_items = sort(readdir(node.path))
    var new_lines: list<string> = []
    var children: dict<any> = {}
    var indent = repeat('  ', node.level + 1)

    # Build child nodes
    for item in dir_items
        if item == '.git'
            continue
        endif

        var full_path = node.path .. '/' .. item
        var target_line = line_num + len(new_lines) + 1

        if isdirectory(full_path)
            add(new_lines, indent .. '▸ ' .. item)
            children[target_line] = {
                path: full_path,
                type: 'dir',
                opened: v:false,
                level: node.level + 1
            }
        else
            add(new_lines, indent .. ' ' .. item)
            children[target_line] = {
                path: full_path,
                type: 'file',
                level: node.level + 1
            }
        endif
    endfor

    # Mark directory as opened even if empty
    node.opened = v:true
    call setline(line_num, substitute(getline(line_num), '^\\s*▸', repeat('  ', node.level) .. '▾', ''))

    if empty(new_lines)
        return
    endif

    # Shift existing nodes down
    var shift = len(new_lines)
    var max_line = line('$')

    for current_line in reverse(range(line_num + 1, max_line))
        if has_key(line_to_node, current_line)
            line_to_node[current_line + shift] = line_to_node[current_line]
            call remove(line_to_node, current_line)
        endif
    endfor

    # Insert new lines into buffer
    call append(line_num, new_lines)

    # Add child nodes into line_to_node
    for [child_line, child_node] in items(children)
        line_to_node[str2nr(child_line)] = child_node
    endfor
enddef

# Collapse a directory under the given line
def CollapseDirectory(line_num: number, node: dict<any>)
    var start_line = line_num + 1
    var end_line = start_line

    # Find all visible child lines
    while end_line <= line('$')
        if !has_key(line_to_node, end_line)
            break
        endif

        var child = line_to_node[end_line]

        if child.level <= node.level
            break
        endif

        end_line += 1
    endwhile

    var delete_count = end_line - start_line

    # Nothing to collapse
    if delete_count <= 0
        node.opened = v:false
        call setline(line_num, substitute(getline(line_num), '^\\s*▾', repeat('  ', node.level) .. '▸', ''))
        return
    endif

    # Remove child nodes from line_to_node
    for current_line in range(start_line, end_line - 1)
        if has_key(line_to_node, current_line)
            call remove(line_to_node, current_line)
        endif
    endfor

    # Delete child lines from buffer
    call deletebufline(explorer_buf, start_line, end_line - 1)

    # Shift remaining nodes up
    var max_line = line('$') + delete_count

    for current_line in range(end_line, max_line)
        if has_key(line_to_node, current_line)
            line_to_node[current_line - delete_count] = line_to_node[current_line]
            call remove(line_to_node, current_line)
        endif
    endfor

    # Mark directory as closed
    node.opened = v:false
    call setline(line_num, substitute(getline(line_num), '^\\s*▾', repeat('  ', node.level) .. '▸', ''))
enddef

# Delete the selected file or directory
def DeleteNode()
    var line_num = line('.')

    if !has_key(line_to_node, line_num)
        return
    endif

    var node = line_to_node[line_num]

    if node.type == 'dir'
        delete(node.path, 'rf')
    else
        delete(node.path)
    endif

    Render()
enddef

# Copy the selected file or directory path
def CopyNode()
    var line_num = line('.')

    if !has_key(line_to_node, line_num)
        return
    endif

    clipboard_node = copy(line_to_node[line_num])
    clipboard_mode = 'copy'
enddef

# Mark the selected file or directory for moving
def MoveNode()
    var line_num = line('.')

    if !has_key(line_to_node, line_num)
        return
    endif

    clipboard_node = copy(line_to_node[line_num])
    clipboard_mode = 'move'
enddef

# Paste copied or moved node into selected directory
def PasteNode()
    var line_num = line('.')

    if empty(clipboard_node)
        return
    endif

    if !has_key(line_to_node, line_num)
        return
    endif

    var target = line_to_node[line_num]

    # If target is a file, use its parent directory
    var target_dir = target.path
    if target.type == 'file'
        target_dir = fnamemodify(target.path, ':h')
    endif

    var source_path = clipboard_node.path
    var source_name = fnamemodify(source_path, ':t')
    var destination_path = target_dir .. '/' .. source_name

    # Prevent copying onto itself
    if source_path == destination_path
        return
    endif

    if clipboard_mode == 'copy'
        if clipboard_node.type == 'dir'
            system('cp -R ' .. shellescape(source_path) .. ' ' .. shellescape(destination_path))
        else
            writefile(readfile(source_path, 'b'), destination_path, 'b')
        endif
    elseif clipboard_mode == 'move'
        rename(source_path, destination_path)
        clipboard_node = {}
        clipboard_mode = ''
    endif

    Render()
enddef
