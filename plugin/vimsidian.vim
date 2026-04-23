vim9script

import autoload "vimsidian.vim" as vimsidian
import autoload "editor/markdown.vim" as md
import autoload "ui/explorer/explorer.vim" as explorer

# ----------------------------
# core setup
# ----------------------------

command! -nargs=* -complete=customlist,vimsidian.CompleteNoteNames VimsidianNew call vimsidian.OpenOrCreateNote(<q-args>)
command! -nargs=+ VimsidianOpen call vimsidian.OpenNote(<q-args>)
command! -nargs=0 VimsidianFollowLink call vimsidian.FollowLink()
command! VimsidianToday call vimsidian.TodayNote()
command! VimsidianBacklinks call vimsidian.Backlinks()
command! VimsidianPicker call vimsidian.VimsidianPicker()
command! VimsidianToggleExplorer call vimsidian.OpenVaultExplorer()
command! VimsidianReminders call vimsidian.ShowReminders()
command! VimsidianScanReminders call vimsidian.ScanReminders()
command! VimsidianScanTags call vimsidian.ScanTags()
command! VimsidianGraph call vimsidian.OpenGraphView()
command! VimsidianMedia call vimsidian.OpenMediaPicker()
command! VimsidianToggleGraph call vimsidian.ToggleGraphPanel()


import autoload "ui/graph.vim" as graph

nnoremap <leader>vv <ScriptCmd>VimsidianPicker<CR>
nnoremap <leader>vg <ScriptCmd>VimsidianToggleGraph<CR>
nnoremap <leader>vm <ScriptCmd>VimsidianMedia<CR>
nnoremap <leader>vn <ScriptCmd>VimsidianNew<CR>
nnoremap <leader>vf <ScriptCmd>VimsidianFollowLink<CR>
nnoremap <leader>vt <ScriptCmd>VimsidianToday<CR>
nnoremap <leader>vb <ScriptCmd>VimsidianBacklinks<CR>
nnoremap <leader>ve <Cmd>VimsidianToggleExplorer<CR>
nnoremap <leader>vr <Cmd>VimsidianReminders<CR>

# ----------------------------
# Editor setup
# ----------------------------

# checkbox
command! VimsidianToggleCheckbox call md.ToggleCheckbox()
command! -range VimsidianToggleCheckboxVisual call md.ToggleCheckboxVisual()
command! VimsidianMakeCheckbox call md.MakeCheckbox()

# list
command! VimsidianContinueList call md.ContinueList()

# visual formatting
command! -range VimsidianToggleBold call md.ToggleBold()
command! -range VimsidianToggleItalic call md.ToggleItalic()
command! -range VimsidianToggleCode call md.ToggleCode()
command! -range VimsidianToggleCodeBlock call md.ToggleCodeBlock()
command! -range VimsidianToggleQuote call md.ToggleQuote()
command! -range VimsidianToggleList call md.ToggleList()

augroup vimsidian_markdown 
    autocmd! 
    autocmd FileType markdown call SetupMarkdown()
augroup END 

def SetupMarkdown() 
    nnoremap <buffer> <C-x> <Cmd>VimsidianToggleCheckbox<CR> 
    vnoremap <buffer> <C-x> <Cmd>VimsidianToggleCheckboxVisual<CR> 
    nnoremap <buffer> <C-c> <Cmd>VimsidianMakeCheckbox<CR> 

    inoremap <buffer> <expr> <CR> md.ContinueList()

    vnoremap <buffer> <C-b> <Cmd>VimsidianToggleBold<CR> 
    vnoremap <buffer> <C-i> <Cmd>VimsidianToggleItalic<CR> 
    vnoremap <buffer> <C-c> <Cmd>VimsidianToggleCode<CR> 
    vnoremap <buffer> <C-C> <Cmd>VimsidianToggleCodeBlock<CR> 
    vnoremap <buffer> <C-q> <Cmd>VimsidianToggleQuote<CR> 
    vnoremap <buffer> <C-l> <Cmd>VimsidianToggleList<CR> 

    SetTagCompletion()
enddef

export def SetTagCompletion()
    setlocal completefunc=vimsidian#TagCompleteWrapper
    setlocal omnifunc=vimsidian#TagCompleteWrapper
enddef
