vim9script

import autoload "core/vault.vim" as vault
import autoload "ui/explorer/domain/tree.vim" as tree
import autoload "ui/explorer/domain/node.vim" as node
import autoload "ui/explorer/infrastructure/window.vim" as window
import autoload "ui/explorer/infrastructure/render.vim" as render
import autoload "ui/explorer/application/open.vim" as open_app
import autoload "ui/explorer/application/delete.vim" as delete_app
import autoload "ui/explorer/application/copy_move.vim" as copy_move_app

export def ToggleExplorer()
    if window.GetWindowId() != -1 && win_gotoid(window.GetWindowId())
        close
        window.CloseWindow()
        return
    endif

    window.OpenWindow()
    SetupMappings()

    tree.BuildTree()
    render.Render()
enddef

export def Render()
    tree.BuildTree()
    render.Render()
enddef

def SetupMappings()
    nnoremap <silent><buffer> <CR> <ScriptCmd>open_app.OpenNode()<CR>
    nnoremap <silent><buffer> o <ScriptCmd>open_app.OpenNode()<CR>
    nnoremap <silent><buffer> <C-d> <ScriptCmd>delete_app.DeleteNode()<CR>
    nnoremap <silent><buffer> <C-y> <ScriptCmd>copy_move_app.CopyNode()<CR>
    nnoremap <silent><buffer> <C-p> <ScriptCmd>copy_move_app.PasteNode()<CR>
    nnoremap <silent><buffer> <C-m> <ScriptCmd>copy_move_app.MoveNode()<CR>
    nnoremap <silent><buffer> r <ScriptCmd>render.Render()<CR>
    nnoremap <silent><buffer> q <Cmd>close<CR>
enddef

defcompile