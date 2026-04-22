vim9script

var clipboard_node: dict<any> = {}
var clipboard_mode = ''

export def Copy(node: dict<any>)
    clipboard_node = copy(node)
    clipboard_mode = 'copy'
enddef

export def Move(node: dict<any>)
    clipboard_node = copy(node)
    clipboard_mode = 'move'
enddef

export def IsEmpty(): bool
    return empty(clipboard_node)
enddef

export def GetMode(): string
    return clipboard_mode
enddef

export def GetNode(): dict<any>
    return clipboard_node
enddef

export def Clear()
    clipboard_node = {}
    clipboard_mode = ''
enddef

defcompile