vim9script

export def NewNode(path: string, name: string, node_type: string, parent: string, level: number): dict<any>
    return {
        path: path,
        name: name,
        type: node_type,
        parent: parent,
        level: level,
        opened: v:false,
        children: [],
    }
enddef

export def IsDirectory(node: dict<any>): bool
    return get(node, 'type', '') == 'dir'
enddef

export def IsFile(node: dict<any>): bool
    return get(node, 'type', '') == 'file'
enddef

export def GetNodeName(node: dict<any>): string
    return get(node, 'name', '')
enddef

export def GetNodePath(node: dict<any>): string
    return get(node, 'path', '')
enddef

export def GetNodeLevel(node: dict<any>): number
    return get(node, 'level', 0)
enddef

export def IsOpened(node: dict<any>): bool
    return get(node, 'opened', v:false)
enddef

export def GetChildren(node: dict<any>): list<string>
    return get(node, 'children', [])
enddef

export def GetParent(node: dict<any>): string
    return get(node, 'parent', '')
enddef