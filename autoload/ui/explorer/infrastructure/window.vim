vim9script

var explorer_win = -1
var explorer_buf = -1
var line_to_node: dict<any> = {}

export def OpenWindow()
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
enddef

export def CloseWindow()
    if explorer_win != -1
        popup_close(explorer_win)
        explorer_win = -1
        explorer_buf = -1
    endif

    if explorer_buf != -1
        popup_close(explorer_buf)
        explorer_buf = -1
    endif
enddef

export def GetWindowId(): number
    return explorer_win
enddef

export def GetBufferId(): number
    return explorer_buf
enddef

export def SetLineNode(line: number, node: dict<any>)
    line_to_node[line] = node
enddef

export def GetLineNode(line: number): dict<any>
    if has_key(line_to_node, line)
        return line_to_node[line]
    endif
    return {}
enddef

export def GetAllLineNodes(): dict<any>
    return copy(line_to_node)
enddef

export def ClearLineNode()
    line_to_node = {}
enddef

export def GetCurrentLine(): number
    return line('.')
enddef

export def SetContent(lines: list<string>)
    setlocal modifiable
    deletebufline(explorer_buf, 1, '$')
    setline(1, lines)
    setlocal nomodifiable
enddef

defcompile