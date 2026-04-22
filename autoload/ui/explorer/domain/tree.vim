vim9script

import autoload "core/vault.vim" as vault
import autoload "ui/explorer/domain/node.vim" as node

var nodes_by_path: dict<any> = {}
var root_nodes: list<string> = []

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

    BuildDirectoryRecursive(root_path, '', 0)
enddef

def BuildDirectoryRecursive(path: string, parent_path: string, level: number)
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

    for dir in dirs
        var full_path = path .. '/' .. dir
        var new_node = node.NewNode(full_path, dir, 'dir', parent_path, level)

        nodes_by_path[full_path] = new_node

        if parent_path == ''
            add(root_nodes, full_path)
        else
            var parent_node = nodes_by_path[parent_path]
            add(parent_node.children, full_path)
        endif

        BuildDirectoryRecursive(full_path, full_path, level + 1)
    endfor

    for file in files
        var full_path = path .. '/' .. file
        var new_node = node.NewNode(full_path, file, 'file', parent_path, level)

        nodes_by_path[full_path] = new_node

        if parent_path == ''
            add(root_nodes, full_path)
        else
            var parent_node = nodes_by_path[parent_path]
            add(parent_node.children, full_path)
        endif
    endfor
enddef

export def GetNode(path: string): dict<any>
    if has_key(nodes_by_path, path)
        return nodes_by_path[path]
    endif
    return {}
enddef

export def GetRootNodes(): list<string>
    return copy(root_nodes)
enddef

export def AddNode(path: string, parent_path: string)
    var name = fnamemodify(path, ':t')
    var is_dir = isdirectory(path)
    var level = 0

    if has_key(nodes_by_path, parent_path)
        level = nodes_by_path[parent_path].level + 1
    endif

    var new_node = node.NewNode(path, name, is_dir ? 'dir' : 'file', parent_path, level)
    nodes_by_path[path] = new_node

    if has_key(nodes_by_path, parent_path)
        add(nodes_by_path[parent_path].children, path)
        nodes_by_path[parent_path].opened = v:true
    else
        add(root_nodes, path)
    endif

    if is_dir
        BuildChildrenRecursive(path)
    endif
enddef

def BuildChildrenRecursive(parent_path: string)
    var items = sort(readdir(parent_path))

    for item in items
        if item == '.git'
            continue
        endif

        var child_path = parent_path .. '/' .. item
        AddNode(child_path, parent_path)
    endfor
enddef

export def RemoveNode(path: string)
    if !has_key(nodes_by_path, path)
        return
    endif

    var node_to_remove = nodes_by_path[path]
    var node_children = copy(node_to_remove.children)

    for child_path in node_children
        RemoveNode(child_path)
    endfor

    var parent_path = node_to_remove.parent

    if parent_path != '' && has_key(nodes_by_path, parent_path)
        var parent_children = nodes_by_path[parent_path].children
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

export def UpdateNodePath(old_path: string, new_path: string)
    if !has_key(nodes_by_path, old_path)
        return
    endif

    var nd = nodes_by_path[old_path]
    var child_paths = copy(nd.children)
    var old_parent = nd.parent
    var new_parent = fnamemodify(new_path, ':h')

    remove(nodes_by_path, old_path)

    nd.path = new_path
    nd.name = fnamemodify(new_path, ':t')
    nd.parent = has_key(nodes_by_path, new_parent) ? new_parent : ''

    if nd.parent != '' && has_key(nodes_by_path, nd.parent)
        nd.level = nodes_by_path[nd.parent].level + 1
    else
        nd.level = 0
    endif

    nodes_by_path[new_path] = nd

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

    if nd.parent != ''
        if has_key(nodes_by_path, nd.parent)
            add(nodes_by_path[nd.parent].children, new_path)
        endif
    else
        add(root_nodes, new_path)
    endif

    var new_children: list<string> = []

    for child_path in child_paths
        var child_name = fnamemodify(child_path, ':t')
        var new_child_path = new_path .. '/' .. child_name

        UpdateNodePath(child_path, new_child_path)
        add(new_children, new_child_path)
    endfor

    nodes_by_path[new_path].children = new_children
enddef

export def ListNodes(): dict<any>
    return copy(nodes_by_path)
enddef

export def ToggleNode(path: string)
    var nd = GetNode(path)

    if empty(nd)
        return
    endif

    if nd.type == 'dir'
        nd.opened = !get(nd, 'opened', v:false)
    endif
enddef

defcompile